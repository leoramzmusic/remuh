import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../services/database_service.dart';
import 'audio_player_provider.dart';
import 'library_view_model.dart';

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
  }

  Future<void> loadPlaylists() async {
    state = await AsyncValue.guard(() async {
      final playlists = await _repository.getAllPlaylists();

      // Ensure "Favoritos" exists
      if (!playlists.any((p) => p.name == 'Favoritos')) {
        await _repository.createPlaylist(Playlist(name: 'Favoritos'));
        return await _repository.getAllPlaylists();
      }

      final libraryTracks = _ref.read(libraryViewModelProvider).tracks;
      if (libraryTracks.isEmpty) {
        return playlists;
      }

      // 1. Recientes
      final recentlyPlayedIds = await _repository.getRecentlyPlayedTrackIds(50);

      // 2. Más escuchadas
      final mostPlayedIds = await _repository.getMostPlayedTrackIds(50);

      // 3. Por Género
      final Map<String, List<String>> genreMap = {};
      for (final track in libraryTracks) {
        final genre = track.genre ?? 'Desconocido';
        if (!genreMap.containsKey(genre)) {
          genreMap[genre] = [];
        }
        genreMap[genre]!.add(track.id);
      }

      final smartPlaylists = [
        Playlist(
          id: -1,
          name: 'Escuchadas recientemente',
          description: 'Tus últimas canciones reproducidas',
          trackIds: recentlyPlayedIds,
          isSmart: true,
          smartType: 'recent',
        ),
        Playlist(
          id: -2,
          name: 'Más escuchadas',
          description: 'Tus canciones favoritas por excelencia',
          trackIds: mostPlayedIds,
          isSmart: true,
          smartType: 'top',
        ),
      ];

      // Add genre playlists (only if they have more than 2 songs to keep it clean)
      final genrePlaylists =
          genreMap.entries
              .where((e) => e.value.length >= 2)
              .map(
                (e) => Playlist(
                  id: -100 - genreMap.keys.toList().indexOf(e.key),
                  name: e.key,
                  description: 'Colección de ${e.key}',
                  trackIds: e.value,
                  isSmart: true,
                  smartType: 'genre',
                ),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      return [...smartPlaylists, ...genrePlaylists, ...playlists];
    });
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
