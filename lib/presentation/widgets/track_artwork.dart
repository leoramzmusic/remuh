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

  // Simple in-memory cache to speed up loading and prevent flickering on frequent reloads
  static final Map<String, Uint8List> _artworkCache = {};

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

    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List?>(
        future: _getArtworkBytes(trackId),
        builder: (context, snapshot) {
          Widget content;

          if (snapshot.hasData && snapshot.data != null) {
            content = AspectRatio(
              key: ValueKey('art_$trackId'),
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.memory(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  filterQuality:
                      FilterQuality.medium, // Optimized for performance
                  gaplessPlayback: true,
                ),
              ),
            );
          } else {
            content = Container(
              key: const ValueKey('placeholder'),
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

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: content,
          );
        },
      ),
    );
  }

  Future<Uint8List?> _getArtworkBytes(String trackId) async {
    // Check cache first
    if (_artworkCache.containsKey(trackId)) {
      return _artworkCache[trackId];
    }
    return cacheArtwork(trackId);
  }

  /// Pre-caches artwork bytes for a given track ID
  static Future<Uint8List?> cacheArtwork(String trackId) async {
    // Check cache first
    if (_artworkCache.containsKey(trackId)) {
      return _artworkCache[trackId];
    }

    try {
      // Validate ID is numeric
      int? id;
      try {
        id = int.parse(trackId);
      } catch (_) {
        return null;
      }

      final bytes = await OnAudioQuery().queryArtwork(
        id,
        ArtworkType.AUDIO,
        size: 500, // Reduced from 1000 for performance
        quality: 100,
        format: ArtworkFormat.JPEG,
      );

      if (bytes != null) {
        _artworkCache[trackId] = bytes;
      }

      return bytes;
    } catch (e) {
      Logger.error('Error fetching/caching artwork for $trackId: $e');
      return null;
    }
  }
}
