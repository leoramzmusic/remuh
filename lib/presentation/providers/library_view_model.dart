import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../../domain/usecases/scan_tracks.dart';
import 'audio_player_provider.dart';

// Estado de la biblioteca
class LibraryState {
  final List<Track> tracks;
  final bool isScanning;
  final int lastAddedCount;
  final String? error;

  LibraryState({
    this.tracks = const [],
    this.isScanning = false,
    this.lastAddedCount = 0,
    this.error,
  });

  LibraryState copyWith({
    List<Track>? tracks,
    bool? isScanning,
    int? lastAddedCount,
    String? error,
  }) {
    return LibraryState(
      tracks: tracks ?? this.tracks,
      isScanning: isScanning ?? this.isScanning,
      lastAddedCount: lastAddedCount ?? this.lastAddedCount,
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

  LibraryViewModel(this._scanTracks) : super(LibraryState()) {
    scanLibrary(initial: true);
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

      state = state.copyWith(
        tracks: newTracks,
        isScanning: false,
        lastAddedCount: added,
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }
}
