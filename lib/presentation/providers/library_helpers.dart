import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import 'library_view_model.dart';

/// Provider for sorted tracks
final sortedTracksProvider = Provider<List<Track>>((ref) {
  final tracks = ref.watch(libraryViewModelProvider).tracks;
  final sortOption = ref.watch(sortOptionProvider);
  return sortTracks(tracks, sortOption);
});

/// Provider for grouping tracks into Album objects
final albumsProvider = Provider<List<Album>>((ref) {
  final tracks = ref.watch(libraryViewModelProvider).tracks;
  final albumsMap = <String, List<Track>>{};

  for (final track in tracks) {
    final albumName = track.album ?? 'Desconocido';
    albumsMap.putIfAbsent(albumName, () => []).add(track);
  }

  return albumsMap.entries.map((entry) {
    final albumTracks = entry.value;
    // Use first track as template for metadata
    final firstTrack = albumTracks.firstWhere(
      (t) => t.artworkPath != null,
      orElse: () => albumTracks.first,
    );
    return Album(
      title: entry.key,
      artist: firstTrack.artist ?? 'Desconocido',
      artworkPath: firstTrack.artworkPath,
      year: firstTrack.year,
      tracks: albumTracks,
    );
  }).toList();
});

/// Provider for sorted albums
final sortedAlbumsProvider = Provider<List<Album>>((ref) {
  final albums = ref.watch(albumsProvider);
  final sortOption = ref.watch(albumSortOptionProvider);
  return sortAlbums(albums, sortOption);
});

/// Provider for grouping tracks into Artist objects
final artistsProvider = Provider<List<Artist>>((ref) {
  final tracks = ref.watch(libraryViewModelProvider).tracks;
  final artistsMap = <String, List<Track>>{};

  for (final track in tracks) {
    final artistName = track.artist ?? 'Desconocido';
    artistsMap.putIfAbsent(artistName, () => []).add(track);
  }

  return artistsMap.entries.map((entry) {
    return Artist(name: entry.key, tracks: entry.value);
  }).toList();
});

/// Provider for sorted artists
final sortedArtistsProvider = Provider<List<Artist>>((ref) {
  final artists = ref.watch(artistsProvider);
  final sortOption = ref.watch(artistSortOptionProvider);
  return sortArtists(artists, sortOption);
});

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

enum AlbumSortOption {
  titleAsc,
  titleDesc,
  artistAz,
  artistZa,
  yearAsc,
  yearDesc,
}

enum ArtistSortOption { nameAz, nameZa, mostPlayed, trackCount }

/// Provider for sort option with persistence
final sortOptionProvider =
    StateNotifierProvider<SortOptionNotifier, SortOption>((ref) {
      return SortOptionNotifier();
    });

class SortOptionNotifier extends StateNotifier<SortOption> {
  static const String _keySortOption = 'library_sort_option';

  SortOptionNotifier() : super(SortOption.nameAz) {
    _loadSortOption();
  }

  Future<void> _loadSortOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_keySortOption);
      if (index != null && index < SortOption.values.length) {
        state = SortOption.values[index];
      }
    } catch (e) {
      // Fallback to default
    }
  }

  Future<void> setSortOption(SortOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySortOption, option.index);
  }
}

/// Provider for album sort option
final albumSortOptionProvider =
    StateNotifierProvider<AlbumSortOptionNotifier, AlbumSortOption>((ref) {
      return AlbumSortOptionNotifier();
    });

class AlbumSortOptionNotifier extends StateNotifier<AlbumSortOption> {
  static const String _keyAlbumSortOption = 'library_album_sort_option';

  AlbumSortOptionNotifier() : super(AlbumSortOption.titleAsc) {
    _loadSortOption();
  }

  Future<void> _loadSortOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_keyAlbumSortOption);
      if (index != null && index < AlbumSortOption.values.length) {
        state = AlbumSortOption.values[index];
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> setSortOption(AlbumSortOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAlbumSortOption, option.index);
  }
}

/// Provider for artist sort option
final artistSortOptionProvider =
    StateNotifierProvider<ArtistSortOptionNotifier, ArtistSortOption>((ref) {
      return ArtistSortOptionNotifier();
    });

class ArtistSortOptionNotifier extends StateNotifier<ArtistSortOption> {
  static const String _keyArtistSortOption = 'library_artist_sort_option';

  ArtistSortOptionNotifier() : super(ArtistSortOption.nameAz) {
    _loadSortOption();
  }

  Future<void> _loadSortOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_keyArtistSortOption);
      if (index != null && index < ArtistSortOption.values.length) {
        state = ArtistSortOption.values[index];
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> setSortOption(ArtistSortOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyArtistSortOption, option.index);
  }
}

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

/// Helper to sort albums
List<Album> sortAlbums(List<Album> albums, AlbumSortOption option) {
  final sorted = List<Album>.from(albums);

  switch (option) {
    case AlbumSortOption.titleAsc:
      sorted.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      break;
    case AlbumSortOption.titleDesc:
      sorted.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
      break;
    case AlbumSortOption.artistAz:
      sorted.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
      break;
    case AlbumSortOption.artistZa:
      sorted.sort(
        (a, b) => b.artist.toLowerCase().compareTo(a.artist.toLowerCase()),
      );
      break;
    case AlbumSortOption.yearAsc:
      sorted.sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));
      break;
    case AlbumSortOption.yearDesc:
      sorted.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      break;
  }

  return sorted;
}

/// Helper to sort artists
List<Artist> sortArtists(List<Artist> artists, ArtistSortOption option) {
  final sorted = List<Artist>.from(artists);

  switch (option) {
    case ArtistSortOption.nameAz:
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      break;
    case ArtistSortOption.nameZa:
      sorted.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
      break;
    case ArtistSortOption.mostPlayed:
      sorted.sort((a, b) {
        final aPlays = a.tracks.fold<int>(0, (sum, t) => sum + t.playCount);
        final bPlays = b.tracks.fold<int>(0, (sum, t) => sum + t.playCount);
        return bPlays.compareTo(aPlays);
      });
      break;
    case ArtistSortOption.trackCount:
      sorted.sort((a, b) => b.tracks.length.compareTo(a.tracks.length));
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

String getAlbumSortLabel(AlbumSortOption option) {
  switch (option) {
    case AlbumSortOption.titleAsc:
      return 'Título A-Z';
    case AlbumSortOption.titleDesc:
      return 'Título Z-A';
    case AlbumSortOption.artistAz:
      return 'Artista A-Z';
    case AlbumSortOption.artistZa:
      return 'Artista Z-A';
    case AlbumSortOption.yearAsc:
      return 'Año (Antiguo primero)';
    case AlbumSortOption.yearDesc:
      return 'Año (Reciente primero)';
  }
}

String getArtistSortLabel(ArtistSortOption option) {
  switch (option) {
    case ArtistSortOption.nameAz:
      return 'Nombre A-Z';
    case ArtistSortOption.nameZa:
      return 'Nombre Z-A';
    case ArtistSortOption.mostPlayed:
      return 'Más escuchados';
    case ArtistSortOption.trackCount:
      return 'Número de pistas';
  }
}
