import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../services/database_service.dart';
import 'audio_player_provider.dart';
import 'library_view_model.dart';
import 'spotify_provider.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PlaylistRepositoryImpl(dbService);
});

class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final PlaylistRepository _repository;
  final Ref _ref;

  PlaylistsNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadPlaylists();

    // Refresh smart playlists when library changes
    _ref.listen(libraryViewModelProvider, (previous, next) {
      if (previous?.tracks.length != next.tracks.length ||
          previous?.isScanning != next.isScanning) {
        if (!next.isScanning) {
          loadPlaylists();
        }
      }
    });

    // Refresh when Spotify tracks change
    _ref.listen(spotifyProvider, (previous, next) {
      if (previous?.savedTracks.length != next.savedTracks.length) {
        loadPlaylists();
      }
    });
  }

  Future<void> loadPlaylists() async {
    state = await AsyncValue.guard(() async {
      final userPlaylists = await _repository.getAllPlaylists();

      // Ensure "Favoritos" exists and is first
      if (!userPlaylists.any((p) => p.name == 'Favoritos')) {
        await _repository.createPlaylist(Playlist(name: 'Favoritos'));
        return await loadPlaylistsInternal();
      }

      return await loadPlaylistsInternal();
    });
  }

  Future<List<Playlist>> loadPlaylistsInternal() async {
    final userPlaylists = await _repository.getAllPlaylists();
    final libraryTracks = _ref.read(libraryViewModelProvider).tracks;

    final List<Playlist> smartPlaylists = [];

    // 1. Recientes (Historial)
    final recentlyPlayedIds = await _repository.getRecentlyPlayedTrackIds(50);
    if (recentlyPlayedIds.isNotEmpty) {
      smartPlaylists.add(
        Playlist(
          id: -1,
          name: 'Escuchadas recientemente',
          description: 'Tu historial de reproducción reciente',
          trackIds: recentlyPlayedIds,
          isSmart: true,
          smartType: 'recent',
        ),
      );
    }

    // 2. Más escuchadas (Global)
    final mostPlayedIds = await _repository.getMostPlayedTrackIds(50);
    if (mostPlayedIds.isNotEmpty) {
      smartPlaylists.add(
        Playlist(
          id: -2,
          name: 'Tus favoritas (Top 50)',
          description: 'Las canciones que más has disfrutado',
          trackIds: mostPlayedIds,
          isSmart: true,
          smartType: 'top',
        ),
      );
    }

    // 3. Recientemente añadidas
    final recentlyAdded = libraryTracks.toList()
      ..sort((a, b) {
        final dateA = a.dateAdded ?? DateTime(2000);
        final dateB = b.dateAdded ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

    final recentlyAddedIds = recentlyAdded.take(50).map((t) => t.id).toList();
    if (recentlyAddedIds.isNotEmpty) {
      smartPlaylists.add(
        Playlist(
          id: -4,
          name: 'Recién añadidas',
          description: 'Lo último que ha llegado a tu biblioteca',
          trackIds: recentlyAddedIds,
          isSmart: true,
          smartType: 'added',
        ),
      );
    }

    // 4. Por conseguir (from Spotify)
    final spotifyTracks = _ref
        .read(spotifyProvider)
        .savedTracks
        .where((t) => !t.isAcquired)
        .toList();

    if (spotifyTracks.isNotEmpty) {
      smartPlaylists.add(
        Playlist(
          id: -3,
          name: 'Por conseguir',
          description: 'Pendientes de Spotify 🛒',
          trackIds: [], // Custom screen
          isSmart: true,
          smartType: 'spotify_pending',
        ),
      );
    }

    // 5. Por Género (Sorted by total playCount in that genre)
    final Map<String, List<Track>> genreTracks = {};
    for (final track in libraryTracks) {
      final genre = track.genre ?? 'Desconocido';
      if (!genreTracks.containsKey(genre)) {
        genreTracks[genre] = [];
      }
      genreTracks[genre]!.add(track);
    }

    final genrePlaylists =
        genreTracks.entries.where((e) => e.value.length >= 3).map((e) {
          final totalPlays = (e.value as List<Track>).fold(
            0,
            (sum, t) => sum + (t.playCount),
          );
          return MapEntry(e.key, {'tracks': e.value, 'plays': totalPlays});
        }).toList()..sort(
          (a, b) =>
              (b.value['plays'] as int).compareTo(a.value['plays'] as int),
        );

    final List<Playlist> genreSmartPlaylists = genrePlaylists.map((e) {
      final genre = e.key;
      final tracks = e.value['tracks'] as List<Track>;
      return Playlist(
        id: -100 - genreTracks.keys.toList().indexOf(genre),
        name: '$genre Mix',
        description: 'Lo mejor del género $genre',
        trackIds: tracks.map((t) => t.id).toList(),
        isSmart: true,
        smartType: 'genre',
      );
    }).toList();

    // Sort user playlists - Favoritos first, then alphabetical
    final sortedUserPlaylists = userPlaylists.toList()
      ..sort((a, b) {
        if (a.name == 'Favoritos') return -1;
        if (b.name == 'Favoritos') return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return [...smartPlaylists, ...genreSmartPlaylists, ...sortedUserPlaylists];
  }

  Future<void> createPlaylist(
    String name, {
    String? description,
    String? coverUrl,
  }) async {
    final newPlaylist = Playlist(
      name: name,
      description: description,
      coverUrl: coverUrl,
    );
    await _repository.createPlaylist(newPlaylist);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(int id) async {
    await _repository.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<void> addTrackToPlaylist(int playlistId, String trackId) async {
    await _repository.addTrackToPlaylist(playlistId, trackId);
    await loadPlaylists();
  }

  Future<void> removeTrackFromPlaylist(int playlistId, String trackId) async {
    await _repository.removeTrackFromPlaylist(playlistId, trackId);
    await loadPlaylists();
  }

  Future<void> toggleFavorite(String trackId) async {
    final playlists = state.value ?? [];
    Playlist? favorites = playlists
        .where((p) => p.name == 'Favoritos')
        .firstOrNull;

    if (favorites == null) {
      await _repository.createPlaylist(Playlist(name: 'Favoritos'));
      final all = await _repository.getAllPlaylists();
      state = AsyncValue.data(all);
      favorites = all.firstWhere((p) => p.name == 'Favoritos');
    }

    if (favorites.trackIds.contains(trackId)) {
      await removeTrackFromPlaylist(favorites.id!, trackId);
    } else {
      await addTrackToPlaylist(favorites.id!, trackId);
    }
  }

  /// Sync favorite status from LibraryViewModel
  Future<void> syncFavoriteStatus(String trackId, bool isFavorite) async {
    final playlists = state.value ?? [];
    Playlist? favorites = playlists
        .where((p) => p.name == 'Favoritos')
        .firstOrNull;

    if (favorites == null && isFavorite) {
      await _repository.createPlaylist(Playlist(name: 'Favoritos'));
      final all = await _repository.getAllPlaylists();
      state = AsyncValue.data(all);
      favorites = all.firstWhere((p) => p.name == 'Favoritos');
    }

    if (favorites != null) {
      final contains = favorites.trackIds.contains(trackId);
      if (isFavorite && !contains) {
        await addTrackToPlaylist(favorites.id!, trackId);
      } else if (!isFavorite && contains) {
        await removeTrackFromPlaylist(favorites.id!, trackId);
      }
    }
  }

  bool isFavorite(String trackId) {
    final playlists = state.value ?? [];
    final favorites = playlists.where((p) => p.name == 'Favoritos').firstOrNull;
    return favorites?.trackIds.contains(trackId) ?? false;
  }

  Future<void> playPlaylist(Playlist playlist, {bool shuffle = false}) async {
    final libraryTracks = _ref.read(libraryViewModelProvider).tracks;

    final List<Track> tracksToPlay = [];
    for (final id in playlist.trackIds) {
      final track = libraryTracks.where((t) => t.id == id).firstOrNull;
      if (track != null) {
        tracksToPlay.add(track);
      }
    }

    if (tracksToPlay.isEmpty) return;

    final player = _ref.read(audioPlayerProvider.notifier);
    await player.loadPlaylist(
      tracksToPlay,
      0,
      startShuffled: shuffle,
      playlistName: playlist.name,
    );
  }

  Future<void> playPlaylistWithTrack(
    Playlist playlist,
    String trackId, {
    bool shuffle = false,
  }) async {
    final libraryTracks = _ref.read(libraryViewModelProvider).tracks;

    final List<Track> tracksToPlay = [];
    int startIndex = 0;
    for (final id in playlist.trackIds) {
      final track = libraryTracks.where((t) => t.id == id).firstOrNull;
      if (track != null) {
        if (track.id == trackId) {
          startIndex = tracksToPlay.length;
        }
        tracksToPlay.add(track);
      }
    }

    if (tracksToPlay.isEmpty) return;

    final player = _ref.read(audioPlayerProvider.notifier);
    await player.loadPlaylist(
      tracksToPlay,
      startIndex,
      startShuffled: shuffle,
      playlistName: playlist.name,
    );
  }
}

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, AsyncValue<List<Playlist>>>((ref) {
      final repository = ref.watch(playlistRepositoryProvider);
      return PlaylistsNotifier(repository, ref);
    });
