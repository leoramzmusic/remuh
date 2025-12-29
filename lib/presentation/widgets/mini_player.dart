import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../screens/test_player_screen.dart'; // Changed to test screen

/// Mini player that floats above content
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TestPlayerScreen(),
          ), // Using test screen
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentTrack.artist ?? 'Desconocido',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
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
              ),
              onPressed: () {
                ref.read(audioPlayerProvider.notifier).togglePlayPause();
              },
            ),
            // Next button
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 28),
              onPressed: () {
                ref.read(audioPlayerProvider.notifier).skipToNext();
              },
            ),
          ],
        ),
      ),
    );
  }
}
