import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../utils/logger.dart';

/// Service for precaching album artwork to improve performance
/// Implements LRU-style caching with memory management
class ArtworkCacheService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Map<String, bool> _precachedIds = {};
  static const int _maxCacheSize = 20; // Maximum number of precached artworks

  /// Precache artwork for a specific track
  Future<void> precacheArtwork(
    BuildContext context,
    String trackId, {
    int size = 1000,
  }) async {
    if (_precachedIds.containsKey(trackId)) {
      return; // Already precached
    }

    try {
      final id = int.parse(trackId);

      // Get artwork as ImageProvider
      final artworkData = await _audioQuery.queryArtwork(
        id,
        ArtworkType.AUDIO,
        size: size,
        quality: 100,
      );

      if (artworkData != null && context.mounted) {
        final imageProvider = MemoryImage(artworkData);
        await precacheImage(imageProvider, context);

        _precachedIds[trackId] = true;
        _evictOldCacheIfNeeded();

        Logger.info('Precached artwork for track: $trackId');
      }
    } catch (e) {
      Logger.warning('Failed to precache artwork for track $trackId: $e');
    }
  }

  /// Precache artwork for multiple tracks (e.g., upcoming queue)
  Future<void> precacheMultiple(
    BuildContext context,
    List<String> trackIds, {
    int size = 500, // Use medium size for queue items
  }) async {
    for (final trackId in trackIds) {
      if (!context.mounted) break;
      await precacheArtwork(context, trackId, size: size);
    }
  }

  /// Precache current track at full HD and next few tracks at medium quality
  Future<void> precacheQueueArtwork(
    BuildContext context,
    List<String> queueTrackIds,
    int currentIndex,
  ) async {
    if (queueTrackIds.isEmpty || currentIndex < 0) return;

    // Precache current track at full HD
    if (currentIndex < queueTrackIds.length) {
      await precacheArtwork(context, queueTrackIds[currentIndex], size: 1000);
    }

    // Precache next 2-3 tracks at medium quality
    final nextTracks = <String>[];
    for (int i = 1; i <= 3; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < queueTrackIds.length) {
        nextTracks.add(queueTrackIds[nextIndex]);
      }
    }

    if (nextTracks.isNotEmpty && context.mounted) {
      await precacheMultiple(context, nextTracks, size: 500);
    }

    // Precache previous track at medium quality
    if (currentIndex > 0 && context.mounted) {
      await precacheArtwork(
        context,
        queueTrackIds[currentIndex - 1],
        size: 500,
      );
    }
  }

  /// Evict old cache entries if we exceed max cache size
  void _evictOldCacheIfNeeded() {
    if (_precachedIds.length > _maxCacheSize) {
      // Remove oldest entries (first entries in the map)
      final keysToRemove = _precachedIds.keys.take(
        _precachedIds.length - _maxCacheSize,
      );
      for (final key in keysToRemove.toList()) {
        _precachedIds.remove(key);
      }
      Logger.info('Evicted ${keysToRemove.length} old cache entries');
    }
  }

  /// Clear all precached artwork
  void clearCache() {
    _precachedIds.clear();
    Logger.info('Cleared artwork cache');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {'cachedCount': _precachedIds.length, 'maxCacheSize': _maxCacheSize};
  }
}
