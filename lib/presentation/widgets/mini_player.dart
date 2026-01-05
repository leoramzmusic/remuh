import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../screens/player_screen.dart';

import '../../core/services/color_extraction_service.dart';

/// Mini player that floats above content
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  final ColorExtractionService _colorService = ColorExtractionService();
  List<Color>? _backgroundColors;

  @override
  void initState() {
    super.initState();
    // Watch for track changes to update color
    // Initial update tied to build method logic or listener
  }

  Future<void> _updateBackgroundColor(String? trackId) async {
    if (trackId == null) return;
    final colors = await _colorService.getBackgroundColors(trackId);
    if (mounted) {
      setState(() {
        _backgroundColors = colors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));

    // Listen for track changes to update background
    ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (_, next) {
      if (next != null) {
        _updateBackgroundColor(next.id);
      }
    });

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    // Ensure we have colors for the current track if not yet loaded (e.g. first load)
    if (_backgroundColors == null) {
      _updateBackgroundColor(currentTrack.id);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          ref.read(audioPlayerProvider.notifier).skipToNext();
        } else if (details.primaryVelocity! > 0) {
          ref.read(audioPlayerProvider.notifier).skipToPrevious();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Use gradient if available, else fallback to theme surface
          gradient: _backgroundColors != null
              ? LinearGradient(
                  colors: _backgroundColors!,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: _backgroundColors == null
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Album art
            TrackArtwork(trackId: currentTrack.id, size: 48, borderRadius: 6),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTrack.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      // Forcing white text when gradient is active for better contrast
                      color: _backgroundColors != null ? Colors.white : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentTrack.artist ?? 'Desconocido',
                    style: TextStyle(
                      fontSize: 12,
                      color: _backgroundColors != null
                          ? Colors.white70
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Play/Pause button
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 32,
                color: _backgroundColors != null ? Colors.white : null,
              ),
              onPressed: () {
                ref.read(audioPlayerProvider.notifier).togglePlayPause();
              },
            ),
            // Next button
            GestureDetector(
              onTap: () {
                ref.read(audioPlayerProvider.notifier).skipToNext();
              },
              onLongPressStart: (_) {
                ref.read(audioPlayerProvider.notifier).startFastForward();
              },
              onLongPressEnd: (_) {
                ref.read(audioPlayerProvider.notifier).stopFastForward();
              },
              child: IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  size: 28,
                  color: _backgroundColors != null ? Colors.white : null,
                ),
                onPressed: null, // GestureDetector handles it
              ),
            ),
          ],
        ),
      ),
    );
  }
}
