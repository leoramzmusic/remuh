import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../core/utils/logger.dart';
import '../domain/entities/track.dart';
// Note: We removed 'implements AudioRepository' because AudioHandler has its own interface.
// AudioRepositoryImpl will adapt to this.

/// Handler de audio para background playback
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Propagar eventos de just_audio a audio_service
    _player.playbackEventStream.listen(_broadcastState);

    // Propagar errores
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _broadcastState(_player.playbackEvent);
      }
    });
  }

  /// Transforma eventos de just_audio a PlaybackState de audio_service
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final queueIndex =
        event.currentIndex; // Si usáramos ConcatenatingAudioSource

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: queueIndex,
      ),
    );
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
    // Si estamos usando BaseAudioHandler, este evento viene de la notificación
    // Necesitamos notificar al UI o manejarlo internamente si supieramos la cola.
    // Una opción rápida: notificar a través de un stream custom o customAction.
    //
    // Pero si el UI maneja la cola, el UI debería escuchar esto.
    // Lo ideal es que el AudioHandler maneje la cola.
    //
    // Por ahora, para Milestone 3 rápido, podemos ignorarlo o intentar implementar
    // cola básica si `AudioRepositoryImpl` lo soporta.
    //
    // Vamos a dejarlo vacío o loguear, ya que el UI tiene los botones.
    // PERO la notificación necesita funcionar.
    // Para que la notificación funcione, el Handler debe saber cambiar de canción.
    //
    // SOLUCION: El Repo llamará a skipToNext del Notifier, quien llama a loadTrack.
    // PERO si el usuario toca la notificación... el Handler recibe la llamada.
    // El Handler NO conoce al Notifier.
    //
    // Para resolver esto: El AudioPlayerNotifier debería escuchar playbackState.
    // O mejor, pasamos una referencia/callback? No.
    //
    // Vamos a usar custom notifications o streams.
    // O simplemente asumimos que loadTrack actualiza todo.
    Logger.info('SkipToNext called from AudioHandler');
  }

  @override
  Future<void> skipToPrevious() async {
    Logger.info('SkipToPrevious called from AudioHandler');
  }

  // Custom method to load a track from our App
  Future<void> loadTrack(Track track) async {
    try {
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
      mediaItem.add(item);

      // Cargar audio
      AudioSource source;
      if (track.fileUrl != null && track.fileUrl!.startsWith('http')) {
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
}
