import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/track.dart';
import '../../domain/usecases/scan_tracks.dart';
import '../../domain/repositories/track_repository.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../core/utils/logger.dart';
import 'audio_player_provider.dart';
import '../../domain/entities/scan_progress.dart';

// Estado de la biblioteca
class LibraryState {
  final List<Track> tracks;
  final bool isScanning;
  final ScanProgress? scanProgress;
  final int lastAddedCount;
  final DateTime? lastScanTime;
  final String? error;

  LibraryState({
    this.tracks = const [],
    this.isScanning = false,
    this.scanProgress,
    this.lastAddedCount = 0,
    this.lastScanTime,
    this.error,
  });

  LibraryState copyWith({
    List<Track>? tracks,
    bool? isScanning,
    ScanProgress? scanProgress,
    int? lastAddedCount,
    DateTime? lastScanTime,
    String? error,
  }) {
    return LibraryState(
      tracks: tracks ?? this.tracks,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      lastAddedCount: lastAddedCount ?? this.lastAddedCount,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      error: error, // Se resetea si no se pasa
    );
  }
}

// Provider principal de la biblioteca
final libraryViewModelProvider =
    StateNotifierProvider<LibraryViewModel, LibraryState>((ref) {
      final scanTracks = ref.watch(scanTracksUseCaseProvider);
      final trackRepository = ref.watch(trackRepositoryProvider);
      final audioRepository = ref.watch(audioRepositoryProvider);
      final audioPlayer = ref.watch(audioPlayerProvider.notifier);
      return LibraryViewModel(
        scanTracks,
        trackRepository,
        audioRepository,
        audioPlayer,
      );
    });

class LibraryViewModel extends StateNotifier<LibraryState> {
  final ScanTracks _scanTracks;
  final TrackRepository _trackRepository;
  final AudioRepository _audioRepository;
  final AudioPlayerNotifier _audioPlayer;
  static const String _keyLastScanTime = 'library_last_scan_time';

  LibraryViewModel(
    this._scanTracks,
    this._trackRepository,
    this._audioRepository,
    this._audioPlayer,
  ) : super(LibraryState()) {
    _loadLastScanTime();
    // Delay scan to ensure UI is ready and avoid permission errors on startup
    // Delay scan to ensure UI is ready and avoid permission errors on startup
    Future.delayed(
      const Duration(seconds: 1),
      () => scanLibrary(initial: true),
    );
  }

