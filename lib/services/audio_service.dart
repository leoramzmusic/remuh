import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../core/utils/logger.dart';
import '../domain/entities/track.dart';
import '../domain/repositories/audio_repository.dart';
// Note: We removed 'implements AudioRepository' because AudioHandler has its own interface.
// AudioRepositoryImpl will adapt to this.

/// Handler de audio para background playback
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();
  String? _lastLoadedTrackId; // Track identity to avoid redundant loads

  // Stream para que el Notifier escuche peticiones de skip desde la notificación
  final _skipRequestController = StreamController<bool>.broadcast();
  Stream<bool> get skipRequestStream => _skipRequestController.stream;

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Sincronizar estado inicial
    _syncState();

    // Escuchar cambios de estado (play/pause/processing)
    _player.playerStateStream.listen((_) => _syncState());

    // Escuchar eventos de la posición y buffer
    _player.playbackEventStream.listen((_) => _syncState());

    // Escuchar cambios en MediaItem para actualizar notificación inmediatamente
    mediaItem.listen((_) => _syncState());
  }

  /// Sincroniza el estado de just_audio con audio_service
  void _syncState() {
    final playing = _player.playing;
    final processingState = _player.processingState;

    Logger.info(
      'Syncing Audio State: playing=$playing, processing=$processingState',
    );

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
      // Usar el índice del mediaItem actual si existe
      queueIndex: 0,
    );

    Logger.info(
      'Broadcasting PlaybackState: playing=${state.playing}, processing=${state.processingState}',
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
  Future<void> skipToNext() async {
    Logger.info('SkipToNext requested from Notification');
    _skipRequestController.add(true); // true = next
  }

  @override
  Future<void> skipToPrevious() async {
    Logger.info('SkipToPrevious requested from Notification');
    _skipRequestController.add(false); // false = previous
  }

  @override
  Future<void> onTaskRemoved() async {
    // Si no hay música reproduciéndose, cerramos el servicio por completo
    if (!playbackState.value.playing) {
      await stop();
    }
  }

  // Custom method to load a track from our App
  Future<void> loadTrack(Track track) async {
    try {
      if (_lastLoadedTrackId == track.id &&
          _player.audioSource != null &&
          _player.processingState != ProcessingState.idle) {
        Logger.info('Track ${track.title} already active, skipping load.');
        return;
      }
      _lastLoadedTrackId = track.id;

      Logger.info('Loading track in Handler: ${track.title}');

      // Obtener artUri del track (ya preparado por el repositorio)
      Uri? artUri;
      if (track.artworkPath != null) {
        artUri = Uri.parse(track.artworkPath!);
      }

      // Actualizar notificación
      final item = MediaItem(
        id: track.id,
        album: track.album ?? '',
        title: track.title,
        artist: track.artist ?? '',
        duration: track.duration,
        artUri: artUri,
        extras: {'url': track.fileUrl, 'path': track.filePath},
      );
      Logger.info(
        'Updating MediaItem: ${item.id} - ${item.title}, artUri: ${item.artUri}',
      );
      mediaItem.add(item);

      // Cargar audio
      AudioSource source;
      if (track.fileUrl != null &&
          (track.fileUrl!.startsWith('http') ||
              track.fileUrl!.startsWith('content://'))) {
        source = AudioSource.uri(Uri.parse(track.fileUrl!));
      } else {
        source = AudioSource.file(track.filePath);
      }

      await _player.setAudioSource(source);
    } catch (e) {
      Logger.error('Error loading track in handler', e);
      rethrow;
    }
  }

  // Expose internal player streams if needed for Repo (legacy support)
  // But ideally Repo should use AudioHandler streams (playbackState).
  // Current Repo uses _player.playerStateStream etc.
  // We can bridge them.

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
}
