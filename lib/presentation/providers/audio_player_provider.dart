import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sleep_timer_provider.dart';
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

import 'package:shared_preferences/shared_preferences.dart';
import '../../services/permission_service.dart';
import '../../data/datasources/local_audio_source.dart';

import '../../domain/repositories/track_repository.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../../services/database_service.dart';
import 'library_view_model.dart';

// Provider del servicio de audio
// Provider del Handler (inicializado en main.dart)
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  throw UnimplementedError('Provider was not overridden');
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final localAudioSourceProvider = Provider<LocalAudioSource>((ref) {
  return LocalAudioSource();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TrackRepositoryImpl(dbService);
});

// Provider del repositorio
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final localAudioSource = ref.watch(localAudioSourceProvider);
  return AudioRepositoryImpl(audioHandler, permissionService, localAudioSource);
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

// Provider for tracking if the progress bar is being dragged
final sliderDraggingProvider = StateProvider<bool>((ref) => false);

class AudioPlayerState {
  final Track? currentTrack;
  final PlaybackState playbackState;
  final Duration position;
  final Duration? duration;
  final List<Track> queue;
  final int currentIndex;
  final AudioRepeatMode repeatMode;
  final bool shuffleMode;
  final List<int> shuffledIndices;
  final String? error;
  final String? playlistName;
  final List<Track> originalQueue;
  final bool isFastForwarding;
  final bool isRewinding;
  final int seekMultiplier;
  final int? audioSessionId;

  const AudioPlayerState({
    this.currentTrack,
    this.playbackState = PlaybackState.stopped,
    this.position = Duration.zero,
    this.duration,
    this.queue = const [],
    this.currentIndex = -1,
    this.repeatMode = AudioRepeatMode.off,
    this.shuffleMode = false,
    this.shuffledIndices = const [], // Deprecated: keeping for compatibility
    this.error,
    this.playlistName,
    this.originalQueue = const [],
    this.isFastForwarding = false,
    this.isRewinding = false,
    this.seekMultiplier = 1,
    this.audioSessionId,
  });

  List<Track> get effectiveQueue => queue; // Order is now always physical
  int get effectiveIndex => currentIndex;

  AudioPlayerState copyWith({
    Track? currentTrack,
    PlaybackState? playbackState,
    Duration? position,
    Duration? duration,
    List<Track>? queue,
    int? currentIndex,
    AudioRepeatMode? repeatMode,
    bool? shuffleMode,
    List<int>? shuffledIndices,
    String? error,
    String? playlistName,
    List<Track>? originalQueue,
    bool? isFastForwarding,
    bool? isRewinding,
    int? seekMultiplier,
    int? audioSessionId,
  }) {
    return AudioPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
      error: error ?? this.error,
      playlistName: playlistName ?? this.playlistName,
      originalQueue: originalQueue ?? this.originalQueue,
      isFastForwarding: isFastForwarding ?? this.isFastForwarding,
      isRewinding: isRewinding ?? this.isRewinding,
      seekMultiplier: seekMultiplier ?? this.seekMultiplier,
      audioSessionId: audioSessionId ?? this.audioSessionId,
    );
  }

  bool get isPlaying => playbackState == PlaybackState.playing;
  bool get isPaused => playbackState == PlaybackState.paused;
  bool get isBuffering => playbackState == PlaybackState.buffering;
  bool get hasError => error != null;

  bool get hasNext {
    if (queue.isEmpty) return false;
    final idx = effectiveIndex;
    return idx != -1 && idx < queue.length - 1;
  }

  bool get hasPrevious {
    if (queue.isEmpty) return false;
    final idx = effectiveIndex;
    return idx > 0;
  }
}

