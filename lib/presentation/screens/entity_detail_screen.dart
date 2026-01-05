import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/track_contextual_menu.dart';
import '../widgets/shuffle_indicator.dart';
import 'player_screen.dart';

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
    final isShuffleActive = ref.watch(
      audioPlayerProvider.select((s) => s.shuffleMode),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: tracks.isEmpty
          ? const Center(child: Text('No hay canciones'))
          : ListView.builder(
              itemCount: tracks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Material(
                    color: isShuffleActive
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        final notifier = ref.read(audioPlayerProvider.notifier);
                        int shuffleStartIdx = 0;
                        if (tracks.length > 1) {
                          shuffleStartIdx = math.Random().nextInt(
                            tracks.length,
                          );
                        }
                        final startTrack = tracks[shuffleStartIdx];

                        notifier.loadPlaylist(
                          tracks,
                          shuffleStartIdx,
                          startShuffled: true,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reproducción Aleatoria Activa desde ${startTrack.title}',
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlayerScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            ShuffleIndicator(
                              isActive: isShuffleActive,
                              size: 28,
                              activeColor: Colors.orangeAccent,
                              inactiveColor: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REPRODUCCIÓN ALEATORIA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isShuffleActive
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                                Text(
                                  '${tracks.length} canciones',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
                        .playTrackManually(tracks, index - 1);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerScreen(),
                      ),
                    );
                  },
                  onLongPress: () {
                    TrackContextualMenu.show(context, ref, track, tracks);
                  },
                );
              },
            ),
    );
  }
}
