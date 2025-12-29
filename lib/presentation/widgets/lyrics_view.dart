import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lyrics_provider.dart';
import '../providers/audio_player_provider.dart';

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  static const double _rowHeight = 60.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0) {
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final centerOffset =
        (screenHeight / 2) - (_rowHeight / 2) - 100; // Ajuste para el centro

    final targetOffset = (index * _rowHeight) - centerOffset;

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutSine,
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

    if (lyricsState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Buscando letras online...',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (lyricsState.lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'No hay letras disponibles local ni online para esta canción',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (lyricsState.isOnline)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_download_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Letra obtenida de Genius (Estática)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: lyricsState.lines.length,
            padding: const EdgeInsets.symmetric(vertical: 200),
            itemBuilder: (context, index) {
              final line = lyricsState.lines[index];
              final isActive = index == activeIndex;

              return GestureDetector(
                onTap: lyricsState.isOnline
                    ? null
                    : () {
                        // Ir a este tiempo en la canción
                        ref
                            .read(audioPlayerProvider.notifier)
                            .seekTo(line.startTime);
                      },
                child: Container(
                  height: _rowHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isActive ? 24 : 18,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
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
