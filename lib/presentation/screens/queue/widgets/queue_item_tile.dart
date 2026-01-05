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

    Widget content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: TrackArtwork(
          trackId: track.id,
          size: 48,
          borderRadius: 8,
          placeholderIcon: isCurrent ? null : icons.lyrics,
        ),
      ),
      title: Row(
        children: [
          if (isCurrent) ...[
            Icon(Icons.play_arrow, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        track.artist ?? 'Artista desconocido',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? colorScheme.primary.withValues(alpha: 0.7) : null,
        ),
      ),
      trailing: isFiltered
          ? null
          : ReorderableDragStartListener(
              index: displayIndex,
              child: Icon(
                Icons.drag_handle,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
      onTap: () {
        if (isFiltered) {
          // In filtered mode, find the track in the main queue and play it
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

    return SizedBox(
      height: 72.0,
      child: RepaintBoundary(
        key: key,
        child: isCurrent
            ? Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(child: content),
              )
            : Center(child: content),
      ),
    );
  }
}
