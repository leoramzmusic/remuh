import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/entities/track.dart';
import '../../domain/repositories/audio_repository.dart';

import '../providers/audio_player_provider.dart';
import '../widgets/secondary_actions.dart';
import '../widgets/progress_bar.dart';
import '../widgets/track_artwork.dart';
import 'queue_screen.dart';
import '../widgets/lyrics_view.dart';
import '../providers/library_view_model.dart';
import 'entity_detail_screen.dart';
import '../../core/services/color_extraction_service.dart';

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
  Color? _backgroundColor; // Nullable to use theme color initially

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

    final color = await _colorService.getDominantColor(trackId);
    if (mounted) {
      setState(() {
        _backgroundColor = color;
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
          // Optional: Background gradient if desired, or stick to plain black as requested
          // Container(color: Colors.black),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopBar(context),
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

          if (_showLyrics) const Positioned.fill(child: LyricsView()),
        ],
      ),
    );
  }

  void _setupListeners(List<Track> queue) {
    // Update background color
    ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (_, next) {
      if (next != null) _updateBackgroundColor(next.id);
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
  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            IconButton(
              icon: Icon(
                _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                color: _showLyrics
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                size: 24,
              ),
              onPressed: () => setState(() => _showLyrics = !_showLyrics),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
              onPressed: () {
                // Show options menu (re-using SecondaryActions logic or custom sheet)
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF2D2D2D),
                  builder: (_) =>
                      const SecondaryActions(), // Re-using existing actions widget as a sheet
                );
              },
            ),
          ],
        ),
      ),
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
            IconButton(
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 36,
              ),
              onPressed: hasPrevious
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
                    color: Colors.white.withOpacity(0.2),
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
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
              onPressed: hasNext
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
              icon: const Icon(Icons.queue_music, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QueueScreen()),
              ),
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
