import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/track.dart';
import '../../../../core/theme/icon_sets.dart';
import '../../../providers/audio_player_provider.dart';
import 'queue_item_tile.dart';

class QueueList extends ConsumerWidget {
  final ScrollController scrollController;
  final List<Track> filteredQueue;
  final List<Track> effectiveQueue;
  final int effectiveIndex;
  final bool isSearching;
  final bool shuffleMode;
  final AppIconSet icons;

  const QueueList({
    required this.scrollController,
    required this.filteredQueue,
    required this.effectiveQueue,
    required this.effectiveIndex,
    required this.isSearching,
    required this.shuffleMode,
    required this.icons,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isSearching && filteredQueue.isNotEmpty) {
      return ListView.builder(
        controller: scrollController,
        itemCount: filteredQueue.length,
        padding: const EdgeInsets.only(bottom: 32),
        itemBuilder: (context, index) {
          final track = filteredQueue[index];
          return QueueItemTile(
            track: track,
            displayIndex: index,
            currentIndex: effectiveIndex,
            icons: icons,
            contextQueue: effectiveQueue,
            isFiltered: true,
            shuffleMode: shuffleMode,
            key: ValueKey('search_${track.id}_$index'),
          );
        },
      );
    }

    return ReorderableListView.builder(
      scrollController: scrollController,
      shrinkWrap: true,
      itemCount: effectiveQueue.length,
      padding: const EdgeInsets.only(bottom: 32),
      onReorder: (oldIndex, newIndex) {
        ref.read(audioPlayerProvider.notifier).reorderQueue(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final track = effectiveQueue[index];
        return QueueItemTile(
          track: track,
          displayIndex: index,
          currentIndex: effectiveIndex,
          icons: icons,
          contextQueue: effectiveQueue,
          isFiltered: false,
          shuffleMode: shuffleMode,
          key: ValueKey('queue_${track.id}_${identityHashCode(track)}'),
        );
      },
    );
  }
}
