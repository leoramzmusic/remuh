import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../providers/favorites_provider.dart';
import '../providers/library_view_model.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';

import 'player_screen.dart';

/// Favorites screen with heart icon and play functionality
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteTracks = ref.watch(favoriteTracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Favoritos'),
            Text(
              '${favoriteTracks.length} canciones ❤️',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          if (favoriteTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () {
                ref
                    .read(audioPlayerProvider.notifier)
                    .loadPlaylist(favoriteTracks, 0);
                ref.read(audioPlayerProvider.notifier).toggleShuffle();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reproducción aleatoria activada 🔀'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Reproducción aleatoria',
            ),
          if (favoriteTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () {
                ref
                    .read(audioPlayerProvider.notifier)
                    .loadPlaylist(favoriteTracks, 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reproduciendo tus favoritos ❤️'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlayerScreen()),
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
                          ref
                              .read(libraryViewModelProvider.notifier)
                              .clearAllFavorites();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Favoritos eliminados'),
                            ),
                          );
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
                final isCurrentPlaying = ref.watch(
                  audioPlayerProvider.select(
                    (s) => s.currentTrack?.id == track.id,
                  ),
                );

                return Dismissible(
                  key: Key('fav_${track.id}'),
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      // Swipe right -> Add to playlist
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddToPlaylistSheet(track: track),
                      );
                      return false; // Don't dismiss
                    }
                    return true; // Dismiss for left swipe
                  },
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.blueAccent,
                    child: const Icon(Icons.playlist_add, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      ref
                          .read(libraryViewModelProvider.notifier)
                          .toggleFavorite(track.id);
                    }
                  },
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrentPlaying
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white38,
                              fontWeight: isCurrentPlaying
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        _PlayingArtwork(
                          trackId: track.id,
                          isPlaying: isCurrentPlaying,
                        ),
                      ],
                    ),
                    title: Text(
                      track.title,
                      style: TextStyle(
                        color: isCurrentPlaying
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isCurrentPlaying ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text(track.artist ?? 'Desconocido'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrentPlaying)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.equalizer_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            track.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: track.isFavorite ? Colors.red : null,
                          ),
                          onPressed: () {
                            ref
                                .read(libraryViewModelProvider.notifier)
                                .toggleFavorite(track.id);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .loadPlaylist(favoriteTracks, index);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlayerScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _PlayingArtwork extends StatefulWidget {
  final String trackId;
  final bool isPlaying;

  const _PlayingArtwork({required this.trackId, required this.isPlaying});

  @override
  State<_PlayingArtwork> createState() => _PlayingArtworkState();
}

class _PlayingArtworkState extends State<_PlayingArtwork>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return TrackArtwork(trackId: widget.trackId, size: 48, borderRadius: 4);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.3 + (_controller.value * 0.4),
                ),
                blurRadius: 8 + (_controller.value * 8),
                spreadRadius: 1 + (_controller.value * 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: TrackArtwork(trackId: widget.trackId, size: 48, borderRadius: 4),
    );
  }
}
