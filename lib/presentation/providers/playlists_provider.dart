import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
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

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());

class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final PlaylistRepository _repository;
  final ImageService _imageService;
  final Ref _ref;
  final _hiddenGenresKey = 'hidden_genres';
  final _customImagesKey = 'smart_playlist_images';

  PlaylistsNotifier(this._repository, this._imageService, this._ref)
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

      final playlists = await loadPlaylistsInternal();

      // Trigger background collage update
      _updatePlaylistCovers(playlists);

      return playlists;
    });
  }

  Future<void> _updatePlaylistCovers(List<Playlist> playlists) async {
    bool stateChanged = false;
    final updatedPlaylists = [...playlists];
    final libraryTracks = _ref.read(libraryViewModelProvider).tracks;

    for (int i = 0; i < updatedPlaylists.length; i++) {
      final playlist = updatedPlaylists[i];

      // Skip if it has a custom cover set (manual override)
      if (playlist.customCover != null) continue;

      // Only generate if we have tracks
      if (playlist.trackIds.isNotEmpty) {
        // Get Track objects first
        final tracks = playlist.trackIds
            .map(
              (id) => libraryTracks.firstWhere(
                (t) => t.id == id,
                orElse: () => const Track(id: '', title: '', filePath: ''),
              ),
            )
            .where(
              (t) =>
                  t.id.isNotEmpty &&
                  t.artworkPath != null &&
                  t.artworkPath!.isNotEmpty,
            )
            .toList();

        if (tracks.isNotEmpty) {
          List<Track> selectedTracks;

          if (playlist.isSmart) {
            if (playlist.smartType == 'top') {
              // Top: sort by playCount descending
              selectedTracks = List.from(tracks)
                ..sort((a, b) => b.playCount.compareTo(a.playCount));
            } else if (playlist.smartType == 'added') {
              // Added: sort by dateAdded descending
              selectedTracks = List.from(tracks)
                ..sort((a, b) {
                  final dateA = a.dateAdded ?? DateTime(2000);
                  final dateB = b.dateAdded ?? DateTime(2000);
                  return dateB.compareTo(dateA);
                });
            } else {
              // Genre or others: Shuffle
              selectedTracks = List.from(tracks)..shuffle();
            }
          } else {
            // Manual Playlists: Shuffle by default for dynamic cover
            selectedTracks = List.from(tracks)..shuffle();
          }

          // Take unique artworks
          final uniqueArtworks = <String>{};
          final selectedArtworks = <String>[];

          for (final track in selectedTracks) {
            if (selectedArtworks.length >= 4) break;
            if (track.artworkPath != null &&
                uniqueArtworks.add(track.artworkPath!)) {
              selectedArtworks.add(track.artworkPath!);
            }
          }

          // Generate if artwork found
          if (selectedArtworks.isNotEmpty) {
            final collagePath = await _imageService.generatePlaylistCollage(
              selectedArtworks,
              playlist.name,
            );

            if (collagePath != null && collagePath != playlist.coverUrl) {
              // Update in memory state
              // For manual playlists, we might want to verify if we should persist this generated URL
              // to DB 'coverUrl' field so it persists without re-generation every start?
              // The user requirement says "Actualizar collage automáticamente ... Al crear ... Al agregar".
              // Re-generating on load is fine, but persisting 'coverUrl' in DB for manual playlists improves startup perf.
              // However, 'loadPlaylistsInternal' reads from DB.
              // If we only update state here, it won't persist to DB 'coverUrl'.
              // Let's update state here. Persist optimization is secondary unless requested.
              // Actually, user said: "Guardar como imagen final ... Si quieres que el collage sea persistente ... guardas ese Uint8List como generatedCover".
              // Since I don't have 'generatedCover' field, I use 'coverUrl'.

              updatedPlaylists[i] = playlist.copyWith(coverUrl: collagePath);
              stateChanged = true;

              if (!playlist.isSmart) {
                // Ideally update DB too so we don't regenerate every single time if valid
                // But for now, let's keep it simple: State update.
                // Optionally: _repository.updatePlaylist(updatedPlaylists[i]);
              }
            }
          }
        }
      }
    }

    if (stateChanged && mounted) {
      state = AsyncValue.data(updatedPlaylists);
    }
  }

  Future<List<Playlist>> loadPlaylistsInternal() async {
    final userPlaylists = await _repository.getAllPlaylists();
    final libraryTracks = _ref.read(libraryViewModelProvider).tracks;

    // --- Smart Playlist Generation ---
    final smartPlaylists = <Playlist>[];

    // 1. Recently Added (Recién añadidas)
    final recentTracks = List<Track>.from(libraryTracks)
      ..sort((a, b) {
        final dateA = a.dateAdded ?? DateTime(2000);
        final dateB = b.dateAdded ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

    if (libraryTracks.isNotEmpty) {
      smartPlaylists.add(
        Playlist(
          id: -100,
          name: 'Recién añadidas',
          trackIds: recentTracks.take(50).map((t) => t.id).toList(),
          isSmart: true,
          smartType: 'added',
          canBeDeleted: false,
          canBeHidden: false,
          description: 'Canciones añadidas recientemente',
        ),
      );
    }

    // 2. Most Played (Más escuchadas)
    final topTracks = List<Track>.from(libraryTracks)
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    final topTracksFiltered = topTracks.where((t) => t.playCount > 0).take(100);
    if (libraryTracks.isNotEmpty) {
      smartPlaylists.add(
        Playlist(
          id: -101,
          name: 'Más escuchadas',
          trackIds: topTracksFiltered.map((t) => t.id).toList(),
          isSmart: true,
          smartType: 'top',
          canBeDeleted: false,
          canBeHidden: false,
          description: 'Tus 100 canciones favoritas',
        ),
      );
    }

    // 3. Genre Playlists (Por género)
    final Map<String, List<Track>> genres = {};
    for (var track in libraryTracks) {
      if (track.genre != null &&
          track.genre!.trim().isNotEmpty &&
          track.genre != '<unknown>') {
        genres.putIfAbsent(track.genre!, () => []).add(track);
      }
    }

    final sortedGenres = genres.keys.toList()..sort();
    var genreIdCounter = -200;

    for (final genre in sortedGenres) {
      final genreTracks = genres[genre]!;
      smartPlaylists.add(
        Playlist(
          id: genreIdCounter--,
          name: genre,
          trackIds: genreTracks.map((t) => t.id).toList(),
          isSmart: true,
          smartType: 'genre',
          canBeDeleted: false,
          canBeHidden: true,
          description: '${genreTracks.length} canciones',
        ),
      );
    }

    // 4. Favorites (Favoritos) - Moving here to treat as Smart
    final favorites = userPlaylists
        .where((p) => p.name == 'Favoritos')
        .firstOrNull;
    if (favorites != null) {
      smartPlaylists.add(
        favorites.copyWith(
          isSmart: true,
          smartType: 'favorites',
          canBeDeleted: false,
          canBeHidden:
              false, // Favoritos usually shouldn't be hidden in this section
        ),
      );
    }

    // 4. Spotify Section (Exportadas)
    final spotifyState = _ref.read(spotifyProvider);
    final allSpotifyTracks = spotifyState.savedTracks;

    // A. "Por conseguir" - Summary of all pending tracks
    final totalPending = allSpotifyTracks.where((t) => !t.isAcquired).length;
    if (totalPending > 0) {
      smartPlaylists.add(
        Playlist(
          id: -300,
          name: 'Por conseguir',
          trackIds: [], // Managed in SpotifyPendingTracksScreen
          isSmart: true,
          smartType: 'spotify_pending',
          canBeDeleted: false,
          canBeHidden: true,
          description: '$totalPending canciones pendientes de descargar',
        ),
      );
    }

    // B. Individual Exported Playlists
    for (var sPlaylist in spotifyState.playlists) {
      final pName = sPlaylist['name'] as String;
      final imageUrl =
          (sPlaylist['images'] as List?)?.firstOrNull?['url'] as String?;

      // Count tracks for this specific playlist in our local spotify_tracks db
      final pTracks = allSpotifyTracks.where((t) => t.playlistName == pName);
      final pPending = pTracks.where((t) => !t.isAcquired).length;
      final pAcquired = pTracks.where((t) => t.isAcquired).length;

      if (pTracks.isNotEmpty) {
        smartPlaylists.add(
          Playlist(
            id: -400 - sPlaylist.hashCode,
            name: pName,
            description: pPending > 0
                ? '$pPending pendientes • $pAcquired ya en biblioteca'
                : 'Sincronizada • $pAcquired canciones',
            coverUrl: imageUrl,
            isSmart: true,
            smartType: 'spotify_exported',
            canBeDeleted: false,
            canBeHidden: true,
            trackIds: [],
          ),
        );
      }
    }

    // --- Filter Hidden Smart Playlists ---
    final prefs = await SharedPreferences.getInstance();
    final hiddenKeys = prefs.getStringList(_hiddenGenresKey) ?? [];

    final visibleSmartPlaylists = smartPlaylists.map((p) {
      String key = p.name;
      if (p.smartType == 'genre') {
        key = 'genre_${p.name}';
      } else if (p.smartType == 'spotify_pending' ||
          p.smartType == 'spotify_exported') {
        key = 'spotify_${p.name}';
      }
      // If the key is in hiddenKeys, mark playlist as hidden
      return p.copyWith(isHidden: hiddenKeys.contains(key));
    }).toList();

    // --- Combine All ---
    final allPlaylists = <Playlist>[];

    // Add Smart Playlists (Screen will handle filtering and visual sections)
    allPlaylists.addAll(visibleSmartPlaylists);

    // Add User Playlists (NOT favorites, as it's now smart)
    final otherUserPlaylists = userPlaylists.where(
      (p) => p.name != 'Favoritos',
    );
    allPlaylists.addAll(otherUserPlaylists);

    return allPlaylists;
  }

  Future<void> createPlaylist(
    String name, {
    String? description,
    String? coverPath,
  }) async {
    await _repository.createPlaylist(
      Playlist(name: name, description: description, customCover: coverPath),
    );
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

  Future<void> deletePlaylist(int id) async {
    await _repository.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<void> toggleGenreVisibility(String name, bool isGenre) async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenGenres = prefs.getStringList(_hiddenGenresKey) ?? [];

    final key = isGenre ? 'genre_$name' : name;

    if (hiddenGenres.contains(key)) {
      hiddenGenres.remove(key);
    } else {
      hiddenGenres.add(key);
    }

    await prefs.setStringList(_hiddenGenresKey, hiddenGenres);
    await loadPlaylists();
  }

  Future<void> updatePlaylistCover(Playlist playlist, String? path) async {
    if (playlist.isSmart) {
      final prefs = await SharedPreferences.getInstance();
      final customImages = <String, String>{};
      final savedImagesList = prefs.getStringList(_customImagesKey) ?? [];

      for (final entry in savedImagesList) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          customImages[parts[0]] = parts[1];
        }
      }

      String key = playlist.smartType ?? '';
      if (playlist.smartType == 'genre') {
        key = 'genre_${playlist.name}';
      }

      if (path == null) {
        customImages.remove(key);
      } else {
        customImages[key] = path;
      }

      final newSavedList = customImages.entries
          .map((e) => '${e.key}|${e.value}')
          .toList();

      await prefs.setStringList(_customImagesKey, newSavedList);
    } else {
      // Manual Playlists - Update DB
      // customCover being null means "Automatic"
      await _repository.updatePlaylist(playlist.copyWith(customCover: path));
    }
    await loadPlaylists();
  }

  Future<void> toggleFavorite(String trackId) async {
    final playlists = state.value ?? [];
    Playlist? favorites = playlists
        .where((p) => p.name == 'Favoritos')
        .firstOrNull;

    if (favorites == null) {
      await _repository.createPlaylist(Playlist(name: 'Favoritos'));
      await _repository.createPlaylist(Playlist(name: 'Favoritos'));
      // Ideally we just call loadPlaylists() full cycle
      // but we need favorites ID.
      // Let's just create and reload.
      await loadPlaylists();
      final newState = state.value ?? [];
      favorites = newState.firstWhere((p) => p.name == 'Favoritos');
    }

    if (favorites.trackIds.contains(trackId)) {
      await removeTrackFromPlaylist(favorites.id!, trackId);
    } else {
      await addTrackToPlaylist(favorites.id!, trackId);
    }
  }

  /// Sync favorite status from LibraryViewModel
  Future<void> syncFavoriteStatus(String trackId, bool isFavorite) async {
    // Similar logic to toggleFavorite but checking status
    // Using loadPlaylists cycle ensures robustness
    final playlists = state.value ?? [];
    Playlist? favorites = playlists
        .where((p) => p.name == 'Favoritos')
        .firstOrNull;

    if (favorites == null && isFavorite) {
      await _repository.createPlaylist(Playlist(name: 'Favoritos'));
      await loadPlaylists();
      final newState = state.value ?? [];
      favorites = newState.firstWhere((p) => p.name == 'Favoritos');
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
      final imageService = ref.watch(imageServiceProvider);
      return PlaylistsNotifier(repository, imageService, ref);
    });
