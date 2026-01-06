import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/spotify_track.dart';
import '../../domain/repositories/spotify_repository.dart';
import '../../data/repositories/spotify_repository_impl.dart';
import '../../services/spotify_service.dart';
import 'library_view_model.dart';
import 'playlists_provider.dart';

final spotifyServiceProvider = Provider<SpotifyService>(
  (ref) => SpotifyService(),
);

final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SpotifyRepositoryImpl(dbService);
});

class SpotifyState {
  final bool isAuthenticated;
  final bool isSyncing;
  final List<SpotifyTrack> savedTracks;
  final List<Map<String, dynamic>> playlists;

  SpotifyState({
    this.isAuthenticated = false,
    this.isSyncing = false,
    this.savedTracks = const [],
    this.playlists = const [],
  });

  SpotifyState copyWith({
    bool? isAuthenticated,
    bool? isSyncing,
    List<SpotifyTrack>? savedTracks,
    List<Map<String, dynamic>>? playlists,
  }) {
    return SpotifyState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSyncing: isSyncing ?? this.isSyncing,
      savedTracks: savedTracks ?? this.savedTracks,
      playlists: playlists ?? this.playlists,
    );
  }
}

class SpotifyNotifier extends StateNotifier<SpotifyState> {
  final SpotifyService _service;
  final SpotifyRepository _repository;
  final Ref _ref;
  String? _accessToken;

  SpotifyNotifier(this._service, this._repository, this._ref)
    : super(SpotifyState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_token');
    final tracks = await _repository.getAllSavedTracks();

    state = state.copyWith(
      isAuthenticated: _accessToken != null,
      savedTracks: tracks,
    );
  }

  Future<void> login() async {
    final token = await _service.authenticate();
    if (token != null) {
      _accessToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('spotify_token', token);

      final playlists = await _service.getUserPlaylists(token);
      state = state.copyWith(isAuthenticated: true, playlists: playlists);
    }
  }

  Future<void> syncPlaylist(String playlistId, String playlistName) async {
    if (_accessToken == null) return;

    state = state.copyWith(isSyncing: true);
    try {
      final spotifyTracks = await _service.getPlaylistTracks(
        _accessToken!,
        playlistId,
        playlistName,
      );

      // Filtrar tracks que ya existen localmente
      final libraryTracks = _ref.read(libraryViewModelProvider).tracks;

      final List<SpotifyTrack> pendingTracks = [];
      for (final sTrack in spotifyTracks) {
        final existsLocally = libraryTracks.any((lTrack) {
          final sTitle = sTrack.title.toLowerCase();
          final sArtist = sTrack.artist.toLowerCase();
          final lTitle = lTrack.title.toLowerCase();
          final lArtist = (lTrack.artist ?? '').toLowerCase();

          return (lTitle.contains(sTitle) || sTitle.contains(lTitle)) &&
              (lArtist.contains(sArtist) || sArtist.contains(lArtist));
        });

        if (!existsLocally) {
          pendingTracks.add(sTrack);
        }
      }

      await _repository.saveSpotifyTracks(pendingTracks);
      final allTracks = await _repository.getAllSavedTracks();

      state = state.copyWith(savedTracks: allTracks, isSyncing: false);

      // Refresh playlists to show "Por conseguir"
      _ref.read(playlistsProvider.notifier).loadPlaylists();
    } catch (e) {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> markAsAcquired(String spotifyId, bool acquired) async {
    await _repository.markAsAcquired(spotifyId, acquired);
    final tracks = await _repository.getAllSavedTracks();
    state = state.copyWith(savedTracks: tracks);
    _ref.read(playlistsProvider.notifier).loadPlaylists();
  }

  Future<void> deleteTrack(String spotifyId) async {
    await _repository.deleteTrack(spotifyId);
    final tracks = await _repository.getAllSavedTracks();
    state = state.copyWith(savedTracks: tracks);
    _ref.read(playlistsProvider.notifier).loadPlaylists();
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_token');
    _accessToken = null;
    state = state.copyWith(isAuthenticated: false, playlists: []);
  }
}

final spotifyProvider = StateNotifierProvider<SpotifyNotifier, SpotifyState>((
  ref,
) {
  final service = ref.watch(spotifyServiceProvider);
  final repository = ref.watch(spotifyRepositoryProvider);
  return SpotifyNotifier(service, repository, ref);
});
