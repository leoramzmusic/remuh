import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
    final currentIndex = ref.watch(
      audioPlayerProvider.select((s) => s.currentIndex),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('A continuación'), centerTitle: true),
      body: ReorderableListView.builder(
        itemCount: queue.length,
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.smallPadding,
        ),
        onReorder: (oldIndex, newIndex) {
          ref
              .read(audioPlayerProvider.notifier)
              .reorderQueue(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final track = queue[index];
          final isCurrent = index == currentIndex;

          return ListTile(
            key: ValueKey(track.id + index.toString()),
            leading: Hero(
              tag: 'artwork_${track.id}',
              child: TrackArtwork(
                trackId: track.id,
                size: 40,
                borderRadius: 4,
                placeholderIcon: isCurrent
                    ? Icons.play_arrow_rounded
                    : Icons.music_note_rounded,
              ),
            ),
            title: Text(
              track.title,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? Theme.of(context).colorScheme.primary : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist ?? 'Artista desconocido',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCurrent)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .removeFromQueue(index);
                    },
                  ),
                const Icon(Icons.drag_handle_rounded),
              ],
            ),
            onTap: () {
              ref.read(audioPlayerProvider.notifier).loadTrackInQueue(index);
            },
          );
        },
      ),
    );
  }
}
