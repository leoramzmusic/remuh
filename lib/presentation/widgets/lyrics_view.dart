import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
  static const double _rowHeight = 64.0;
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (index < 0 || index >= _itemKeys.length) return;

    final context = _itemKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.5, // Center the item in the viewport
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final activeIndex = lyricsState.activeLineIndex;

    // Cada vez que se reconstruye (ej: al abrir el panel o cambiar de línea),
    // nos aseguramos de centrar la línea activa.
    if (activeIndex != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(activeIndex);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: widget.opacity),
        borderRadius: BorderRadius.circular(24),
      ),
      child: _buildContent(lyricsState, activeIndex),
    );
  }

  Widget _buildContent(LyricsState lyricsState, int activeIndex) {
    if (lyricsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool isEmpty = lyricsState.lines.isEmpty;

    // Sync keys with lines if not empty
    if (!isEmpty && _itemKeys.length != lyricsState.lines.length) {
      _itemKeys.clear();
      _itemKeys.addAll(
        List.generate(lyricsState.lines.length, (_) => GlobalKey()),
      );
    }

    return Column(
      children: [
        // Fixed Drag Handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400]?.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        // Scrollable Content (Unified as ListView)
        Expanded(
          child: ListView.builder(
            key: GlobalKey(debugLabel: 'lyrics_unified_list_view'),
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: isEmpty ? 1 : lyricsState.lines.length,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.1,
              bottom: MediaQuery.of(context).size.height * 0.2,
            ),
            itemBuilder: (context, index) {
              if (isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 100,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    lyricsState.error ?? 'No hay letras disponibles',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              final line = lyricsState.lines[index];
              final isActive = index == activeIndex;

              return GestureDetector(
                onTap: lyricsState.isOnline
                    ? null
                    : () {
                        ref
                            .read(audioPlayerProvider.notifier)
                            .seekTo(line.startTime);
                      },
                child: AnimatedContainer(
                  key: _itemKeys[index],
                  duration: const Duration(milliseconds: 300),
                  constraints: const BoxConstraints(minHeight: _rowHeight),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: AutoSizeText(
                    line.text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 12,
                    style: TextStyle(
                      fontSize: isActive ? 32 : 22,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withValues(alpha: 0.5),
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4.0,
                          color: Colors.black.withValues(
                            alpha: isActive ? 0.8 : 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
