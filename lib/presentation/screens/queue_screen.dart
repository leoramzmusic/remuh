import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
import '../widgets/track_artwork.dart';

class QueueScreen extends ConsumerWidget {
  final ScrollController? scrollController;

  const QueueScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);

    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
    final currentIndex = ref.watch(
      audioPlayerProvider.select((s) => s.currentIndex),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Fila de reproducción',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Consumer(
              builder: (context, ref, child) {
                final shuffleMode = ref.watch(
                  audioPlayerProvider.select((s) => s.shuffleMode),
                );
                final playlistName = ref.watch(
                  audioPlayerProvider.select((s) => s.playlistName),
                );

                String subtitle;
                if (playlistName != null) {
                  subtitle = 'Reproduciendo $playlistName';
                } else if (shuffleMode) {
                  subtitle = 'Reproduciendo Aleatoriamente';
                } else {
                  subtitle = 'Reproduciendo En orden';
                }

                return Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              scrollController:
                  scrollController, // Use the provided controller for drag behavior
              itemCount: queue.length,
              padding: const EdgeInsets.only(bottom: 32),
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(audioPlayerProvider.notifier)
                    .reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final track = queue[index];
                final isCurrent = index == currentIndex;

                return ListTile(
                  key: ValueKey(
                    '${track.id}_$index',
                  ), // Unique key including index to avoid conflicts
                  leading: Hero(
                    tag: 'artwork_queue_${track.id}_$index', // Unique tag
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: TrackArtwork(
                        trackId: track.id,
                        size: 48,
                        borderRadius: 8,
                        placeholderIcon: isCurrent ? icons.play : icons.lyrics,
                      ),
                    ),
                  ),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        onPressed: () {
                          ref
                              .read(audioPlayerProvider.notifier)
                              .removeFromQueue(index);
                        },
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.drag_handle_rounded,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                  onTap: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .loadTrackInQueue(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
