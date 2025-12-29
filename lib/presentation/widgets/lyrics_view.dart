import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late ScrollController _internalScrollController;
  static const double _rowHeight = 64.0;

  ScrollController get _activeScrollController =>
      widget.scrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    _internalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_activeScrollController.hasClients || index < 0) {
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    // Aim for upper-middle part of the screen for active line
    final centerOffset = (screenHeight * 0.35) - (_rowHeight / 2);

    final targetOffset = (index * _rowHeight) - centerOffset;

    _activeScrollController.animateTo(
      targetOffset.clamp(0, _activeScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
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

    return ListView.builder(
      controller: _activeScrollController,
      itemCount: lyricsState.lines.length,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.4,
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
            height: _rowHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              line.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isActive ? 26 : 20,
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
