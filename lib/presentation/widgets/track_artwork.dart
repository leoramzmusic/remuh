import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
import '../../core/utils/logger.dart';

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

    // First, try to find a local cover file if we have a path (not implemented yet in Track entity, but planned)
    // For now, we'll use OnAudioQuery as the primary source but optimized.

    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List?>(
        future: _getArtworkBytes(trackId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.memory(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
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
      ),
    );
  }

  Future<Uint8List?> _getArtworkBytes(String trackId) async {
    return cacheArtwork(trackId);
  }

  /// Pre-caches artwork bytes for a given track ID
  static Future<Uint8List?> cacheArtwork(String trackId) async {
    try {
      final bytes = await OnAudioQuery().queryArtwork(
        int.parse(trackId),
        ArtworkType.AUDIO,
        size: 1000,
        quality: 100,
        format: ArtworkFormat.JPEG,
      );
      return bytes;
    } catch (e) {
      Logger.error('Error fetching/caching artwork for $trackId: $e');
      return null;
    }
  }
}
