import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/widgets/equalizer_sheet.dart';

import 'dart:async';
import '../../domain/entities/track.dart';

import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/progress_bar.dart';
import 'queue_screen.dart';
import '../widgets/lyrics_view.dart';
import '../providers/library_view_model.dart';
import '../widgets/marquee_text.dart';
import 'entity_detail_screen.dart';
import '../../core/services/color_extraction_service.dart';

import '../widgets/track_actions_sheet.dart';
import '../widgets/lyrics_actions_sheet.dart';
import '../../domain/repositories/audio_repository.dart';
import '../widgets/shuffle_indicator.dart';

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

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Listeners for side effects (background color, artwork precache, page controller)
    _setupListeners(queue);

    return WillPopScope(
      onWillPop: () async {
        if (_showLyrics) {
          setState(() {
            _showLyrics = false;
          });
          return false; // Don't pop data, just close lyrics
        }
        return true; // Pop screen
      },
      child: Scaffold(
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
            Container(color: Colors.black.withOpacity(0.3)),
            Column(
              children: [
                if (!isLandscape) _buildTopBar(context, currentTrack),
                Expanded(
                  child: isLandscape
                      ? _buildLandscapeDashboard(
                          context,
                          currentTrack,
                          queue,
                          currentIndex,
                          isPlaying,
                          hasNext,
                          hasPrevious,
                          repeatMode,
                          shuffleMode,
                        )
                      : _buildMiddleSection(
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
                if (!isLandscape) _buildBottomBar(context, currentTrack),
              ],
            ),

            // Persistent Lyrics Layer (Stack-based)
            if (_showLyrics)
              Positioned.fill(
                child: Stack(
                  children: [
                    // Barrier (Tap to close)
                    GestureDetector(
                      onTap: () => setState(() => _showLyrics = false),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),
                    // Draggable Sheet
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            50 * (1 - value),
                          ), // Slide up effect
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: NotificationListener<DraggableScrollableNotification>(
                        onNotification: (notification) {
                          if (notification.extent < 0.25) {
                            // Close if dragged too low
                            setState(() {
                              _showLyrics = false;
                            });
                          }
                          return true;
                        },
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.5,
                          minChildSize: 0.0,
                          maxChildSize: 1.0, // Full persistent height!
                          expand:
                              true, // Use expand: true inside Stack for full height
                          snap: true,
                          snapSizes: const [0.5, 1.0],
                          builder: (context, scrollController) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor
                                    .withOpacity(0.5), // Semi-transparent
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        LyricsView(
                                          scrollController: scrollController,
                                        ),
                                        // Actions
                                        Positioned(
                                          top: 0,
                                          right: 16,
                                          child: IconButton(
                                            icon: const Icon(Icons.more_vert),
                                            onPressed: () {
                                              if (currentTrack != null) {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (context) =>
                                                      LyricsActionsSheet(
                                                        track: currentTrack,
                                                      ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
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
              ),
          ],
        ),
      ),
    );
  }

  void _setupListeners(List<Track> queue) {
    // Update background color and precache next/prev artwork
    ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (_, next) {
      if (next != null) {
        _updateBackgroundColor(next.id);

        // Pre-cache next artwork
        final currentIndex = ref.read(audioPlayerProvider).currentIndex;
        if (currentIndex != -1 && currentIndex < queue.length - 1) {
          final nextTrack = queue[currentIndex + 1];
          TrackArtwork.cacheArtwork(nextTrack.id);
        }
        // Pre-cache previous artwork
        if (currentIndex > 0) {
          final prevTrack = queue[currentIndex - 1];
          TrackArtwork.cacheArtwork(prevTrack.id);
        }
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
                  onPressed: () => Navigator.pop(
                    context,
                  ), // Normal pop, WillPopScope handles if lyrics open
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust spacing and sizes based on available height
        final double maxHeight = constraints.maxHeight;
        final bool isSmallScreen = maxHeight < 600;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Album Art
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      // Adaptive size: use 80% width but cap it based on height
                      height:
                          (isSmallScreen
                                  ? maxHeight * 0.4
                                  : MediaQuery.of(context).size.width * 0.8)
                              .clamp(150.0, 400.0),
                      width:
                          (isSmallScreen
                                  ? maxHeight * 0.4
                                  : MediaQuery.of(context).size.width * 0.8)
                              .clamp(150.0, 400.0),
                      child: _buildAlbumCover(
                        currentTrack,
                        queue,
                        currentIndex,
                        false,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Song Info
                  _buildSongInfo(currentTrack),

                  SizedBox(height: isSmallScreen ? 20 : 32),

                  // Playback Controls
                  _buildPlaybackControls(
                    context,
                    isPlaying,
                    hasNext,
                    hasPrevious,
                    repeatMode,
                    shuffleMode,
                    compact: isSmallScreen,
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Progress Bar
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: ProgressBar(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongInfo(Track? currentTrack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          MarqueeText(
            text: currentTrack?.title ?? 'No Track Playing',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            height: 32,
          ),
          const SizedBox(height: 8),
          MarqueeText(
            text: currentTrack?.artist ?? 'Unknown Artist',
            style: const TextStyle(fontSize: 18, color: Colors.white60),
            height: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(
    BuildContext context,
    bool isPlaying,
    bool hasNext,
    bool hasPrevious,
    AudioRepeatMode repeatMode,
    bool shuffleMode, {
    bool compact = false,
  }) {
    // Determine sizes based on screen and button type
    final double sideIconSize = compact ? 20 : 24;
    final double skipIconSize = compact ? 28 : 32;
    final double playPauseSize = compact ? 42 : 48;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Columna izquierda: Repetir y Aleatorio
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Repetir',
              icon: Icon(
                repeatMode == AudioRepeatMode.one
                    ? Icons.repeat_one
                    : Icons.repeat,
                size: sideIconSize,
                color: repeatMode != AudioRepeatMode.off
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleRepeatMode(),
            ),
            IconButton(
              tooltip: 'Aleatorio',
              icon: ShuffleIndicator(isActive: shuffleMode, size: sideIconSize),
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleShuffle(),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Controles centrales: Anterior, Play/Pause, Siguiente
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedIconButton(
              tooltip: 'Anterior',
              icon: Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: skipIconSize,
              ),
              onTap: hasPrevious
                  ? () =>
                        ref.read(audioPlayerProvider.notifier).skipToPrevious()
                  : null,
            ),
            const SizedBox(width: 12),
            _AnimatedIconButton(
              tooltip: isPlaying ? 'Pausar' : 'Reproducir',
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
                size: playPauseSize,
              ),
              onTap: () =>
                  ref.read(audioPlayerProvider.notifier).togglePlayPause(),
            ),
            const SizedBox(width: 12),
            _AnimatedIconButton(
              tooltip: 'Siguiente',
              icon: Icon(
                Icons.skip_next,
                color: Colors.white,
                size: skipIconSize,
              ),
              onTap: hasNext
                  ? () => ref.read(audioPlayerProvider.notifier).skipToNext()
                  : null,
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Columna derecha: Temporizador y Ecualizador
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Temporizador',
              icon: Icon(
                Icons.timer_outlined,
                size: sideIconSize,
                color: Colors.white,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temporizador próximamente')),
                );
              },
            ),
            IconButton(
              tooltip: 'Ecualizador',
              icon: Icon(
                Icons.equalizer_rounded,
                size: sideIconSize,
                color: Colors.white,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const EqualizerSheet(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeDashboard(
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
    return SafeArea(
      child: Column(
        children: [
          // Landscape Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back to library',
                ),
                IconButton(
                  icon: Icon(
                    Icons.lyrics,
                    color: _showLyrics
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                  ),
                  onPressed: () => setState(() => _showLyrics = !_showLyrics),
                  tooltip: 'Toggle lyrics',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    if (currentTrack != null) {
                      _showTrackActions(context, currentTrack);
                    }
                  },
                  tooltip: 'Track actions',
                ),
              ],
            ),
          ),
          // Main Landscape Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 43.0,
                vertical: 12.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Column: Square Album Artwork (Flex 4)
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildAlbumCover(
                          currentTrack,
                          queue,
                          currentIndex,
                          true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                  // Right Column: Controls and Info (Flex 6)
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSongInfo(currentTrack),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: ProgressBar(),
                        ),
                        const SizedBox(height: 24),
                        _buildPlaybackControls(
                          context,
                          isPlaying,
                          hasNext,
                          hasPrevious,
                          repeatMode,
                          shuffleMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                    expand: false, // For queue, false is fine inside modal
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

  Widget _buildAlbumCover(
    Track? track,
    List<Track> queue,
    int currentIndex,
    bool isLandscape,
  ) {
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
              size: isLandscape ? 200 : 300,
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
  final String? tooltip;
  final double pressedScale = 0.8;
  final Duration duration = const Duration(milliseconds: 150);

  const _AnimatedIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

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
    Widget content = GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.icon, // The icon widget itself (e.g. Icon or IconButton)
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }

    return content;
  }
}
