import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/audio_repository_impl.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/load_track.dart';
import '../../domain/usecases/pause_audio.dart';
import '../../domain/usecases/play_audio.dart';
import '../../domain/usecases/seek_audio.dart';
import '../../domain/usecases/scan_tracks.dart';
import '../../services/audio_service.dart';
import '../../core/utils/logger.dart';

import '../../services/permission_service.dart';
import '../../data/datasources/local_audio_source.dart';

// Provider del servicio de audio
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final localAudioSourceProvider = Provider<LocalAudioSource>((ref) {
  return LocalAudioSource();
});

// Provider del repositorio
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final service = ref.watch(audioServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final localAudioSource = ref.watch(localAudioSourceProvider);
  return AudioRepositoryImpl(service, permissionService, localAudioSource);
});

// Providers de casos de uso
final playAudioUseCaseProvider = Provider<PlayAudio>((ref) {
  final repository = ref.watch(audioRepositoryProvider);
  return PlayAudio(repository);
});

final pauseAudioUseCaseProvider = Provider<PauseAudio>((ref) {
  final repository = ref.watch(audioRepositoryProvider);
  return PauseAudio(repository);
});

final seekAudioUseCaseProvider = Provider<SeekAudio>((ref) {
  final repository = ref.watch(audioRepositoryProvider);
  return SeekAudio(repository);
});

final loadTrackUseCaseProvider = Provider<LoadTrack>((ref) {
  final repository = ref.watch(audioRepositoryProvider);
  return LoadTrack(repository);
});

final scanTracksUseCaseProvider = Provider<ScanTracks>((ref) {
  final repository = ref.watch(audioRepositoryProvider);
  return ScanTracks(repository);
});

/// Estado del reproductor
class AudioPlayerState {
  final Track? currentTrack;
  final PlaybackState playbackState;
  final Duration position;
  final Duration? duration;
  final List<Track> queue;
  final int currentIndex;
  final String? error;

  const AudioPlayerState({
    this.currentTrack,
    this.playbackState = PlaybackState.stopped,
    this.position = Duration.zero,
    this.duration,
    this.queue = const [],
    this.currentIndex = -1,
    this.error,
  });

  AudioPlayerState copyWith({
    Track? currentTrack,
    PlaybackState? playbackState,
    Duration? position,
    Duration? duration,
    List<Track>? queue,
    int? currentIndex,
    String? error,
  }) {
    return AudioPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      error: error,
    );
  }

  bool get isPlaying => playbackState == PlaybackState.playing;
  bool get isPaused => playbackState == PlaybackState.paused;
  bool get isBuffering => playbackState == PlaybackState.buffering;
  bool get hasError => error != null;
  bool get hasNext => queue.isNotEmpty && currentIndex < queue.length - 1;
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;
}

/// Notifier del reproductor de audio
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioRepository _repository;
  final LoadTrack _loadTrack;
  final PlayAudio _playAudio;
  final PauseAudio _pauseAudio;
  final SeekAudio _seekAudio;

  AudioPlayerNotifier(
    this._repository,
    this._loadTrack,
    this._playAudio,
    this._pauseAudio,
    this._seekAudio,
  ) : super(const AudioPlayerState()) {
    _init();
  }

  void _init() {
    Logger.info('Initializing AudioPlayerNotifier');

    // Escuchar cambios en el estado de reproducción
    _repository.playbackStateStream.listen((playbackState) {
      state = state.copyWith(playbackState: playbackState);

      // Auto-avance simple: si completa, pasar al siguiente
      if (playbackState == PlaybackState.completed) {
        if (state.hasNext) {
          skipToNext();
        }
      }
    });

    // Escuchar cambios en la posición
    _repository.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    // Escuchar cambios en la duración
    _repository.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  /// Cargar y reproducir una pista (cola unitaria)
  Future<void> loadAndPlay(Track track) async {
    return loadPlaylist([track], 0);
  }

  /// Cargar una lista de reproducción
  Future<void> loadPlaylist(List<Track> tracks, int initialIndex) async {
    if (tracks.isEmpty) return;

    try {
      final track = tracks[initialIndex];
      Logger.info('Loading playlist starting at: ${track.title}');

      state = state.copyWith(
        queue: tracks,
        currentIndex: initialIndex,
        error: null,
      );

      await _loadTrack(track);
      state = state.copyWith(currentTrack: track);

      await _playAudio();
    } catch (e) {
      Logger.error('Error loading playlist', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Saltar a la siguiente pista
  Future<void> skipToNext() async {
    if (state.hasNext) {
      final nextIndex = state.currentIndex + 1;
      final nextTrack = state.queue[nextIndex];
      Logger.info('Skipping to next: ${nextTrack.title}');

      // Actualizamos estado antes de cargar para UI optimista
      state = state.copyWith(currentIndex: nextIndex);

      await _loadTrack(nextTrack);
      state = state.copyWith(currentTrack: nextTrack);
      await _playAudio();
    }
  }

  /// Saltar a la pista anterior
  Future<void> skipToPrevious() async {
    if (state.hasPrevious) {
      final prevIndex = state.currentIndex - 1;
      final prevTrack = state.queue[prevIndex];
      Logger.info('Skipping to previous: ${prevTrack.title}');

      state = state.copyWith(currentIndex: prevIndex);

      await _loadTrack(prevTrack);
      state = state.copyWith(currentTrack: prevTrack);
      await _playAudio();
    } else {
      // Si no hay anterior, reiniciar la actual
      await seekTo(Duration.zero);
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    try {
      if (state.isPlaying) {
        await _pauseAudio();
      } else {
        await _playAudio();
      }
    } catch (e) {
      Logger.error('Error toggling play/pause', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Buscar a una posición
  Future<void> seekTo(Duration position) async {
    try {
      await _seekAudio(position);
    } catch (e) {
      Logger.error('Error seeking', e);
      state = state.copyWith(error: e.toString());
    }
  }
}

// Provider del estado del reproductor
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final repository = ref.watch(audioRepositoryProvider);
      final loadTrack = ref.watch(loadTrackUseCaseProvider);
      final playAudio = ref.watch(playAudioUseCaseProvider);
      final pauseAudio = ref.watch(pauseAudioUseCaseProvider);
      final seekAudio = ref.watch(seekAudioUseCaseProvider);

      return AudioPlayerNotifier(
        repository,
        loadTrack,
        playAudio,
        pauseAudio,
        seekAudio,
      );
    });
