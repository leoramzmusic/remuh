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
  final String? heroTag;
  final FilterQuality filterQuality;

  // Simple in-memory cache to speed up loading and prevent flickering on frequent reloads
  // Limited to 150 items to avoid memory exhaustion (OOM)
  static final Map<String, Uint8List> _artworkCache = {};
  static final Map<String, Future<Uint8List?>> _pendingQueries = {};
  static final _audioQuery = OnAudioQuery();
  static const int _maxCacheSize = 150;
  static final List<String> _cacheKeys = [];

  const TrackArtwork({
    super.key,
    required this.trackId,
    this.size = 50,
    this.borderRadius = 8,
    this.placeholderIcon,
    this.heroTag,
    this.filterQuality = FilterQuality.medium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);
    final actualPlaceholder = placeholderIcon ?? icons.lyrics;

    Widget artwork = SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List?>(
        initialData: _artworkCache[trackId],
        future: _artworkCache.containsKey(trackId)
            ? null
            : _getArtworkBytes(trackId),
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
                  filterQuality: filterQuality,
                  gaplessPlayback: true,
                  cacheWidth: size.isFinite ? (size * 2).toInt() : 600,
                  cacheHeight: size.isFinite ? (size * 2).toInt() : 600,
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
            child: RepaintBoundary(child: content),
          );
        },
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: artwork);
    }

    return artwork;
  }

  Future<Uint8List?> _getArtworkBytes(String trackId) async {
    // Check cache first
    if (_artworkCache.containsKey(trackId)) {
      return _artworkCache[trackId];
    }

    // Check if there is an active query for this track to avoid duplicates
    if (_pendingQueries.containsKey(trackId)) {
      return _pendingQueries[trackId];
    }

    return cacheArtwork(trackId);
  }

  /// Pre-caches artwork bytes for a given track ID
  static Future<Uint8List?> cacheArtwork(String trackId) async {
    // Check if already cached
    if (_artworkCache.containsKey(trackId)) {
      return _artworkCache[trackId];
    }

    // Check if there's already a query in progress
    if (_pendingQueries.containsKey(trackId)) {
      return _pendingQueries[trackId];
    }

    final queryFuture = _performQuery(trackId);
    _pendingQueries[trackId] = queryFuture;

    try {
      final bytes = await queryFuture;
      if (bytes != null) {
        // Atomic cache update
        if (_artworkCache.length >= _maxCacheSize) {
          final oldestKey = _cacheKeys.removeAt(0);
          _artworkCache.remove(oldestKey);
        }
        _artworkCache[trackId] = bytes;
        _cacheKeys.add(trackId);
      }
      return bytes;
    } finally {
      _pendingQueries.remove(trackId);
    }
  }

  static Future<Uint8List?> _performQuery(String trackId) async {
    try {
      int? id = int.tryParse(trackId);
      if (id == null) return null;

      return await _audioQuery.queryArtwork(
        id,
        ArtworkType.AUDIO,
        size: 800,
        quality: 100,
        format: ArtworkFormat.JPEG,
      );
    } catch (e) {
      Logger.error('Error querying artwork for $trackId: $e');
      return null;
    }
  }
}
