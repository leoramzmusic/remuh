import 'dart:math' as math;
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
import '../widgets/play_pause_button.dart';
import '../widgets/progress_bar.dart';
import 'queue/queue_screen.dart';
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
                          minChildSize:
                              0.4, // Keep it slightly visible or at least have a solid floor
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
        if (currentIndex != -1) {
          // Pre-cache next 3 tracks for smooth scrolling/skipping
          for (int i = 1; i <= 3; i++) {
            if (currentIndex + i < queue.length) {
              TrackArtwork.cacheArtwork(queue[currentIndex + i].id);
            }
          }
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
        final isDraggingSlider = ref.watch(sliderDraggingProvider);

        return SingleChildScrollView(
          physics: isDraggingSlider
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildAlbumCover(
                            displayedTrack,
                            queue,
                            currentIndex,
                            false,
                            heroTag: displayedTrack != null
                                ? 'art_${displayedTrack.id}'
                                : null,
                          ),
                          if (ref.watch(
                            audioPlayerProvider.select(
                              (s) => s.isFastForwarding,
                            ),
                          ))
                            const _SeekIndicator(isForward: true),
                          if (ref.watch(
                            audioPlayerProvider.select((s) => s.isRewinding),
                          ))
                            const _SeekIndicator(isForward: false),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Song Info
                  _buildSongInfo(displayedTrack),

                  SizedBox(height: isSmallScreen ? 16 : 28),

                  // Element Scaling/Fading Animation
                  AnimatedBuilder(
                    animation:
                        ModalRoute.of(context)?.animation ??
                        kAlwaysCompleteAnimation,
                    builder: (context, child) {
                      final animation =
                          ModalRoute.of(context)?.animation ??
                          kAlwaysCompleteAnimation;
                      // Elements fade out faster than they slide
                      final fadeValue = Curves.easeInQuint.transform(
                        (1.0 - animation.value).clamp(0.0, 1.0),
                      );
                      final opacity = 1.0 - fadeValue;
                      final scale = 1.0 - (fadeValue * 0.1);

                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: Column(
                      children: [
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

                        SizedBox(height: isSmallScreen ? 12 : 20),

                        // Progress Bar
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: ProgressBar(),
                        ),
                      ],
                    ),
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
    final shuffleMode = ref.watch(
      audioPlayerProvider.select((s) => s.shuffleMode),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          // Mode Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (shuffleMode ? Colors.orangeAccent : Colors.blueAccent)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (shuffleMode ? Colors.orangeAccent : Colors.blueAccent)
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              shuffleMode ? 'MODO ALEATORIO' : 'MODO ORDENADO',
              style: TextStyle(
                color: shuffleMode ? Colors.orangeAccent : Colors.blueAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Hero(
              tag: 'title_${track?.id ?? 'none'}',
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
    final sleepTimerState = ref.watch(sleepTimerProvider);
    final isTimerActive = sleepTimerState.isActive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Columna izquierda: Repetir y Aleatorio - Ancho fijo para centrar la fila del medio
        SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: _AnimatedIconButton(
                    tooltip: 'Repetir',
                    pressedScale: 0.8,
                    rotateAngle: 2 * math.pi,
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
                    onTap: () {
                      ref.read(audioPlayerProvider.notifier).toggleRepeatMode();
                      final newMode = ref.read(audioPlayerProvider).repeatMode;
                      final message = switch (newMode) {
                        AudioRepeatMode.all => 'Repetición de lista activada',
                        AudioRepeatMode.one => 'Repetición de canción activada',
                        AudioRepeatMode.off => 'Repetición desactivada',
                      };
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Espaciador de tamaño fijo igual al de la derecha para mantener alineación
              const SizedBox(height: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: _AnimatedIconButton(
                    tooltip: 'Aleatorio',
                    pressedScale: 0.8,
                    rotateAngle: 0.3 * math.pi,
                    icon: ShuffleIndicator(
                      isActive: shuffleMode,
                      size: sideIconSize,
                      inactiveColor: Colors.white.withValues(alpha: 0.4),
                    ),
                    onTap: () =>
                        ref.read(audioPlayerProvider.notifier).toggleShuffle(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Controles centrales: Anterior, Play/Pause, Siguiente
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedIconButton(
              icon: Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: skipIconSize,
              ),
              slideOffset: -10.0,
              pressedScale: 0.8,
              onTap: hasPrevious
                  ? () =>
                        ref.read(audioPlayerProvider.notifier).skipToPrevious()
                  : null,
              // Allow rewind if we have a track, regardless of queue position
              onLongPressStart:
                  ref.read(audioPlayerProvider).currentTrack != null
                  ? () => ref.read(audioPlayerProvider.notifier).startRewind()
                  : null,
              onLongPressEnd: ref.read(audioPlayerProvider).currentTrack != null
                  ? () => ref.read(audioPlayerProvider.notifier).stopRewind()
                  : null,
            ),
            const SizedBox(width: 8),
            PlayPauseButton(size: (playPauseSize / 1.5).clamp(48.0, 96.0)),
            const SizedBox(width: 8),
            _AnimatedIconButton(
              icon: Icon(
                Icons.skip_next,
                color: Colors.white,
                size: skipIconSize,
              ),
              slideOffset: 12.0,
              pressedScale: 0.85,
              onTap: hasNext
                  ? () => ref.read(audioPlayerProvider.notifier).skipToNext()
                  : null,
              onLongPressStart: hasNext
                  ? () => ref
                        .read(audioPlayerProvider.notifier)
                        .startFastForward()
                  : null,
              onLongPressEnd: hasNext
                  ? () =>
                        ref.read(audioPlayerProvider.notifier).stopFastForward()
                  : null,
            ),
          ],
        ),

        const SizedBox(width: 8),

        // Columna derecha: Temporizador y Ecualizador - Ancho fijo para centrar la fila del medio
        SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: _AnimatedIconButton(
                    tooltip: 'Temporizador',
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isTimerActive ? Icons.timer : Icons.timer_outlined,
                        key: ValueKey('timer_$isTimerActive'),
                        size: sideIconSize,
                        color: isTimerActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    onTap: () => _showSleepTimerSheet(context, ref),
                  ),
                ),
              ),
              // Espaciador de tamaño fijo para las etiquetas del timer
              SizedBox(
                height: 12,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isTimerActive &&
                          sleepTimerState.remainingTime != null)
                        Text(
                          _formatDurationShort(sleepTimerState.remainingTime!),
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (isTimerActive && sleepTimerState.pauseAtEndOfTrack)
                        Text(
                          'FIN',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: _AnimatedIconButton(
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
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const EqualizerSheet(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
    bool isLandscape, {
    String? heroTag,
  }) {
    if (track == null) {
      return TrackArtwork(
        trackId: 'none',
        size: 300,
        borderRadius: 20,
        heroTag: heroTag,
      );
    }

    // ModalRoute animation to drive the minimize effect
    final routeAnimation =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;

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

        if (!shouldRender) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: Listenable.merge([_pageController, routeAnimation]),
          builder: (context, child) {
            // PageView Scroll factor
            double pageValue = 1.0;
            if (_pageController.position.hasContentDimensions) {
              pageValue = (_pageController.page! - index).abs();
              pageValue = (1 - (pageValue * 0.2)).clamp(0.8, 1.0);
            } else {
              pageValue = (index == currentIndex) ? 1.0 : 0.8;
            }

            // Route minimize factor
            final routeValue = routeAnimation.value;
            final double safeRouteValue = routeValue.isNaN ? 1.0 : routeValue;

            // Elements shrink when route is popping
            final double minimizeScale = 0.8 + (safeRouteValue * 0.2);
            final double finalScale = pageValue * minimizeScale;
            // Fade out if we are swiping away OR if we are minimizing
            final double opacity = (pageValue < 0.7)
                ? 0.0
                : (((pageValue - 0.7) / 0.3) * (0.5 + safeRouteValue * 0.5))
                      .clamp(0.0, 1.0);

            return Center(
              child: Transform.scale(
                scale: finalScale,
                child: Opacity(opacity: opacity, child: child),
              ),
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final artSize = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TrackArtwork(
                  trackId: queue[index].id,
                  size: artSize,
                  borderRadius: 20,
                  heroTag: index == currentIndex ? heroTag : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Temporizador',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La reproducción se pausará automáticamente',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildTimerOption(context, ref, 'Desactivar', null),
                  _buildTimerOption(
                    context,
                    ref,
                    'Al finalizar la canción',
                    Duration.zero,
                    isEndOfTrack: true,
                  ),
                  _buildTimerOption(
                    context,
                    ref,
                    '5 minutos',
                    const Duration(minutes: 5),
                  ),
                  _buildTimerOption(
                    context,
                    ref,
                    '10 minutos',
                    const Duration(minutes: 10),
                  ),
                  _buildTimerOption(
                    context,
                    ref,
                    '15 minutos',
                    const Duration(minutes: 15),
                  ),
                  _buildTimerOption(
                    context,
                    ref,
                    '30 minutos',
                    const Duration(minutes: 30),
                  ),
                  _buildTimerOption(
                    context,
                    ref,
                    '45 minutos',
                    const Duration(minutes: 45),
                  ),
                  _buildTimerOption(
                    context,
                    ref,
                    '1 hora',
                    const Duration(hours: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    Duration? duration, {
    bool isEndOfTrack = false,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        if (duration == null) {
          ref.read(sleepTimerProvider.notifier).cancelTimer();
        } else if (isEndOfTrack) {
          ref.read(sleepTimerProvider.notifier).setPauseAtEndOfTrack();
        } else {
          ref.read(sleepTimerProvider.notifier).setTimer(duration);
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              duration == null
                  ? 'Temporizador desactivado'
                  : 'Temporizador configurado: $title',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  String _formatDurationShort(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _SeekIndicator extends ConsumerWidget {
  final bool isForward;

  const _SeekIndicator({super.key, required this.isForward});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(
      audioPlayerProvider.select((s) => s.seekMultiplier),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            isForward ? 'FAST FORWARD ${speed}X' : 'REWIND ${speed}X',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final String? tooltip;
  final double pressedScale;
  final double slideOffset;
  final double rotateAngle;

  const _AnimatedIconButton({
    required this.icon,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.tooltip,
    this.pressedScale = 0.9,
    this.slideOffset = 0.0,
    this.rotateAngle = 0.0,
  });

  @override
  _AnimatedIconButtonState createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  bool _isLongPressActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: widget.pressedScale),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.pressedScale, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(widget.slideOffset, 0),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(widget.slideOffset, 0),
          end: Offset.zero,
        ),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: widget.rotateAngle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // If long press is active, ignore tap
    if (widget.onTap == null || _isLongPressActive) return;
    _controller.forward(from: 0);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: _handleTap,
      onLongPressStart: widget.onLongPressStart != null
          ? (_) {
              setState(() => _isLongPressActive = true);
              _controller.forward(from: 0);
              widget.onLongPressStart!();
            }
          : null,
      onLongPressEnd: widget.onLongPressEnd != null
          ? (_) {
              widget.onLongPressEnd!();
              // Reset long press flag after a small delay to ensure onTap isn't successfully triggered
              // by the system if the touch up happens too quickly
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) setState(() => _isLongPressActive = false);
              });
            }
          : null,
      onLongPressCancel: () {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isLongPressActive = false);
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.translate(
              offset: _slideAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: widget.icon,
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }

    return content;
  }
}
