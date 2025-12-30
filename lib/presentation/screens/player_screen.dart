import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/entities/track.dart';

import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/progress_bar.dart';
import 'queue_screen.dart';
import '../widgets/lyrics_view.dart';
import '../providers/library_view_model.dart';
import 'entity_detail_screen.dart';
import '../../core/services/color_extraction_service.dart';

import '../widgets/track_actions_sheet.dart';
import '../widgets/lyrics_actions_sheet.dart';
import '../../domain/repositories/audio_repository.dart';

/// Pantalla principal del reproductor - Rediseñada
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late PageController _pageController;
  Timer? _debounceTimer; // Timer for debouncing swipes
  bool _showLyrics = false;
  final ColorExtractionService _colorService = ColorExtractionService();
  List<Color>? _backgroundColors; // List for gradient

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(audioPlayerProvider).currentIndex;
    _pageController = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize background color for current track
      final currentTrack = ref.read(audioPlayerProvider).currentTrack;
      if (currentTrack != null) {
        _updateBackgroundColor(currentTrack.id);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _debounceTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  Future<void> _updateBackgroundColor(String? trackId) async {
    if (trackId == null) return;

    final colors = await _colorService.getBackgroundColors(trackId);
    if (mounted) {
      setState(() {
        _backgroundColors = colors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final hasNext = ref.watch(audioPlayerProvider.select((s) => s.hasNext));
    final hasPrevious = ref.watch(
      audioPlayerProvider.select((s) => s.hasPrevious),
    );
    final currentIndex = ref.watch(
      audioPlayerProvider.select((s) => s.currentIndex),
    );
    final repeatMode = ref.watch(
      audioPlayerProvider.select((s) => s.repeatMode),
    );
    final shuffleMode = ref.watch(
      audioPlayerProvider.select((s) => s.shuffleMode),
    );

    // Listeners for side effects (background color, artwork precache, page controller)
    _setupListeners(queue);

    return Scaffold(
      backgroundColor: Colors.black, // Dark mode strict
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _backgroundColors ?? [Colors.black, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Subtle overlay to ensure text readability if needed, or rely on dark colors
          Container(color: Colors.black.withValues(alpha: 0.3)),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopBar(context, currentTrack),
              Expanded(
                child: _buildMiddleSection(
                  context,
                  currentTrack,
                  queue,
                  currentIndex,
                  isPlaying,
                  hasNext,
                  hasPrevious,
                  repeatMode,
                  shuffleMode,
                ),
              ),
              _buildBottomBar(context, currentTrack),
            ],
          ),

          // Lyrics Layer (Draggable Sheet)
          if (_showLyrics)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if (notification.extent == 0.0) {
                    setState(() {
                      _showLyrics = false;
                    });
                  }
                  return true;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: 0.5,
                  minChildSize: 0.0,
                  maxChildSize: 0.95,
                  snap: true,
                  snapSizes: const [0.0, 0.5, 0.95],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          LyricsView(
                            scrollController: scrollController,
                            opacity: 0.7, // Higher opacity for sheet mode
                          ),
                          // Handle (Pill)
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // More Actions for Lyrics
                          if (currentTrack != null)
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => LyricsActionsSheet(
                                        track: currentTrack,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _setupListeners(List<Track> queue) {
    // Update background color
    ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (_, next) {
      if (next != null) {
        _updateBackgroundColor(next.id);
      }
    });

    // Page controller sync
    ref.listen(audioPlayerProvider.select((s) => s.currentIndex), (_, next) {
      if (next >= 0 &&
          _pageController.hasClients &&
          _pageController.page?.round() != next) {
        _pageController.jumpToPage(next);
      }
    });
  }

  // 1. TopBar
  Widget _buildTopBar(BuildContext context, Track? currentTrack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Centered Lyrics Button
              TextButton(
                onPressed: () => setState(() => _showLyrics = !_showLyrics),
                child: Text(
                  'Lyrics',
                  style: TextStyle(
                    color: _showLyrics
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: _showLyrics ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),

              // More Actions Button
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    if (currentTrack != null) {
                      _showTrackActions(context, currentTrack);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackActions(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrackActionsSheet(track: track),
    );
  }

  // 2. Middle Section
  Widget _buildMiddleSection(
    BuildContext context,
    Track? currentTrack,
    List<Track> queue,
    int currentIndex,
    bool isPlaying,
    bool hasNext,
    bool hasPrevious,
    AudioRepeatMode repeatMode,
    bool shuffleMode,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Album Art
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.width * 0.8, // Responsive size
            width: MediaQuery.of(context).size.width * 0.8,
            child: _buildAlbumCover(currentTrack, queue, currentIndex),
          ),
        ),

        const SizedBox(height: 24),

        // Song Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Text(
                currentTrack?.title ?? 'No Track Playing',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                currentTrack?.artist ?? 'Unknown Artist',
                style: const TextStyle(fontSize: 18, color: Colors.white60),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Playback Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color: shuffleMode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
              ),
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleShuffle(),
            ),
            _AnimatedIconButton(
              icon: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.skip_previous, color: Colors.white, size: 36),
              ),
              onTap: hasPrevious
                  ? () =>
                        ref.read(audioPlayerProvider.notifier).skipToPrevious()
                  : null,
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 40,
                ),
                onPressed: () =>
                    ref.read(audioPlayerProvider.notifier).togglePlayPause(),
                padding: const EdgeInsets.all(16),
              ),
            ),
            _AnimatedIconButton(
              icon: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.skip_next, color: Colors.white, size: 36),
              ),
              onTap: hasNext
                  ? () => ref.read(audioPlayerProvider.notifier).skipToNext()
                  : null,
            ),
            IconButton(
              icon: Icon(
                repeatMode == AudioRepeatMode.one
                    ? Icons.repeat_one
                    : Icons.repeat,
                color: repeatMode != AudioRepeatMode.off
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
              ),
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleRepeatMode(),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Progress Bar
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: ProgressBar(),
        ),
      ],
    );
  }

  // 3. BottomBar
  Widget _buildBottomBar(BuildContext context, Track? currentTrack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.album, color: Colors.white),
              onPressed: () {
                if (currentTrack?.album != null) {
                  final albumTracks = ref
                      .read(libraryViewModelProvider.notifier)
                      .getTracksByAlbum(currentTrack!.album!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EntityDetailScreen(
                        title: currentTrack.album!,
                        tracks: albumTracks,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'Album Songs',
            ),
            IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.4,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) {
                      return QueueScreen(scrollController: scrollController);
                    },
                  ),
                );
              },
              tooltip: 'Queue',
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                if (currentTrack?.artist != null) {
                  final artistTracks = ref
                      .read(libraryViewModelProvider.notifier)
                      .getTracksByArtist(currentTrack!.artist!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EntityDetailScreen(
                        title: currentTrack.artist!,
                        tracks: artistTracks,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'Artist Songs',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCover(Track? track, List<Track> queue, int currentIndex) {
    if (track == null) return _buildPlaceholderCover();

    // Using PageView for swipe support which users expect
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        // Debounce the audio loading to prevent "Connection aborted" crashes
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(audioPlayerProvider.notifier).loadTrackInQueue(index);
          }
        });
      },
      itemCount: queue.length,
      itemBuilder: (context, index) {
        // Optimization: Only render heavy artwork for current, next, and previous items
        final bool shouldRender = (index - currentIndex).abs() <= 1;

        if (!shouldRender) {
          return const SizedBox();
        }

        final itemTrack = queue[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: TrackArtwork(
              trackId: itemTrack.id,
              size:
                  300, // Reduced from potentially larger sizes, matches cache optimization
              borderRadius: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.white24, size: 80),
      ),
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final double pressedScale = 0.8;
  final Duration duration = const Duration(milliseconds: 150);

  const _AnimatedIconButton({required this.icon, required this.onTap});

  @override
  _AnimatedIconButtonState createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.onTap == null) return;

    setState(() => _isPressed = true);
    widget.onTap!();

    Future.delayed(widget.duration, () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.icon, // The icon widget itself (e.g. Icon or IconButton)
      ),
    );
  }
}
