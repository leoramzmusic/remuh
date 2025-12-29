import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';

class EntityDetailScreen extends ConsumerWidget {
  final String title;
  final List<Track> tracks;

  const EntityDetailScreen({
    super.key,
    required this.title,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: tracks.isEmpty
          ? const Center(child: Text('No hay canciones'))
          : ListView.builder(
              itemCount: tracks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isShuffleActive = ref.watch(
                            audioPlayerProvider.select((s) => s.shuffleMode),
                          );
                          return Icon(
                            Icons.shuffle,
                            size: 28,
                            color: isShuffleActive
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.white,
                          );
                        },
                      ),
                    ),
                    title: const Text(
                      'Modo Aleatorio',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${tracks.length} canciones'),
                    onTap: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .loadPlaylist(tracks, 0, startShuffled: true);
                    },
                  );
                }

                final track = tracks[index - 1];
                return ListTile(
                  leading: Hero(
                    tag: 'artwork_${track.id}',
                    child: TrackArtwork(
                      trackId: track.id,
                      size: 50,
                      borderRadius: 4,
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist ?? 'Desconocido',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .loadPlaylist(tracks, index - 1);
                  },
                );
              },
            ),
    );
  }
}
