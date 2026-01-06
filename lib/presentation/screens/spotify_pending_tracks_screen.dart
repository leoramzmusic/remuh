import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spotify_provider.dart';
import '../../domain/entities/spotify_track.dart';
import 'spotify_sync_screen.dart';

class SpotifyPendingTracksScreen extends ConsumerWidget {
  const SpotifyPendingTracksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotifyState = ref.watch(spotifyProvider);
    final pendingTracks = spotifyState.savedTracks
        .where((t) => !t.isAcquired)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Por conseguir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpotifySyncScreen()),
            ),
          ),
        ],
      ),
      body: pendingTracks.isEmpty
          ? _buildEmptyState(context)
          : _buildTrackList(context, ref, pendingTracks),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Todo al día!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No tienes canciones pendientes de conseguir. Sincroniza una playlist de Spotify para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.sync_rounded),
            label: const Text('SINCRONIZAR SPOTIFY'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpotifySyncScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    WidgetRef ref,
    List<SpotifyTrack> tracks,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                'Tienes ${tracks.length} canciones pendientes',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: track.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          track.imageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.music_note_rounded),
                title: Text(track.title),
                subtitle: Text(
                  '${track.artist} • ${track.album ?? "Sin álbum"}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'acquired') {
                      await ref
                          .read(spotifyProvider.notifier)
                          .markAsAcquired(track.spotifyId, true);
                    } else if (value == 'delete') {
                      await ref
                          .read(spotifyProvider.notifier)
                          .deleteTrack(track.spotifyId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'acquired',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Ya la conseguí'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Eliminar de la lista',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
