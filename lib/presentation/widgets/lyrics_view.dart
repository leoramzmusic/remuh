import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/lyrics_provider.dart';
import '../providers/audio_player_provider.dart';

class LyricsView extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final double opacity;

  const LyricsView({super.key, this.scrollController, this.opacity = 0.4});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  static const double _rowHeight = 64.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_itemScrollController.isAttached || index < 0) {
      return;
    }

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      alignment: 0.5, // Centra el elemento en el viewport
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final activeIndex = lyricsState.activeLineIndex;

    // Escuchar cambios en el índice activo para hacer scroll
    ref.listen(lyricsProvider.select((s) => s.activeLineIndex), (_, next) {
      if (next != -1) {
        _scrollToIndex(next);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: widget.opacity),
      ),
      child: _buildContent(lyricsState, activeIndex),
    );
  }

  Widget _buildContent(LyricsState lyricsState, int activeIndex) {
    if (lyricsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lyricsState.lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            lyricsState.error ?? 'No hay letras disponibles',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemCount: lyricsState.lines.length,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.25,
      ),
      itemBuilder: (context, index) {
        final line = lyricsState.lines[index];
        final isActive = index == activeIndex;

        return GestureDetector(
          onTap: lyricsState.isOnline
              ? null
              : () {
                  ref.read(audioPlayerProvider.notifier).seekTo(line.startTime);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: _rowHeight),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: AutoSizeText(
              line.text,
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize: 12,
              style: TextStyle(
                fontSize: isActive
                    ? 28
                    : 22, // Ligeramente más grande para resaltar
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white.withValues(alpha: 0.5),
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 4.0,
                    color: Colors.black.withValues(alpha: isActive ? 0.8 : 0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
