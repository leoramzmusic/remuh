import 'package:flutter/material.dart';
import '../../../domain/entities/track.dart';
import '../marquee_text.dart';

/// Información de la canción actual (título y artista) con efecto marquee
class PlayerSongInfo extends StatelessWidget {
  final Track? track;

  const PlayerSongInfo({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título con marquee
          MarqueeText(
            text: track!.title,
            style:
                (Theme.of(context).textTheme.headlineSmall ?? const TextStyle())
                    .copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),

          // Artista con marquee
          MarqueeText(
            text: track!.artist ?? 'Artista desconocido',
            style: (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
                .copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
