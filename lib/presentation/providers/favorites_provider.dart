import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/track.dart';
import 'library_view_model.dart';

/// Provider for favorites
class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  static const String _keyFavorites = 'favorites';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_keyFavorites) ?? [];
    state = favoriteIds;
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, state);
  }

  /// Toggle favorite status for a track
  Future<void> toggle(String trackId) async {
    if (state.contains(trackId)) {
      state = state.where((id) => id != trackId).toList();
    } else {
      state = [...state, trackId];
    }
    await _saveFavorites();
  }

  /// Check if track is favorite
  bool isFavorite(String trackId) {
    return state.contains(trackId);
  }

  /// Clear all favorites
  Future<void> clearAll() async {
    state = [];
    await _saveFavorites();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
      return FavoritesNotifier();
    });

/// Provider for favorite tracks (actual Track objects)
final favoriteTracksProvider = Provider<List<Track>>((ref) {
  final favoriteIds = ref.watch(favoritesProvider);
  final allTracks = ref.watch(libraryViewModelProvider).tracks;

  return allTracks.where((track) => favoriteIds.contains(track.id)).toList();
});
