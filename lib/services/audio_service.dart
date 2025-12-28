import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../core/errors/exceptions.dart';
import '../core/utils/logger.dart';
import '../domain/entities/track.dart';
import '../domain/repositories/audio_repository.dart';

/// Servicio de audio que encapsula just_audio
class AudioService implements AudioRepository {
  final AudioPlayer _player = AudioPlayer();
  Track? _currentTrack;
  bool _isInitialized = false;

  @override
  Track? get currentTrack => _currentTrack;

  @override
  Future<List<Track>> getDeviceTracks() async => [];

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('Initializing audio session...');

      // Configurar sesión de audio
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Manejar interrupciones
      session.becomingNoisyEventStream.listen((_) {
        Logger.info('Audio becoming noisy, pausing...');
        pause();
      });

      session.interruptionEventStream.listen((event) {
        Logger.info('Audio interruption: ${event.type}');
        if (event.begin) {
          if (event.type == AudioInterruptionType.pause) {
            pause();
          }
        } else {
          // Interruption ended
          if (event.type == AudioInterruptionType.pause) {
            // Optionally resume playback
          }
        }
      });

      _isInitialized = true;
      Logger.info('Audio session initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize audio session', e, stackTrace);
      throw AudioException('Failed to initialize audio session: $e');
    }
  }

  @override
  Future<void> loadTrack(Track track) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      Logger.info('Loading track: ${track.title}');

      // Determinar la fuente
      AudioSource source;
      if (track.fileUrl != null && track.fileUrl!.startsWith('http')) {
        source = AudioSource.uri(Uri.parse(track.fileUrl!));
      } else {
        source = AudioSource.file(track.filePath);
      }

      await _player.setAudioSource(source);
      _currentTrack = track;

      Logger.info('Track loaded successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to load track', e, stackTrace);
      throw AudioException('Failed to load track: $e');
    }
  }

  @override
  Future<void> play() async {
    if (!_isInitialized) {
      throw AudioException('Audio service not initialized');
    }

    try {
      Logger.info('Playing audio');
      await _player.play();
    } catch (e, stackTrace) {
      Logger.error('Failed to play audio', e, stackTrace);
      throw AudioException('Failed to play audio: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (!_isInitialized) {
      throw AudioException('Audio service not initialized');
    }

    try {
      Logger.info('Pausing audio');
      await _player.pause();
    } catch (e, stackTrace) {
      Logger.error('Failed to pause audio', e, stackTrace);
      throw AudioException('Failed to pause audio: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_isInitialized) {
      throw AudioException('Audio service not initialized');
    }

    try {
      Logger.info('Stopping audio');
      await _player.stop();
    } catch (e, stackTrace) {
      Logger.error('Failed to stop audio', e, stackTrace);
      throw AudioException('Failed to stop audio: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_isInitialized) {
      throw AudioException('Audio service not initialized');
    }

    try {
      Logger.debug('Seeking to position: $position');
      await _player.seek(position);
    } catch (e, stackTrace) {
      Logger.error('Failed to seek', e, stackTrace);
      throw AudioException('Failed to seek: $e');
    }
  }

  @override
  Stream<PlaybackState> get playbackStateStream {
    return _player.playerStateStream.map((state) {
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        return PlaybackState.buffering;
      } else if (state.playing) {
        return PlaybackState.playing;
      } else if (state.processingState == ProcessingState.completed) {
        return PlaybackState.completed;
      } else {
        return PlaybackState.paused;
      }
    });
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> dispose() async {
    Logger.info('Disposing audio service');
    await _player.dispose();
    _isInitialized = false;
  }
}
