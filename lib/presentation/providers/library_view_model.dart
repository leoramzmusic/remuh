import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../../domain/usecases/scan_tracks.dart';
import 'audio_player_provider.dart';

// Provider principal de la biblioteca
final libraryViewModelProvider =
    StateNotifierProvider<LibraryViewModel, AsyncValue<List<Track>>>((ref) {
      final scanTracks = ref.watch(scanTracksUseCaseProvider);
      return LibraryViewModel(scanTracks);
    });

class LibraryViewModel extends StateNotifier<AsyncValue<List<Track>>> {
  final ScanTracks _scanTracks;

  LibraryViewModel(this._scanTracks) : super(const AsyncValue.loading()) {
    scanLibrary();
  }

  Future<void> scanLibrary() async {
    state = const AsyncValue.loading();
    try {
      final tracks = await _scanTracks();
      state = AsyncValue.data(tracks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
