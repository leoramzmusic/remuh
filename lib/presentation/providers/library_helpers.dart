import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import 'library_view_model.dart';

/// Provider for sorted tracks
final sortedTracksProvider = Provider<List<Track>>((ref) {
  final tracks = ref.watch(libraryViewModelProvider).tracks;
  final sortOption = ref.watch(sortOptionProvider);
  return sortTracks(tracks, sortOption);
});

/// Sort options for library views
enum SortOption {
  nameAz,
  nameZa,
  dateAdded,
  albumAz,
  albumZa,
  artistAz,
  artistZa,
  albumArtistAz,
  albumArtistZa,
  duration,
  yearAsc,
  yearDesc,
  mostPlayed,
}

/// Provider for sort option
final sortOptionProvider = StateProvider<SortOption>(
  (ref) => SortOption.nameAz,
);

/// Provider for layout toggle (list vs grid)
final isGridViewProvider = StateProvider<bool>((ref) => false);

/// Helper to sort tracks based on option
List<Track> sortTracks(List<Track> tracks, SortOption option) {
  final sorted = List<Track>.from(tracks);

  switch (option) {
    case SortOption.nameAz:
      sorted.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      break;
    case SortOption.nameZa:
      sorted.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
      break;
    case SortOption.dateAdded:
      sorted.sort(
        (a, b) =>
            (b.dateAdded ?? DateTime(0)).compareTo(a.dateAdded ?? DateTime(0)),
      );
      break;
    case SortOption.albumAz:
      sorted.sort(
        (a, b) => (a.album ?? '').toLowerCase().compareTo(
          (b.album ?? '').toLowerCase(),
        ),
      );
      break;
    case SortOption.albumZa:
      sorted.sort(
        (a, b) => (b.album ?? '').toLowerCase().compareTo(
          (a.album ?? '').toLowerCase(),
        ),
      );
      break;
    case SortOption.artistAz:
      sorted.sort(
        (a, b) => (a.artist ?? '').toLowerCase().compareTo(
          (b.artist ?? '').toLowerCase(),
        ),
      );
      break;
    case SortOption.artistZa:
      sorted.sort(
        (a, b) => (b.artist ?? '').toLowerCase().compareTo(
          (a.artist ?? '').toLowerCase(),
        ),
      );
      break;
    case SortOption.albumArtistAz:
      sorted.sort((a, b) {
        final artistComp = (a.artist ?? '').toLowerCase().compareTo(
          (b.artist ?? '').toLowerCase(),
        );
        if (artistComp != 0) return artistComp;
        return (a.album ?? '').toLowerCase().compareTo(
          (b.album ?? '').toLowerCase(),
        );
      });
      break;
    case SortOption.albumArtistZa:
      sorted.sort((a, b) {
        final artistComp = (b.artist ?? '').toLowerCase().compareTo(
          (a.artist ?? '').toLowerCase(),
        );
        if (artistComp != 0) return artistComp;
        return (b.album ?? '').toLowerCase().compareTo(
          (a.album ?? '').toLowerCase(),
        );
      });
      break;
    case SortOption.duration:
      sorted.sort(
        (a, b) => (b.duration ?? Duration.zero).compareTo(
          a.duration ?? Duration.zero,
        ),
      );
      break;
    case SortOption.yearAsc:
      sorted.sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));
      break;
    case SortOption.yearDesc:
      sorted.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      break;
    case SortOption.mostPlayed:
      sorted.sort((a, b) => b.playCount.compareTo(a.playCount));
      break;
  }

  return sorted;
}

/// Helper to get sort option label
String getSortLabel(SortOption option) {
  switch (option) {
    case SortOption.nameAz:
      return 'Nombre A-Z';
    case SortOption.nameZa:
      return 'Nombre Z-A';
    case SortOption.dateAdded:
      return 'Fecha de añadido';
    case SortOption.albumAz:
      return 'Álbum A-Z';
    case SortOption.albumZa:
      return 'Álbum Z-A';
    case SortOption.artistAz:
      return 'Artista A-Z';
    case SortOption.artistZa:
      return 'Artista Z-A';
    case SortOption.albumArtistAz:
      return 'Álbum por artista A-Z';
    case SortOption.albumArtistZa:
      return 'Álbum por artista Z-A';
    case SortOption.duration:
      return 'Duración';
    case SortOption.yearAsc:
      return 'Año (Ascendente)';
    case SortOption.yearDesc:
      return 'Año (Descendente)';
    case SortOption.mostPlayed:
      return 'Más reproducidas';
  }
}
