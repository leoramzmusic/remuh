import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/customization_provider.dart';
import '../../../core/theme/icon_sets.dart';
import 'widgets/queue_header.dart';
import 'widgets/queue_search_bar.dart';
import 'widgets/queue_list.dart';

class QueueScreen extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const QueueScreen({required this.scrollController, super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _scrollToActive() {
    final state = ref.read(audioPlayerProvider);
    final currentTrack = state.currentTrack;
    if (currentTrack == null) return;

    final query = _searchController.text.toLowerCase();
    final isSearching = _isSearching && query.isNotEmpty;

    int targetIndex = -1;
    if (isSearching) {
      final effectiveQueue = state.effectiveQueue;
      final filteredQueue = effectiveQueue.where((track) {
        return track.title.toLowerCase().contains(query) ||
            (track.artist?.toLowerCase().contains(query) ?? false);
      }).toList();
      targetIndex = filteredQueue.indexWhere((t) => t.id == currentTrack.id);
    } else {
      targetIndex = state.effectiveIndex;
    }

    if (targetIndex != -1 && widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        targetIndex * 72.0, // Fixed height defined in QueueItemTile
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);

    final effectiveQueue = ref.watch(
      audioPlayerProvider.select((s) => s.effectiveQueue),
    );
    final effectiveIndex = ref.watch(
      audioPlayerProvider.select((s) => s.effectiveIndex),
    );
    final shuffleMode = ref.watch(
      audioPlayerProvider.select((s) => s.shuffleMode),
    );
    final playlistName = ref.watch(
      audioPlayerProvider.select((s) => s.playlistName),
    );

    final query = _searchController.text.toLowerCase();
    final filteredQueue = _isSearching && query.isNotEmpty
        ? effectiveQueue.where((track) {
            return track.title.toLowerCase().contains(query) ||
                (track.artist?.toLowerCase().contains(query) ?? false);
          }).toList()
        : effectiveQueue;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            QueueHeader(
              onScrollToActive: _scrollToActive,
              onToggleSearch: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                  }
                  _isSearching = !_isSearching;
                });
              },
              isSearching: _isSearching,
            ),
            if (_isSearching)
              QueueSearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  _getSubTitle(filteredQueue.length, playlistName, shuffleMode),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: QueueList(
                scrollController: widget.scrollController,
                filteredQueue: filteredQueue,
                effectiveQueue: effectiveQueue,
                effectiveIndex: effectiveIndex,
                isSearching: _isSearching && _searchController.text.isNotEmpty,
                shuffleMode: shuffleMode,
                icons: icons,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubTitle(
    int filteredCount,
    String? playlistName,
    bool shuffleMode,
  ) {
    if (_isSearching && _searchController.text.isNotEmpty) {
      return '$filteredCount resultados encontrados';
    } else if (playlistName != null) {
      return 'Reproduciendo $playlistName';
    } else if (shuffleMode) {
      return 'Modo Aleatorio Activo';
    } else {
      return 'Reproduciendo en orden';
    }
  }
}
