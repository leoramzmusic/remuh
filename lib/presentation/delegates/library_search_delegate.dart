import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../providers/library_view_model.dart';
import '../providers/audio_player_provider.dart';
import '../screens/player_screen.dart';
import '../widgets/track_artwork.dart';
import '../providers/search_provider.dart';

class LibrarySearchDelegate extends SearchDelegate<Track?> {
  final WidgetRef ref;

  LibrarySearchDelegate(this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.surface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Buscar canciones, artistas...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchHistory(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchHistory(BuildContext context) {
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.white.withAlpha(50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tu historial de búsqueda aparecerá aquí',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Búsquedas recientes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: history.map((term) {
                  return InputChip(
                    label: Text(term),
                    onPressed: () {
                      query = term;
                      showResults(context);
                    },
                    onDeleted: () {
                      ref
                          .read(searchHistoryServiceProvider)
                          .removeEntry(term)
                          .then((_) => ref.refresh(searchHistoryProvider));
                    },
                  );
                }).toList(),
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ref
                          .read(searchHistoryServiceProvider)
                          .clearHistory()
                          .then((_) => ref.refresh(searchHistoryProvider));
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Borrar todo el historial'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    // Save to history if we are showing results and query is not empty
    // Actually, standard SearchDelegate usage suggests saving on 'showResults' or explicit submission.
    // But here we are live-searching. Users like history to be saved when they *select* a result
    // OR when they hit enter (if we had an enter button).
    // Given the UX, let's save when a user taps a result.

    final libraryState = ref.watch(libraryViewModelProvider);
    final allTracks = libraryState.tracks;

    if (query.isEmpty) {
      // Should not be reached due to buildSuggestions logic, but specific for buildResults
      return _buildSearchHistory(context);
    }

    final queryLower = query.toLowerCase();

    // Filter tracks
    final results = allTracks.where((track) {
      final titleMatch = track.title.toLowerCase().contains(queryLower);
      final artistMatch =
          track.artist?.toLowerCase().contains(queryLower) ?? false;
      final albumMatch =
          track.album?.toLowerCase().contains(queryLower) ?? false;
      return titleMatch || artistMatch || albumMatch;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron resultados para "$query"',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final track = results[index];
        final isActive = currentTrack?.id == track.id;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return ListTile(
          leading: Hero(
            tag: 'search_artwork_${track.id}',
            child: TrackArtwork(trackId: track.id, size: 48, borderRadius: 4),
          ),
          title: Row(
            children: [
              if (isActive) ...[
                Icon(Icons.play_arrow_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? primaryColor : null,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${track.artist ?? 'Desconocido'} • ${track.album ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? primaryColor.withValues(alpha: 0.8) : null,
            ),
          ),
          onTap: () {
            // Save query to history
            ref.read(searchHistoryServiceProvider).addEntry(query).then((_) {
              // Invalidate provider to refresh history elsewhere if needed
              ref.invalidate(searchHistoryProvider);
            });

            // Play the selected track from the search results
            // We create a playlist from the search results so the queue makes sense
            ref
                .read(audioPlayerProvider.notifier)
                .loadPlaylist(
                  results,
                  index,
                  playlistName: 'Resultados de búsqueda: "$query"',
                );

            // Close search and go to player
            close(context, track);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
        );
      },
    );
  }
}
