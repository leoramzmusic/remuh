import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';

class TrackArtwork extends ConsumerWidget {
  final String trackId;
  final double size;
  final double borderRadius;
  final IconData? placeholderIcon;

  const TrackArtwork({
    super.key,
    required this.trackId,
    this.size = 50,
    this.borderRadius = 8,
    this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);
    final actualPlaceholder = placeholderIcon ?? icons.lyrics;

    return FutureBuilder<Uint8List?>(
      // Use queryArtwork directly to avoid unnecessary compression/resizing overhead
      // unless specified.
      future: OnAudioQuery().queryArtwork(
        int.parse(trackId),
        ArtworkType.AUDIO,
        // If size > 200, we interpret it as a request for higher quality.
        // The user suggested not passing size for max quality, but we might want
        // to put a cap (e.g. 1000) to be safe, or just let it be if lazy loading works.
        // Let's pass 1000 if size is large, else 200.
        size: size > 200 ? 1000 : 200,
        quality: size > 200 ? 100 : 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true, // Avoids flickering and recreating objects
            ),
          );
        } else {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              actualPlaceholder,
              size: size * 0.5,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          );
        }
      },
    );
  }
}
