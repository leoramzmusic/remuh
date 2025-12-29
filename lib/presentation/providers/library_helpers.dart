import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';

/// Sort options for library views
enum SortOption { name, date, plays, artist, album }

/// Provider for sort option
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.name);

/// Provider for layout toggle (list vs grid)
final isGridViewProvider = StateProvider<bool>((ref) => false);

/// Helper to sort tracks based on option
List<Track> sortTracks(List<Track> tracks, SortOption option) {
  final sorted = List<Track>.from(tracks);

  switch (option) {
    case SortOption.name:
      sorted.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortOption.date:
      // Sort by duration as proxy (Track doesn't have dateAdded)
      sorted.sort(
        (a, b) =>
            (b.duration?.inSeconds ?? 0).compareTo(a.duration?.inSeconds ?? 0),
      );
      break;
    case SortOption.plays:
      // TODO: Implement play count tracking
      sorted.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortOption.artist:
      sorted.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
      break;
    case SortOption.album:
      sorted.sort((a, b) => (a.album ?? '').compareTo(b.album ?? ''));
      break;
  }

  return sorted;
}

/// Helper to get sort option label
String getSortLabel(SortOption option) {
  switch (option) {
    case SortOption.name:
      return 'Nombre';
    case SortOption.date:
      return 'Fecha';
    case SortOption.plays:
      return 'Reproducciones';
    case SortOption.artist:
      return 'Artista';
    case SortOption.album:
      return 'Álbum';
  }
}
