import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/widgets/equalizer_sheet.dart';
import '../providers/sleep_timer_provider.dart';
import '../viewmodels/equalizer_view_model.dart';

import 'dart:async';
import '../../domain/entities/track.dart';

import '../providers/dynamic_color_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/progress_bar.dart';
import 'queue_screen.dart';
import '../widgets/lyrics_view.dart';
import '../providers/library_view_model.dart';
import '../widgets/marquee_text.dart';
import 'entity_detail_screen.dart';

import '../widgets/track_actions_sheet.dart';
import '../widgets/lyrics_actions_sheet.dart';
import '../../domain/repositories/audio_repository.dart';
import '../widgets/shuffle_indicator.dart';
import '../widgets/player_gesture_wrapper.dart';
import '../../core/utils/logger.dart';

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
  bool _showQueue = false;
  bool _isProgrammaticPageChange =
      false; // Flag to skip loading on programmatic jumps
  Track? _lastStableTrack; // To avoid empty UI during transitions

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(audioPlayerProvider).currentIndex;
    _pageController = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
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

    // Listeners for side effects (artwork precache, page controller)
    _setupListeners(queue);

    // Preserve the last known track when loading or when currentTrack is null for a split second
    final displayedTrack = currentTrack ?? _lastStableTrack;
    if (currentTrack != null) {
      _lastStableTrack = currentTrack;
    }

    final dynamicColorsAsync = ref.watch(dynamicColorsProvider);
    // Use the last known value during loading to avoid the "gray flash"
    final dynamicColors =
        dynamicColorsAsync.value ?? [Colors.black, Colors.black];

    return PopScope(
      canPop: !_showLyrics && !_showQueue,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_showLyrics) {
          setState(() {
            _showLyrics = false;
          });
        } else if (_showQueue) {
          setState(() {
            _showQueue = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Dark mode strict
        body: PlayerGestureWrapper(
          onSwipeUp: () => setState(() => _showQueue = true),
          child: Stack(
            children: [
              // Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      dynamicColors[0].withValues(alpha: 0.8),
                      dynamicColors[1].withValues(alpha: 0.6),
                      Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Subtle overlay to ensure text readability if needed, or rely on dark colors
              Container(color: Colors.black.withValues(alpha: 0.3)),
              Column(
                children: [
                  if (!isLandscape) _buildTopBar(context, displayedTrack),
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeDashboard(
                            context,
                            displayedTrack,
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
                            displayedTrack,
                            queue,
                            currentIndex,
                            isPlaying,
                            hasNext,
                            hasPrevious,
                            repeatMode,
                            shuffleMode,
                          ),
                  ),
                  if (!isLandscape) _buildBottomBar(context, displayedTrack),
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
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
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
                        child:
                            NotificationListener<
                              DraggableScrollableNotification
                            >(
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
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor
                                          .withValues(
                                            alpha: 0.5,
                                          ), // Semi-transparent
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
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
                                                scrollController:
                                                    scrollController,
                                              ),
                                              // Actions
                                              Positioned(
                                                top: 0,
                                                right: 16,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.more_vert,
                                                  ),
                                                  onPressed: () {
                                                    if (currentTrack != null) {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        isScrollControlled:
                                                            true,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        builder: (context) =>
                                                            LyricsActionsSheet(
                                                              track:
                                                                  currentTrack,
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

              // Persistent Queue Layer (Pull-up Sheet)
              if (_showQueue)
                Positioned.fill(
                  child: Stack(
                    children: [
                      // Barrier
                      GestureDetector(
                        onTap: () => setState(() => _showQueue = false),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                      // Pull-up Sheet
                      NotificationListener<DraggableScrollableNotification>(
                        onNotification: (notification) {
                          if (notification.extent < 0.25) {
                            setState(() => _showQueue = false);
                          }
                          return true;
                        },
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.6,
                          minChildSize: 0.0,
                          maxChildSize: 1.0,
                          expand: true,
                          snap: true,
                          snapSizes: const [0.6, 1.0],
                          builder: (context, scrollController) {
                            return QueueScreen(
                              scrollController: scrollController,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _setupListeners(List<Track> queue) {
    // Update background color and precache next/prev artwork
    ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (_, next) {
      if (next != null) {
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
        _isProgrammaticPageChange = true;
        _pageController.jumpToPage(next);
        // Reset after a short delay to allow onPageChanged to fire and be ignored
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isProgrammaticPageChange = false;
        });
      }
    });
  }

  // 1. TopBar
  Widget _buildTopBar(BuildContext context, Track? displayedTrack) {
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
                    if (displayedTrack != null) {
                      _showTrackActions(context, displayedTrack);
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
    Track? displayedTrack,
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
                        displayedTrack,
                        queue,
                        currentIndex,
                        false,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Song Info
                  _buildSongInfo(displayedTrack),

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

  Widget _buildSongInfo(Track? track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: MarqueeText(
              key: ValueKey('title_${track?.id ?? 'none'}'),
              text: track?.title ?? 'No Track Playing',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              height: 32,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: MarqueeText(
              key: ValueKey('artist_${track?.id ?? 'none'}'),
              text: track?.artist ?? 'Unknown Artist',
              style: const TextStyle(fontSize: 18, color: Colors.white60),
              height: 24,
            ),
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
    final double sideIconSize = compact
        ? 16
        : 20; // Repetir, Aleatorio, Temporizador, Ecualizador
    final double skipIconSize = compact ? 40 : 44; // Anterior y Siguiente
    final double playPauseSize = compact ? 72 : 80; // Play/Pause dominante

    final eqEnabled = ref.watch(equalizerProvider.select((s) => s.isEnabled));
    final isTimerActive = ref.watch(sleepTimerProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Columna izquierda: Repetir y Aleatorio
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Repetir',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  repeatMode == AudioRepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  key: ValueKey('repeat_$repeatMode'),
                  size: sideIconSize,
                  color: repeatMode != AudioRepeatMode.off
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleRepeatMode(),
            ),
            IconButton(
              tooltip: 'Aleatorio',
              icon: ShuffleIndicator(
                isActive: shuffleMode,
                size: sideIconSize,
                inactiveColor: Colors.white.withValues(alpha: 0.4),
              ),
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
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.timer_outlined,
                  key: ValueKey('timer_$isTimerActive'),
                  size: sideIconSize,
                  color: isTimerActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              onPressed: () {
                ref.read(sleepTimerProvider.notifier).state = !isTimerActive;
                if (ref.read(sleepTimerProvider)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Temporizador activado (Simulado)'),
                    ),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Ecualizador',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.equalizer_rounded,
                  key: ValueKey('eq_$eqEnabled'),
                  size: sideIconSize,
                  color: eqEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withValues(alpha: 0.4),
                ),
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
    Track? displayedTrack,
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
                    if (displayedTrack != null) {
                      _showTrackActions(context, displayedTrack);
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
                          displayedTrack,
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
                        _buildSongInfo(displayedTrack),
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
  Widget _buildBottomBar(BuildContext context, Track? displayedTrack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.album, color: Colors.white),
              onPressed: () {
                if (displayedTrack?.album != null) {
                  final albumTracks = ref
                      .read(libraryViewModelProvider.notifier)
                      .getTracksByAlbum(displayedTrack!.album!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EntityDetailScreen(
                        title: displayedTrack.album!,
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
              onPressed: () => setState(() => _showQueue = true),
              tooltip: 'Queue',
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                if (displayedTrack?.artist != null) {
                  final artistTracks = ref
                      .read(libraryViewModelProvider.notifier)
                      .getTracksByArtist(displayedTrack!.artist!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EntityDetailScreen(
                        title: displayedTrack.artist!,
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
        if (_isProgrammaticPageChange) {
          Logger.info('PageView: Ignoring programmatic change to index $index');
          return;
        }

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
