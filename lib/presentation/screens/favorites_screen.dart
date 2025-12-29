import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';

import 'test_player_screen.dart'; // Correct import

/// Favorites screen with heart icon and play functionality
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteTracks = ref.watch(favoriteTracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          if (favoriteTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () {
                ref
                    .read(audioPlayerProvider.notifier)
                    .loadPlaylist(favoriteTracks, 0);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestPlayerScreen(),
                  ),
                );
              },
              tooltip: 'Reproducir todo',
            ),
          if (favoriteTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Limpiar favoritos'),
                    content: const Text(
                      '¿Estás seguro de que quieres eliminar todos los favoritos?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).clearAll();
                          Navigator.pop(context);
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Limpiar favoritos',
            ),
        ],
      ),
      body: favoriteTracks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay favoritos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el ❤️ en cualquier canción para agregarla',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favoriteTracks.length,
              itemBuilder: (context, index) {
                final track = favoriteTracks[index];
                final isFavorite = ref
                    .watch(favoritesProvider)
                    .contains(track.id);

                return ListTile(
                  leading: TrackArtwork(
                    trackId: track.id,
                    size: 48,
                    borderRadius: 4,
                  ),
                  title: Text(track.title),
                  subtitle: Text(track.artist ?? 'Desconocido'),
                  trailing: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      ref.read(favoritesProvider.notifier).toggle(track.id);
                    },
                  ),
                  onTap: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .loadPlaylist(favoriteTracks, index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TestPlayerScreen(), // Debugging
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
