import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/track.dart';
import '../../domain/usecases/scan_tracks.dart';
import 'audio_player_provider.dart';

// Estado de la biblioteca
class LibraryState {
  final List<Track> tracks;
  final bool isScanning;
  final int lastAddedCount;
  final DateTime? lastScanTime;
  final String? error;

  LibraryState({
    this.tracks = const [],
    this.isScanning = false,
    this.lastAddedCount = 0,
    this.lastScanTime,
    this.error,
  });

  LibraryState copyWith({
    List<Track>? tracks,
    bool? isScanning,
    int? lastAddedCount,
    DateTime? lastScanTime,
    String? error,
  }) {
    return LibraryState(
      tracks: tracks ?? this.tracks,
      isScanning: isScanning ?? this.isScanning,
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
      return LibraryViewModel(scanTracks);
    });

class LibraryViewModel extends StateNotifier<LibraryState> {
  final ScanTracks _scanTracks;
  static const String _keyLastScanTime = 'library_last_scan_time';

  LibraryViewModel(this._scanTracks) : super(LibraryState()) {
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
    if (state.isScanning) return;

    state = state.copyWith(isScanning: true, error: null);
    try {
      final currentIds = state.tracks.map((t) => t.id).toSet();
      final newTracks = await _scanTracks();

      // Calcular cuántas son realmente nuevas
      int added = 0;
      if (!initial) {
        added = newTracks.where((t) => !currentIds.contains(t.id)).length;
      }

      await _saveLastScanTime();

      state = state.copyWith(
        tracks: newTracks,
        isScanning: false,
        lastAddedCount: added,
        lastScanTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
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
}
