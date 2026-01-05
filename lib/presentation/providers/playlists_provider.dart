import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PlaylistRepositoryImpl(dbService);
});

class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final PlaylistRepository _repository;

  PlaylistsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    state = await AsyncValue.guard(() async {
      final playlists = await _repository.getAllPlaylists();
      if (!playlists.any((p) => p.name == 'Favoritos')) {
        await _repository.createPlaylist(Playlist(name: 'Favoritos'));
        return await _repository.getAllPlaylists();
      }
      return playlists;
    });
  }

  Future<void> createPlaylist(String name) async {
    final newPlaylist = Playlist(name: name);
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
}

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, AsyncValue<List<Playlist>>>((ref) {
      final repository = ref.watch(playlistRepositoryProvider);
      return PlaylistsNotifier(repository);
    });
