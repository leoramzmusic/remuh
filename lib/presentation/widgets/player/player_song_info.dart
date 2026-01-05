import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/track.dart';
import '../../providers/audio_player_provider.dart';
import '../marquee_text.dart';

/// Información de la canción actual (título y artista) con efecto marquee
class PlayerSongInfo extends ConsumerWidget {
  final Track? track;

  const PlayerSongInfo({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (track == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con marquee y corazón
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (track!.isFavorite) ...[
                      const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: MarqueeText(
                        text: track!.title,
                        style:
                            (Theme.of(context).textTheme.headlineSmall ??
                                    const TextStyle())
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Artista con marquee
                MarqueeText(
                  text: track!.artist ?? 'Artista desconocido',
                  style:
                      (Theme.of(context).textTheme.bodyLarge ??
                              const TextStyle())
                          .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(audioPlayerProvider.notifier).toggleFavorite(track!);
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                track!.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(track!.isFavorite),
                color: track!.isFavorite ? Colors.redAccent : Colors.grey,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
