import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import 'library_view_model.dart';

/// Provider for favorite tracks (actual Track objects)
/// Now derives directly from LibraryViewModel tracks based on isFavorite property
final favoriteTracksProvider = Provider<List<Track>>((ref) {
  // Watch all tracks for any favorite change
  final allTracks = ref.watch(libraryViewModelProvider).tracks;
  return allTracks.where((track) => track.isFavorite).toList();
});

/// Keep favoritesProvider for legacy reasons but make it a simple list of favorite IDs
/// This maintains compatibility with widgets that only need the list of IDs
final favoritesProvider = Provider<List<String>>((ref) {
  final favoriteTracks = ref.watch(favoriteTracksProvider);
  return favoriteTracks.map((t) => t.id).toList();
});
