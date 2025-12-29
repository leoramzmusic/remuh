import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/track.dart';
import '../../providers/library_view_model.dart';
import '../../providers/library_helpers.dart';

/// Genres view - automatic genre classification
class GenresView extends ConsumerWidget {
  const GenresView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(libraryViewModelProvider).tracks;
    final isGrid = ref.watch(isGridViewProvider);

    // Group tracks by genre (using album as placeholder since Track doesn't have genre)
    // TODO: Add genre property to Track entity
    final genreMap = <String, List<Track>>{};
    for (final track in tracks) {
      final genre = track.album ?? 'Desconocido';
      genreMap.putIfAbsent(genre, () => []).add(track);
    }

    final genres = genreMap.keys.toList()..sort();

    if (genres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay géneros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          final trackCount = genreMap[genre]!.length;

          return Card(
            child: InkWell(
              onTap: () {
                // TODO: Navigate to genre detail
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Género: $genre')));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.album_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      genre,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$trackCount ${trackCount == 1 ? 'canción' : 'canciones'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final trackCount = genreMap[genre]!.length;

        return ListTile(
          leading: const Icon(Icons.album_rounded),
          title: Text(genre),
          subtitle: Text(
            '$trackCount ${trackCount == 1 ? 'canción' : 'canciones'}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            // TODO: Navigate to genre detail
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Género: $genre')));
          },
        );
      },
    );
  }
}