  Future<void> _loadLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastScanTime);
    if (timestamp != null) {
      state = state.copyWith(
        lastScanTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    }
  }

  Future<void> _saveLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastScanTime, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> scanLibrary({bool initial = false}) async {
    if (state.isScanning) {
      Logger.info('Scan already in progress, skipping request');
      return;
    }

    state = state.copyWith(
      isScanning: true,
      error: null,
      scanProgress: ScanProgress.initial(),
    );
    Logger.info('Starting library scan (initial: $initial)...');

    try {
      final currentIds = state.tracks.map((t) => t.id).toSet();

      // Subscribe to progress stream with a global timeout
      await for (final progress in _audioRepository.scanDeviceTracks().timeout(
        const Duration(seconds: 45),
        onTimeout: (sink) {
          Logger.error('Library scan timed out after 45 seconds');
          sink.close();
        },
      )) {
        state = state.copyWith(scanProgress: progress);
      }

      // Now get the final list (this is fast as it's already scanned in the repository)
      final newTracks = await _scanTracks();

      Logger.info('Scan results received: ${newTracks.length} tracks');

      // Calcular cuántas son realmente nuevas
      int added = 0;
      if (!initial) {
        added = newTracks.where((t) => !currentIds.contains(t.id)).length;
      }

      await _saveLastScanTime();

      // Merge with stats and overrides
      Logger.info('Merging metadata from DB...');
      final statsMap = await _trackRepository.getAllTrackStats();
      final overridesMap = await _trackRepository.getAllTrackOverrides();

      final tracksWithMetadata = newTracks.map((t) {
        Track updated = t;

        // 1. Aplicar Estadísticas
        final stats = statsMap[t.id];
        if (stats != null) {
          updated = updated.copyWith(
            isFavorite: stats.isFavorite,
            playCount: stats.playCount,
            lastPlayedAt: stats.lastPlayedAt,
          );
        }

        // 2. Aplicar Overrides (Ediciones del usuario)
        final overrides = overridesMap[t.id];
        if (overrides != null) {
          updated = updated.copyWith(
            title: overrides['title'] as String?,
            artist: overrides['artist'] as String?,
            album: overrides['album'] as String?,
          );
        }

        return updated;
      }).toList();

      state = state.copyWith(
        tracks: tracksWithMetadata,
        isScanning: false,
        lastAddedCount: added,
        lastScanTime: DateTime.now(),
      );

      Logger.info(
        'Library updated successfully: ${tracksWithMetadata.length} tracks total',
      );

      // Restaurar última sesión si el reproductor está vacío
      _audioPlayer.restorePlayback(tracksWithMetadata);
    } catch (e, stack) {
      Logger.error('Fatal error during library scan', e);
      Logger.error('Stack trace: $stack');
      state = state.copyWith(isScanning: false, error: e.toString());
    } finally {
      // Safety check to ensure isScanning is never stuck
      if (state.isScanning) {
        state = state.copyWith(isScanning: false);
      }
    }
  }

  /// Obtener pistas de un artista específico
  List<Track> getTracksByArtist(String artist) {
    return state.tracks.where((t) => t.artist == artist).toList();
  }

  /// Obtener pistas de un álbum específico
  List<Track> getTracksByAlbum(String album) {
    return state.tracks.where((t) => t.album == album).toList();
  }

  /// Obtener lista de artistas únicos
  List<String> getArtists() {
    return state.tracks.map((t) => t.artist ?? 'Desconocido').toSet().toList()
      ..sort();
  }

  /// Obtener lista de álbumes únicos
  List<String> getAlbums() {
    return state.tracks.map((t) => t.album ?? 'Desconocido').toSet().toList()
      ..sort();
  }

  /// Obtener las 5 canciones más reproducidas
  List<Track> getMostPlayedTracks() {
    final playedTracks = state.tracks.where((t) => t.playCount > 0).toList();
    playedTracks.sort((a, b) => b.playCount.compareTo(a.playCount));
    return playedTracks.take(5).toList();
  }

  /// Obtener los 5 favoritos más recientes
  List<Track> getRecentFavorites() {
    final favorites = state.tracks.where((t) => t.isFavorite).toList();
    // Podríamos ordenar por fecha de "favoriteado" si tuviéramos ese dato,
    // por ahora usamos lastPlayedAt o simplemente los últimos 5.
    favorites.sort(
      (a, b) => (b.lastPlayedAt ?? DateTime(0)).compareTo(
        a.lastPlayedAt ?? DateTime(0),
      ),
    );
    return favorites.take(5).toList();
  }

  /// Editar metadatos de una pista
  Future<void> editTrack(String trackId, Map<String, dynamic> metadata) async {
    try {
      await _trackRepository.updateTrackMetadata(trackId, metadata);
      // Actualizar estado local inmediatamente
      state = state.copyWith(
        tracks: state.tracks.map((t) {
          if (t.id == trackId) {
            return t.copyWith(
              title: metadata['title'] as String?,
              artist: metadata['artist'] as String?,
              album: metadata['album'] as String?,
            );
          }
          return t;
        }).toList(),
      );
      // Sincronizar con el reproductor
      _audioPlayer.refreshTrackMetadata(trackId, metadata);
    } catch (e) {
      Logger.error('Error editing track', e);
    }
  }

  /// Borrar pista permanentemente
  Future<bool> deleteTrack(Track track) async {
    try {
      final success = await _audioRepository.deleteTrackFile(track);
      if (success) {
        // Limpiar base de datos
        await _trackRepository.deleteTrackData(track.id);
        // Actualizar UI
        state = state.copyWith(
          tracks: state.tracks.where((t) => t.id != track.id).toList(),
        );
        // Sincronizar con el reproductor
        _audioPlayer.notifyTrackDeleted(track.id);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Error deleting track', e);
      return false;
    }
  }
}