/// Notifier del reproductor de audio
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioRepository _repository;
  final TrackRepository _trackRepository;
  final LoadTrack _loadTrack;
  final PlayAudio _playAudio;
  final PauseAudio _pauseAudio;
  final SeekAudio _seekAudio;
  final Ref _ref;

  AudioPlayerNotifier(
    this._repository,
    this._trackRepository,
    this._loadTrack,
    this._playAudio,
    this._pauseAudio,
    this._seekAudio,
    this._ref,
  ) : super(const AudioPlayerState()) {
    _init();
    _restoreSettings();
  }

  static const _keyLastTrackId = 'last_track_id';
  static const _keyLastPosition = 'last_position_ms';
  static const _keyShuffleMode = 'shuffle_mode';
  static const _keyRepeatMode = 'repeat_mode';

  Future<void> _restoreSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shuffle = prefs.getBool(_keyShuffleMode) ?? false;
      final repeatIndex =
          prefs.getInt(_keyRepeatMode) ?? AudioRepeatMode.off.index;
      final repeatMode = AudioRepeatMode.values[repeatIndex];

      state = state.copyWith(shuffleMode: shuffle, repeatMode: repeatMode);
      await _repository.setRepeatMode(repeatMode);
      await _repository.setShuffleMode(shuffle);
    } catch (e) {
      Logger.error('Error restoring settings', e);
    }
  }

  Timer? _seekTimer;
  int _seekMultiplier = 1;
  bool _wasPlayingBeforeSeek = false;

  void startFastForward() {
    if (_seekTimer != null) return;
    _wasPlayingBeforeSeek = state.isPlaying;
    _seekMultiplier = 1;
    state = state.copyWith(isFastForwarding: true);

    // Use a local target position to avoid race conditions with the stream
    Duration targetPos = state.position;

    _seekTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) async {
      final duration = state.duration ?? Duration.zero;
      final jump = Duration(seconds: 1 * _seekMultiplier);
      targetPos += jump;

      if (targetPos >= duration) {
        await seekTo(duration);
        await _repository.pause();
        stopFastForward(); // Auto stop if we hit the end
      } else {
        await seekTo(targetPos);
        if (timer.tick % 5 == 0 && _seekMultiplier < 8) {
          _seekMultiplier *= 2;
          state = state.copyWith(seekMultiplier: _seekMultiplier);
        }
      }
    });
  }

  void stopFastForward() {
    if (_seekTimer == null) return;
    _seekTimer?.cancel();
    _seekTimer = null;
    state = state.copyWith(isFastForwarding: false, seekMultiplier: 1);

    if (state.position >= (state.duration ?? Duration.zero)) {
      skipToNext();
    } else if (_wasPlayingBeforeSeek) {
      _repository.play();
    }
  }

  void startRewind() {
    if (_seekTimer != null) return;
    _wasPlayingBeforeSeek = state.isPlaying;
    _seekMultiplier = 1;
    state = state.copyWith(isRewinding: true);

    Duration targetPos = state.position;

    _seekTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) async {
      final jump = Duration(seconds: 1 * _seekMultiplier);

      if (targetPos <= jump) {
        targetPos = Duration.zero;
        await seekTo(targetPos);
        await _repository.pause();
        stopRewind();
      } else {
        targetPos -= jump;
        await seekTo(targetPos);
        if (timer.tick % 5 == 0 && _seekMultiplier < 8) {
          _seekMultiplier *= 2;
          state = state.copyWith(seekMultiplier: _seekMultiplier);
        }
      }
    });
  }

  void stopRewind() {
    if (_seekTimer == null) return;
    _seekTimer?.cancel();
    _seekTimer = null;
    state = state.copyWith(isRewinding: false, seekMultiplier: 1);

    if (_wasPlayingBeforeSeek) {
      _repository.play();
    }
  }

  DateTime _lastPositionSave = DateTime.now();

  Future<void> _saveState({bool force = false}) async {
    try {
      final trackId = state.currentTrack?.id;
      final positionMs = state.position.inMilliseconds;

      final now = DateTime.now();
      // Throttle position saving unless forced (e.g. on pause or track change)
      if (!force && now.difference(_lastPositionSave).inSeconds < 5) {
        return;
      }
      _lastPositionSave = now;

      final prefs = await SharedPreferences.getInstance();
      if (trackId != null) {
        await prefs.setString(_keyLastTrackId, trackId);
        await prefs.setInt(_keyLastPosition, positionMs);
      }
      await prefs.setBool(_keyShuffleMode, state.shuffleMode);
      await prefs.setInt(_keyRepeatMode, state.repeatMode.index);
    } catch (e) {
      // Ignore save errors to avoid UI disruption
    }
  }

  Future<void> restorePlayback(List<Track> library) async {
    if (library.isEmpty || state.currentTrack != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTrackId = prefs.getString(_keyLastTrackId);
      final lastPositionMs = prefs.getInt(_keyLastPosition) ?? 0;

      if (lastTrackId != null) {
        final track = library.where((t) => t.id == lastTrackId).firstOrNull;
        if (track != null) {
          Logger.info('Restoring last session: ${track.title}');

          state = state.copyWith(
            currentTrack: track,
            currentIndex: library.indexOf(track),
            queue: library,
            position: Duration(milliseconds: lastPositionMs),
          );

          await _repository.loadTrack(track);
          await _repository.seek(Duration(milliseconds: lastPositionMs));

          // Note: We don't call play() automatically here to avoid surprises.
          // The user can press play when they see the mini-player.
        }
      }
    } catch (e) {
      Logger.error('Error in restorePlayback', e);
    }
  }

  void _init() {
    Logger.info('Initializing AudioPlayerNotifier');

    // Escuchar el temporizador de sueño
    _ref.listen(sleepTimerProvider, (previous, next) {
      if (previous?.isActive == true &&
          next.isActive == false &&
          next.remainingTime == Duration.zero) {
        pause();
      }
    });

    // Sincronizar track actual al inicio (por si ya hay algo sonando en background)
    final initialTrack = _repository.currentTrack;
    if (initialTrack != null) {
      state = state.copyWith(currentTrack: initialTrack);
    }

    // Escuchar cambios en la pista actual (sync desde background)
    _repository.currentTrackStream.listen((track) {
      if (track != null && state.currentTrack?.id != track.id) {
        state = state.copyWith(currentTrack: track);
      }
    });

    // Escuchar cambios de índice automáticos (gapless o skip manual en Handler)
    _repository.indexChangeStream.listen((index) {
      if (index >= 0 && index < state.queue.length) {
        final track = state.queue[index];
        if (state.currentTrack?.id != track.id) {
          // Verificar si el temporizador de sueño está en modo "Fin de pista"
          final sleepTimer = _ref.read(sleepTimerProvider);
          if (sleepTimer.isActive && sleepTimer.pauseAtEndOfTrack) {
            _ref.read(sleepTimerProvider.notifier).cancelTimer();
            pause();
          }

          state = state.copyWith(currentIndex: index, currentTrack: track);
        }
      }
    });

    // Escuchar cambios en el estado de reproducción
    _repository.playbackStateStream.listen((playbackState) {
      state = state.copyWith(playbackState: playbackState);

      // Auto-avance: ya no llamamos skipToNext() aquí si es gapless,
      // just_audio avanza el índice y nosotros lo escuchamos arriba.
      if (playbackState == PlaybackState.completed) {
        // Increment play count only
        final currentTrackId = state.currentTrack?.id;
        if (currentTrackId != null) {
          _trackRepository.incrementPlayCount(currentTrackId);
        }
      }

      _saveState(
        force:
            playbackState == PlaybackState.paused ||
            playbackState == PlaybackState.stopped,
      );
    });

    // Escuchar cambios en la posición
    _repository.positionStream.listen((position) {
      state = state.copyWith(position: position);
      _saveState();
    });

    // Escuchar cambios en la duración
    _repository.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    // Notify Equalizer when sessionId is ready (Android)
    _repository.playbackStateStream.listen((_) {
      _syncAudioSessionId();
    });
    _repository.currentTrackStream.listen((_) {
      _syncAudioSessionId();
    });
    _syncAudioSessionId();
  }

  void _syncAudioSessionId() {
    final sessionId = _repository.androidAudioSessionId;
    if (sessionId != state.audioSessionId) {
      state = state.copyWith(audioSessionId: sessionId);
    }
  }

  /// Cambiar modo de repetición
  Future<AudioRepeatMode> toggleRepeatMode() async {
    final nextMode = switch (state.repeatMode) {
      AudioRepeatMode.off => AudioRepeatMode.all,
      AudioRepeatMode.all => AudioRepeatMode.one,
      AudioRepeatMode.one => AudioRepeatMode.off,
    };
    state = state.copyWith(repeatMode: nextMode);
    await _repository.setRepeatMode(nextMode);
    await _saveState(force: true);
    return nextMode;
  }

  Future<void> toggleShuffle() async {
    try {
      final bool nextShuffle = !state.shuffleMode;
      List<Track> newQueue;
      int newIndex;

      if (nextShuffle) {
        // ACTIVAR SHUFFLE: Guardamos el orden original y mezclamos físicamente
        final original = List<Track>.from(state.queue);
        final shuffled = List<Track>.from(state.queue);
        final current = state.currentTrack;

        shuffled.shuffle();

        // Mover el track actual al inicio para que no parezca un salto brusco
        if (current != null) {
          shuffled.removeWhere((t) => t.id == current.id);
          shuffled.insert(0, current);
        }

        newQueue = shuffled;
        newIndex = 0;

        state = state.copyWith(
          shuffleMode: true,
          originalQueue: original,
          queue: newQueue,
          currentIndex: newIndex,
        );
      } else {
        // DESACTIVAR SHUFFLE: Restauramos el orden original
        newQueue = state.originalQueue.isNotEmpty
            ? state.originalQueue
            : state.queue;

        newIndex = newQueue.indexWhere((t) => t.id == state.currentTrack?.id);
        if (newIndex == -1) newIndex = 0;

        state = state.copyWith(
          shuffleMode: false,
          originalQueue: [],
          queue: newQueue,
          currentIndex: newIndex,
        );
      }

      // Sincronizar con el motor: siempre lineal
      await _repository.setShuffleMode(false);
      await _repository.updateQueue(
        state.queue,
        initialIndex: state.currentIndex,
      );

      // Asegurarse de que el motor sepa que estamos en el track correcto
      // Importante: No llamamos a loadTrack(track) porque eso reinicia la pista.
      // Solo actualizamos el índice en el motor si es necesario.
      // just_audio ConcatenatingAudioSource mantiene la posición si solo cambiamos el índice?
      // En realidad, al hacer updateQueue (clear + addAll), el player se resetea.
      // Para mantener la posición, necesitamos restaurarla.
      final currentPosition = state.position;
      final track = state.currentTrack;
      if (track != null) {
        await _repository.loadTrack(track);
        if (currentPosition > Duration.zero) {
          await _repository.seek(currentPosition);
        }
        if (state.isPlaying) {
          await _repository.play();
        }
      }
    } catch (e) {
      Logger.error('Error toggling shuffle', e);
    }
  }

  /// Cargar y reproducir una pista (cola unitaria)
  Future<void> loadAndPlay(Track track) async {
    return loadPlaylist([track], 0);
  }

  /// Cargar una lista de reproducción
  Future<void> loadPlaylist(
    List<Track> tracks,
    int initialIndex, {
    bool startShuffled = false,
    String? playlistName,
  }) async {
    if (tracks.isEmpty) return;

    try {
      if (startShuffled) {
        int finalInitialIndex = initialIndex;
        // Si arrancamos aleatorio desde el "botón general" (index 0),
        // elegir una canción al azar para que no siempre empiece la misma.
        if (initialIndex == 0 && tracks.length > 1) {
          final randomIndex = math.Random().nextInt(tracks.length);
          finalInitialIndex = randomIndex;
        }

        final shuffled = List<Track>.from(tracks);
        final initialTrack = tracks[finalInitialIndex];

        shuffled.shuffle();

        // Mover el track inicial al principio para que empiece YA
        shuffled.removeWhere((t) => t.id == initialTrack.id);
        shuffled.insert(0, initialTrack);

        state = state.copyWith(
          queue: shuffled,
          currentIndex: 0,
          currentTrack: initialTrack,
          shuffleMode: true,
          originalQueue: tracks,
          error: null,
          playlistName: playlistName,
        );
      } else {
        // MODO ORDENADO: Respetamos el índice inicial y toda la lista
        state = state.copyWith(
          queue: tracks,
          currentIndex: initialIndex,
          currentTrack: tracks[initialIndex],
          shuffleMode: false,
          originalQueue: [],
          error: null,
          playlistName: playlistName,
        );
      }

      // Sincronizar cola física con el motor (siempre lineal)
      await _repository.setShuffleMode(false);
      await _repository.updateQueue(
        state.queue,
        initialIndex: state.currentIndex,
      );

      // FORZAR el inicio en el track seleccionado
      final trackToPlay = state.currentTrack;
      if (trackToPlay != null) {
        // loadTrack en nuestro handler ya incluye skipToQueueItem si está en la cola
        await _repository.loadTrack(trackToPlay);
      }

      await _repository.play();
    } catch (e) {
      Logger.error('Error loading playlist', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Seleccionar canción manualmente (respeta modo aleatorio si está activo)
  Future<void> playTrackManually(List<Track> contextTracks, int index) async {
    // AL SELECCIONAR MANUALMENTE: Respetamos el modo actual
    if (state.shuffleMode) {
      await loadPlaylist(contextTracks, index, startShuffled: true);
    } else {
      await loadPlaylist(contextTracks, index, startShuffled: false);
    }
  }

  /// Saltar a la siguiente pista
  Future<void> skipToNext() async {
    try {
      if (state.queue.isEmpty) return;

      int nextIndex = -1;
      if (state.currentIndex < state.queue.length - 1) {
        nextIndex = state.currentIndex + 1;
      } else if (state.repeatMode == AudioRepeatMode.all) {
        nextIndex = 0;
      }

      if (nextIndex != -1) {
        final nextTrack = state.queue[nextIndex];
        Logger.info('Skipping to next: ${nextTrack.title}');

        // El estado se actualizará por indexChangeStream, pero forzamos para UI
        state = state.copyWith(
          currentIndex: nextIndex,
          currentTrack: nextTrack,
        );

        await _repository.loadTrack(nextTrack);
        await _playAudio();
      }
    } catch (e) {
      Logger.error('Error skipping to next', e);
      // Don't set error state for connection aborted as it might be transient
      if (!e.toString().contains('Connection aborted')) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  /// Saltar a la pista anterior
  Future<void> skipToPrevious() async {
    try {
      if (state.queue.isEmpty) return;

      int prevIndex = -1;
      if (state.currentIndex > 0) {
        prevIndex = state.currentIndex - 1;
      } else if (state.repeatMode == AudioRepeatMode.all) {
        prevIndex = state.queue.length - 1;
      }

      if (prevIndex != -1) {
        final prevTrack = state.queue[prevIndex];
        Logger.info('Skipping to previous: ${prevTrack.title}');

        state = state.copyWith(
          currentIndex: prevIndex,
          currentTrack: prevTrack,
        );

        await _repository.loadTrack(prevTrack);
        await _playAudio();
      } else {
        await _repository.seek(Duration.zero);
        await _playAudio();
      }
    } catch (e) {
      Logger.error('Error skipping to previous', e);
      if (!e.toString().contains('Connection aborted')) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    try {
      if (state.isPlaying) {
        await _pauseAudio();
      } else {
        if (state.currentTrack == null && state.queue.isNotEmpty) {
          // Si no hay canción seleccionada, pero hay cola, reproducir la primera canción
          // Respetamos el orden efectivo (aleatorio o no)
          if (state.shuffleMode && state.shuffledIndices.isNotEmpty) {
            await loadTrackInQueue(state.shuffledIndices[0]);
          } else {
            await loadTrackInQueue(0);
          }
          await _playAudio();
        } else if (state.queue.isNotEmpty) {
          await _playAudio();
        } else {
          Logger.warning('Play/Pause pulsado pero la cola está vacía');
        }
      }
    } catch (e) {
      Logger.error('Error toggling play/pause', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    try {
      if (state.isPlaying) {
        await _pauseAudio();
      }
    } catch (e) {
      Logger.error('Error pausing audio', e);
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

  /// Reordenar la cola
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final List<Track> newQueue = List.from(state.queue);
    final Track track = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, track);

    // Actualizar el índice actual si la pista que suena se movió
    int newCurrentIndex = state.currentIndex;
    if (oldIndex == state.currentIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentIndex &&
        newIndex >= state.currentIndex) {
      newCurrentIndex -= 1;
    } else if (oldIndex > state.currentIndex &&
        newIndex <= state.currentIndex) {
      newCurrentIndex += 1;
    }

    state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);

    _saveState(force: true);
  }

  /// Quitar pista de la cola
  void removeFromQueue(int index) {
    if (state.queue.length <= 1) {
      return; // No dejar la cola vacía si está sonando
    }

    final List<Track> newQueue = List.from(state.queue);
    newQueue.removeAt(index);

    int newCurrentIndex = state.currentIndex;
    if (index == state.currentIndex) {
      // Si quitamos la que suena, saltar a la siguiente (o anterior si era la última)
      if (index < newQueue.length) {
        // Permanecemos en el mismo índice que ahora apunta a la siguiente pista
        loadTrackInQueue(index);
      } else {
        newCurrentIndex -= 1;
        loadTrackInQueue(newCurrentIndex);
      }
    } else if (index < state.currentIndex) {
      newCurrentIndex -= 1;
    }

    state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);

    _saveState(force: true);
  }

  /// Añadir pista al final de la cola
  void addToEnd(Track track) {
    // Si la cola está vacía, simplemente reproducimos
    if (state.queue.isEmpty) {
      loadAndPlay(track);
      return;
    }

    final newQueue = List<Track>.from(state.queue)..add(track);

    // Si estamos en shuffle, necesitamos actualizar shuffledIndices
    List<int> newShuffledIndices = List.from(state.shuffledIndices);
    if (state.shuffleMode) {
      newShuffledIndices.add(newQueue.length - 1);
    }

    state = state.copyWith(
      queue: newQueue,
      shuffledIndices: newShuffledIndices,
    );
    _saveState(force: true);
  }

  /// Insertar pista para reproducir después de la actual
  void playNext(Track track) {
    if (state.queue.isEmpty) {
      loadAndPlay(track);
      return;
    }

    final newQueue = List<Track>.from(state.queue);
    final insertPos = state.currentIndex + 1;

    newQueue.insert(insertPos, track);

    // Ajustar shuffledIndices si es necesario
    List<int> newShuffledIndices = List.from(state.shuffledIndices);
    if (state.shuffleMode) {
      // En shuffle, "play next" significa insertarlo justo después en la mezcla actual
      final currentPosInShuffle = state.shuffledIndices.indexOf(
        state.currentIndex,
      );
      // Primero incrementamos todos los índices que sean >= a la nueva posición absoluta
      newShuffledIndices = newShuffledIndices
          .map((idx) => idx >= insertPos ? idx + 1 : idx)
          .toList();
      // Luego insertamos la referencia a la nueva canción justo después de la actual en la mezcla
      newShuffledIndices.insert(currentPosInShuffle + 1, insertPos);
    }

    state = state.copyWith(
      queue: newQueue,
      shuffledIndices: newShuffledIndices,
    );
    _saveState(force: true);
  }

  /// Cargar una pista específica de la cola (índice absoluto de state.queue)
  Future<void> loadTrackInQueue(int index) async {
    try {
      final track = state.queue[index];
      await _loadTrack(track);
      state = state.copyWith(currentTrack: track, currentIndex: index);
    } catch (e) {
      Logger.error('Error loading track in queue', e);
      if (!e.toString().contains('Connection aborted')) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  /// Cargar una pista por su posición en la cola EFECTIVA (lo que ve el usuario)
  Future<void> skipToEffectiveIndex(int effectiveIndex) async {
    if (state.shuffleMode && state.shuffledIndices.isNotEmpty) {
      if (effectiveIndex >= 0 &&
          effectiveIndex < state.shuffledIndices.length) {
        final realIndex = state.shuffledIndices[effectiveIndex];
        await loadTrackInQueue(realIndex);
      }
    } else {
      await loadTrackInQueue(effectiveIndex);
    }
  }

  Future<void> stop() async {
    try {
      await _repository.stop();
      state = state.copyWith(playbackState: PlaybackState.stopped);
    } catch (e) {
      Logger.error('Error stopping audio', e);
    }
  }

  /// Actualizar metadatos de una canción si está en la cola
  void refreshTrackMetadata(String trackId, Map<String, dynamic> metadata) {
    bool updated = false;
    final newQueue = state.queue.map((t) {
      if (t.id == trackId) {
        updated = true;
        return t.copyWith(
          title: metadata['title'] as String?,
          artist: metadata['artist'] as String?,
          album: metadata['album'] as String?,
          artworkPath: metadata['artworkPath'] as String?,
          clearArtworkPath:
              metadata.containsKey('artworkPath') &&
              metadata['artworkPath'] == null,
        );
      }
      return t;
    }).toList();

    if (updated) {
      state = state.copyWith(
        queue: newQueue,
        currentTrack: state.currentTrack?.id == trackId
            ? newQueue.firstWhere((t) => t.id == trackId)
            : state.currentTrack,
      );
      _saveState(force: true);
    }
  }

  /// Notificar que una canción fue eliminada
  void notifyTrackDeleted(String trackId) {
    if (state.queue.any((t) => t.id == trackId)) {
      final isPlayingDeleted = state.currentTrack?.id == trackId;

      if (isPlayingDeleted) {
        stop();
      }

      final newQueue = state.queue.where((t) => t.id != trackId).toList();

      state = state.copyWith(
        queue: newQueue,
        currentIndex: isPlayingDeleted ? -1 : state.currentIndex,
        currentTrack: isPlayingDeleted ? null : state.currentTrack,
      );
      _saveState(force: true);
    }
  }

  /// Sync favorite status from external source (e.g. LibraryViewModel)
  void syncFavoriteStatus(String trackId, bool isFavorite) {
    // Update current track if it's the one being toggled
    if (state.currentTrack?.id == trackId) {
      state = state.copyWith(
        currentTrack: state.currentTrack?.copyWith(isFavorite: isFavorite),
      );
    }

    // Update in queue
    final newQueue = state.queue.map((t) {
      if (t.id == trackId) {
        return t.copyWith(isFavorite: isFavorite);
      }
      return t;
    }).toList();

    state = state.copyWith(queue: newQueue);
  }

  /// Toggle favorite status of a track
  Future<void> toggleFavorite(Track track) async {
    // Delegate to LibraryViewModel for centralized state management
    await _ref.read(libraryViewModelProvider.notifier).toggleFavorite(track.id);
  }
}

// Provider del estado del reproductor
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final repository = ref.watch(audioRepositoryProvider);
      final trackRepository = ref.watch(trackRepositoryProvider);
      final loadTrack = ref.watch(loadTrackUseCaseProvider);
      final playAudio = ref.watch(playAudioUseCaseProvider);
      final pauseAudio = ref.watch(pauseAudioUseCaseProvider);
      final seekAudio = ref.watch(seekAudioUseCaseProvider);

      return AudioPlayerNotifier(
        repository,
        trackRepository,
        loadTrack,
        playAudio,
        pauseAudio,
        seekAudio,
        ref,
      );
    });
