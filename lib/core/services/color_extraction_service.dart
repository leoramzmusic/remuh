import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../utils/logger.dart';

/// Service for extracting dominant colors from album artwork
class ColorExtractionService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Map<String, List<Color>> _paletteCache = {};

  /// Extract dominant color from track artwork
  Future<Color> getDominantColor(String trackId) async {
    final colors = await getBackgroundColors(trackId);
    return colors.isNotEmpty ? colors.first : Colors.deepPurple;
  }

  /// Extract gradient colors from track artwork
  Future<List<Color>> getBackgroundColors(String trackId) async {
    // Check cache first
    if (_paletteCache.containsKey(trackId)) {
      return _paletteCache[trackId]!;
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
          maximumColorCount: 5,
        );

        // Get colors for gradient (Dominant -> Vibrant or Muted)
        Color color1 =
            palette.darkVibrantColor?.color ??
            palette.dominantColor?.color ??
            Colors.black;
        Color color2 =
            palette.mutedColor?.color ??
            palette.darkMutedColor?.color ??
            Colors.grey[900]!;

        // Ensure we have at least something dark for the background
        if (color1.computeLuminance() > 0.5) {
          color1 = getDarkerShade(color1);
        }
        if (color2.computeLuminance() > 0.5) {
          color2 = getDarkerShade(color2);
        }

        final colors = [color1, color2];
        _paletteCache[trackId] = colors;
        Logger.info('Extracted palette for track $trackId: $colors');
        return colors;
      }
    } catch (e) {
      Logger.warning('Failed to extract palette for track $trackId: $e');
    }

    // Fallback colors
    final fallback = [Colors.black, Colors.grey[900]!];
    _paletteCache[trackId] = fallback;
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
    _paletteCache.clear();
    Logger.info('Cleared color extraction cache');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {'cachedPalettes': _paletteCache.length};
  }
}
