import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/utils/logger.dart';

class ArtistArtwork extends StatefulWidget {
  final String artistName;
  final double size;

  const ArtistArtwork({super.key, required this.artistName, this.size = 50});

  @override
  State<ArtistArtwork> createState() => _ArtistArtworkState();
}

class _ArtistArtworkState extends State<ArtistArtwork> {
  static final Map<String, String?> _imageUrlCache = {};
  static final Map<String, Future<String?>> _pendingQueries = {};
  static final Set<String> _failedNames = {};

  // Global Queue/Throttling state
  static bool _isProcessingQueue = false;
  static bool _isGloballyRateLimited = false;
  static DateTime? _rateLimitResetTime;
  static final List<ArtistFetchTask> _fetchQueue = [];

  String? _imageUrl;
  bool _isLoading = false;
  CancelableOperation? _currentOperation;

  @override
  void initState() {
    super.initState();
    _loadArtistImage();
  }

  @override
  void didUpdateWidget(ArtistArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artistName != widget.artistName) {
      _loadArtistImage();
    }
  }

  @override
  void dispose() {
    _currentOperation?.cancel();
    super.dispose();
  }

  Future<void> _loadArtistImage() async {
    final name = widget.artistName.trim();
    if (name.isEmpty || name == 'Desconocido') {
      setState(() => _imageUrl = null);
      return;
    }

    if (_imageUrlCache.containsKey(name)) {
      setState(() {
        _imageUrl = _imageUrlCache[name];
        _isLoading = false;
      });
      return;
    }

    if (_failedNames.contains(name)) {
      setState(() {
        _imageUrl = null;
        _isLoading = false;
      });
      return;
    }

    _currentOperation?.cancel();
    setState(() => _isLoading = true);

    // Debounce: Wait 400ms before queueing
    _currentOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(milliseconds: 400)),
    );

    try {
      await _currentOperation!.value;
      if (!mounted) return;

      // Add to global queue
      final task = ArtistFetchTask(
        name: name,
        onComplete: (url) {
          if (mounted) {
            setState(() {
              _imageUrl = url;
              _isLoading = false;
            });
            if (url == null) {
              // Only mark as failed if it's NOT a temporary rate limit
              if (!_isGloballyRateLimited) {
                _failedNames.add(name);
              }
            }
          }
        },
      );

      _fetchQueue.add(task);
      _processQueue();
    } catch (e) {
      if (e is! FutureCancelledException) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  static Future<void> _processQueue() async {
    if (_isProcessingQueue || _fetchQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_fetchQueue.isNotEmpty) {
      // Check for rate limit
      if (_isGloballyRateLimited) {
        if (_rateLimitResetTime != null &&
            DateTime.now().isAfter(_rateLimitResetTime!)) {
          _isGloballyRateLimited = false;
          Logger.info('ArtistArtwork: Rate limit delay finished. Resuming...');
        } else {
          // Keep tasks in queue and stop processing for now
          break;
        }
      }

      final task = _fetchQueue.removeAt(0);

      // Double check cache before performing network work
      if (_imageUrlCache.containsKey(task.name)) {
        task.onComplete(_imageUrlCache[task.name]);
        continue;
      }

      String? result;
      if (_pendingQueries.containsKey(task.name)) {
        result = await _pendingQueries[task.name];
      } else {
        final queryFuture = _performDeezerRequest(task.name);
        _pendingQueries[task.name] = queryFuture;
        result = await queryFuture;
        _pendingQueries.remove(task.name);
        _imageUrlCache[task.name] = result;
      }

      task.onComplete(result);

      // Throttle delay between requests (Deezer allows up to 10 req/s safely)
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isProcessingQueue = false;
  }

  static Future<String?> _performDeezerRequest(String name) async {
    try {
      Logger.info('ArtistArtwork: Fetching from Deezer for $name');
      final response = await http
          .get(
            Uri.parse(
              'https://api.deezer.com/search/artist?q=${Uri.encodeComponent(name)}&limit=1',
            ),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List;
        if (results.isNotEmpty) {
          // Use picture_big or picture_xl for high quality
          return results[0]['picture_big'] as String?;
        }
        return null; // No results
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        _isGloballyRateLimited = true;
        _rateLimitResetTime = DateTime.now().add(const Duration(seconds: 3));
        Logger.warning(
          'ArtistArtwork: Rate limited by Deezer API. Pausing for 3s.',
        );
        return null;
      }
    } catch (e) {
      Logger.error('ArtistArtwork Deezer API Error for $name', e);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrl != null) {
      return ClipOval(
        child: Image.network(
          _imageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(isLoading: true);
          },
        ),
      );
    }

    if (_isLoading) {
      return _buildPlaceholder(isLoading: true);
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: widget.size * 0.5,
                height: widget.size * 0.5,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.person_rounded,
                size: widget.size * 0.6,
                color: Colors.white24,
              ),
      ),
    );
  }
}

// Simple exception for cancellation
class FutureCancelledException implements Exception {}

class CancelableOperation {
  final Future<void> value;
  final bool Function() isCancelled;

  CancelableOperation._(this.value, this.isCancelled);

  factory CancelableOperation.fromFuture(Future<void> future) {
    bool cancelled = false;
    return CancelableOperation._(
      future.then((v) {
        if (cancelled) throw FutureCancelledException();
        return v;
      }),
      () => cancelled,
    )..cancel = () => cancelled = true;
  }

  late void Function() cancel;
}

class ArtistFetchTask {
  final String name;
  final void Function(String? url) onComplete;

  ArtistFetchTask({required this.name, required this.onComplete});
}
