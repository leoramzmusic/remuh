import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/track.dart';
import '../../../widgets/track_artwork.dart';
import '../../../../core/theme/icon_sets.dart';
import '../../../providers/audio_player_provider.dart';

class QueueItemTile extends ConsumerWidget {
  final Track track;
  final int displayIndex;
  final int currentIndex;
  final AppIconSet icons;
  final List<Track> contextQueue;
  final bool isFiltered;
  final bool shuffleMode;

  const QueueItemTile({
    required this.track,
    required this.displayIndex,
    required this.currentIndex,
    required this.icons,
    required this.contextQueue,
    required this.isFiltered,
    required this.shuffleMode,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCurrent =
        !isFiltered &&
        track.id ==
            (currentIndex >= 0 && currentIndex < contextQueue.length
                ? contextQueue[currentIndex].id
                : null);
    final colorScheme = Theme.of(context).colorScheme;

    if (isCurrent) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: InkWell(
          onTap: () => ref
              .read(audioPlayerProvider.notifier)
              .skipToEffectiveIndex(displayIndex),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Artwork
                SizedBox(
                  width: 48,
                  height: 48,
                  child: TrackArtwork(
                    trackId: track.id,
                    size: 48,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                // Text Info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        track.artist ?? 'Artista desconocido',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.primary.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Drag handle (trailing)
                if (!isFiltered)
                  ReorderableDragStartListener(
                    index: displayIndex,
                    child: Icon(
                      Icons.drag_handle,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: TrackArtwork(
          trackId: track.id,
          size: 48,
          borderRadius: 8,
          placeholderIcon: icons.lyrics,
        ),
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        track.artist ?? 'Artista desconocido',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isFiltered
          ? null
          : ReorderableDragStartListener(
              index: displayIndex,
              child: Icon(
                Icons.drag_handle,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
      onTap: () {
        if (isFiltered) {
          final mainIndex = contextQueue.indexWhere((t) => t.id == track.id);
          if (mainIndex != -1) {
            ref.read(audioPlayerProvider.notifier).loadTrackInQueue(mainIndex);
          }
        } else {
          ref
              .read(audioPlayerProvider.notifier)
              .skipToEffectiveIndex(displayIndex);
        }
      },
    );
  }
}
