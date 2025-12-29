import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../utils/logger.dart';

/// Service for extracting dominant colors from album artwork
class ColorExtractionService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Map<String, Color> _colorCache = {};

  /// Extract dominant color from track artwork
  Future<Color> getDominantColor(String trackId) async {
    // Check cache first
    if (_colorCache.containsKey(trackId)) {
      return _colorCache[trackId]!;
    }

    try {
      final id = int.parse(trackId);

      // Get artwork data
      final artworkData = await _audioQuery.queryArtwork(
        id,
        ArtworkType.AUDIO,
        size: 200, // Smaller size for color extraction
        quality: 50,
      );

      if (artworkData != null) {
        // Create image from bytes
        final codec = await ui.instantiateImageCodec(artworkData);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        // Generate palette
        final palette = await PaletteGenerator.fromImage(
          image,
          maximumColorCount: 16,
        );

        // Get best color (prefer vibrant, then dominant, then fallback)
        final color =
            palette.vibrantColor?.color ??
            palette.dominantColor?.color ??
            palette.mutedColor?.color ??
            Colors.deepPurple;

        _colorCache[trackId] = color;
        Logger.info('Extracted color for track $trackId: $color');
        return color;
      }
    } catch (e) {
      Logger.warning('Failed to extract color for track $trackId: $e');
    }

    // Fallback color
    final fallback = Colors.deepPurple;
    _colorCache[trackId] = fallback;
    return fallback;
  }

  /// Get a gradient-friendly lighter version of the color
  Color getLighterShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }

  /// Get a darker version for better contrast
  Color getDarkerShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor();
  }

  /// Clear color cache
  void clearCache() {
    _colorCache.clear();
    Logger.info('Cleared color extraction cache');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {'cachedColors': _colorCache.length};
  }
}
