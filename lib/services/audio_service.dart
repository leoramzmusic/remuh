import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../domain/entities/track.dart';
import '../domain/repositories/audio_repository.dart';
// Note: We removed 'implements AudioRepository' because AudioHandler has its own interface.
// AudioRepositoryImpl will adapt to this.

/// Handler de audio para background playback
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [],
  );

  // Stream para que el Notifier escuche peticiones de skip desde la notificación
  final _skipRequestController = StreamController<bool>.broadcast();
  Stream<bool> get skipRequestStream => _skipRequestController.stream;

  // Stream para cambios de índice automáticos (para gapless playback)
  final _indexChangeController = StreamController<int>.broadcast();
  Stream<int> get indexChangeStream => _indexChangeController.stream;

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Configurar playlist inicial
    await _player.setAudioSource(_playlist);

    // Sincronizar estado inicial
    _syncState();

    // Escuchar cambios de estado (play/pause/processing)
    _player.playerStateStream.listen((_) => _syncState());

    // Escuchar eventos de la posición y buffer
    _player.playbackEventStream.listen((_) => _syncState());

    // Escuchar cambios en MediaItem para actualizar notificación inmediatamente
    mediaItem.listen((_) => _syncState());

    // Escuchar cambios de índice automáticos (just_audio maneja el avance)
    _player.currentIndexStream.listen((index) {
      if (index != null) {
        _indexChangeController.add(index);
        _updateMetadataForIndex(index);
      }
    });

    // Escuchar completado para avanzar si no hay Concatenating (fallback)
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // just_audio avanza solo si hay más items en ConcatenatingAudioSource
      }
    });
  }

  void _updateMetadataForIndex(int index) {
    if (index >= 0 && index < queue.value.length) {
      final item = queue.value[index];
      mediaItem.add(item);
    }
  }

  /// Sincroniza el estado de just_audio con audio_service
  void _syncState() {
    final playing = _player.playing;
    final processingState = _player.processingState;

    final state = playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState:
          const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[processingState] ??
          AudioProcessingState.idle,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );

    playbackState.add(state);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      // Notificar al provider si queremos manejar wrap-around o lógica personalizada
      _skipRequestController.add(true);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious || _player.position.inSeconds > 3) {
      await _player.seekToPrevious();
    } else {
      _skipRequestController.add(false);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!playbackState.value.playing) {
      await stop();
    }
  }

  /// Actualiza la cola de reproducción en audio_service y just_audio
  @override
  Future<void> updateQueue(
    List<MediaItem> newQueue, {
    int initialIndex = 0,
  }) async {
    queue.add(newQueue);

    final List<AudioSource> newSources = newQueue.map((item) {
      final url = item.extras?['url'] as String?;
      final path = item.extras?['path'] as String?;

      if (url != null &&
          (url.startsWith('http') || url.startsWith('content://'))) {
        return AudioSource.uri(Uri.parse(url), tag: item);
      } else {
        return AudioSource.file(path!, tag: item);
      }
    }).toList();

    // Reemplazamos toda la fuente para asegurar el initialIndex y gapless
    _playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: newSources,
    );
    await _player.setAudioSource(
      _playlist,
      initialIndex: initialIndex,
      initialPosition: Duration.zero,
    );
  }

  /// Mueve un elemento en la cola sin reconstruirla por completo
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _playlist.length ||
        newIndex < 0 ||
        newIndex >= _playlist.length) {
      return;
    }

    // Mover en la fuente de audio (just_audio)
    await _playlist.move(oldIndex, newIndex);

    // Mover en la cola de audio_service
    final List<MediaItem> currentQueue = List.from(queue.value);
    final MediaItem item = currentQueue.removeAt(oldIndex);
    currentQueue.insert(newIndex, item);
    queue.add(currentQueue);
  }

  // Legacy support for single track load (still used by repository for quick plays)
  Future<void> loadTrack(Track track) async {
    // Check if track is already in the queue to preserve gapless playback
    final currentQueue = queue.value;
    final index = currentQueue.indexWhere((item) => item.id == track.id);

    if (index != -1) {
      // Track is already in queue, just skip to it
      if (_player.currentIndex != index) {
        await skipToQueueItem(index);
      }
      // Update metadata (in case it has non-standard values or new artwork path)
      _updateMetadataForTrack(track);
      return;
    }

    // Para gapless playback, idealmente usamos updateQueue + skipToQueueItem.
    // Pero si se llama loadTrack individualmente, creamos una cola de uno.
    final item = MediaItem(
      id: track.id,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist ?? '',
      duration: track.duration,
      artUri: track.artworkPath != null ? Uri.parse(track.artworkPath!) : null,
      extras: {'url': track.fileUrl, 'path': track.filePath},
    );
    await updateQueue([item]);
  }

  void _updateMetadataForTrack(Track track) {
    final item = MediaItem(
      id: track.id,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist ?? '',
      duration: track.duration,
      artUri: track.artworkPath != null ? Uri.parse(track.artworkPath!) : null,
      extras: {'url': track.fileUrl, 'path': track.filePath},
    );
    mediaItem.add(item);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> setRepeatModeCustom(AudioRepeatMode mode) async {
    final loopMode = switch (mode) {
      AudioRepeatMode.off => LoopMode.off,
      AudioRepeatMode.one => LoopMode.one,
      AudioRepeatMode.all => LoopMode.all,
    };
    await _player.setLoopMode(loopMode);
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _player.shuffle();
    }
  }

  int? get androidAudioSessionId => _player.androidAudioSessionId;

  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {
    // audio_service builtin call
  }
}
