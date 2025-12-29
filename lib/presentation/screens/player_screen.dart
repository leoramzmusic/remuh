import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/audio_repository.dart';

import '../providers/audio_player_provider.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/track_artwork.dart';
import 'queue_screen.dart';
import '../widgets/lyrics_view.dart';
import '../providers/library_view_model.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
import 'entity_detail_screen.dart';
import '../../core/services/artwork_cache_service.dart';
import '../../core/services/color_extraction_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/secondary_actions.dart';
import 'package:share_plus/share_plus.dart';

/// Pantalla principal del reproductor - Rediseñada
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late PageController _pageController;
  bool _showLyrics = false;
  final ArtworkCacheService _artworkCache = ArtworkCacheService();
  final ColorExtractionService _colorService = ColorExtractionService();
  Color? _backgroundColor; // Nullable to use theme color initially

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialIndex = ref.read(audioPlayerProvider).currentIndex;
      if (initialIndex >= 0) {
        _pageController.jumpToPage(initialIndex);
      }

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
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);

    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
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

    // Update background color when track changes
    ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (
      previous,
      next,
    ) {
      if (next != null && next.id != previous?.id) {
        _updateBackgroundColor(next.id);
      }
    });

    // Precache artwork
    ref.listen(audioPlayerProvider.select((s) => s.currentIndex), (
      previous,
      next,
    ) {
      if (next >= 0 && queue.isNotEmpty) {
        final trackIds = queue.map((t) => t.id).toList();
        _artworkCache.precacheQueueArtwork(context, trackIds, next);
      }
    });

    // Escuchar cambios de índice para animar el PageView
    ref.listen(audioPlayerProvider.select((s) => s.currentIndex), (
      previous,
      next,
    ) {
      if (next >= 0 &&
          _pageController.hasClients &&
          _pageController.page?.round() != next) {
        final diff = (next - (_pageController.page?.round() ?? 0)).abs();
        if (diff > 1) {
          _pageController.jumpToPage(next);
        } else {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('REMUH'),
        actions: [
          IconButton(
            icon: Icon(
              _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
              color: _showLyrics ? Colors.white : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showLyrics = !_showLyrics;
              });
            },
            tooltip: _showLyrics ? 'Ocultar letras' : 'Mostrar letras',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: const Color(0xFF2D2D2D),
        child: SafeArea(
          child: Stack(
            children: [
              if (_showLyrics)
                _buildLyricsView()
              else
                _buildPlayerView(
                  context,
                  currentTrack,
                  queue,
                  currentIndex,
                  hasNext,
                  hasPrevious,
                  repeatMode,
                  shuffleMode,
                  icons,
                ),
              // DEBUG: Test visibility
              Positioned(
                top: 100,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red,
                  child: const Text(
                    'DEBUG: PLAYER SCREEN',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsView() {
    return GestureDetector(
      onTap: () => setState(() => _showLyrics = false),
      child: const LyricsView(),
    );
  }

  Widget _buildPlayerView(
    BuildContext context,
    Track? currentTrack,
    List<Track> queue,
    int currentIndex,
    bool hasNext,
    bool hasPrevious,
    AudioRepeatMode repeatMode,
    bool shuffleMode,
    AppIconSet icons,
  ) {
    return Column(
      children: [
        // Secondary actions at top
        const SecondaryActions(),

        const Spacer(flex: 1),

        // Album cover - Centered and large
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: _buildAlbumCover(currentTrack, queue, currentIndex),
          ),
        ),

        const SizedBox(height: 24),

        // Track counter
        if (queue.isNotEmpty)
          Text(
            '${currentIndex + 1} / ${queue.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),

        const SizedBox(height: 12),

        // Track information - Hierarchical
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  currentTrack?.title ?? 'Sin pista',
                  key: ValueKey(currentTrack?.id ?? 'none'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              // Artist
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  currentTrack?.artist ?? 'Artista desconocido',
                  key: ValueKey(
                    (currentTrack?.artist ?? 'unknown') +
                        (currentTrack?.id ?? ''),
                  ),
                  style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Album
              if (currentTrack?.album != null)
                Text(
                  currentTrack!.album!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Progress bar
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ProgressBar(),
        ),

        const SizedBox(height: 32),

        // Main controls - Redesigned
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle
            IconButton(
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleShuffle(),
              icon: Icon(
                icons.shuffle,
                color: shuffleMode ? Colors.white : Colors.white54,
              ),
              iconSize: 24,
            ),
            const SizedBox(width: 16),
            // Previous
            IconButton(
              onPressed: hasPrevious
                  ? () =>
                        ref.read(audioPlayerProvider.notifier).skipToPrevious()
                  : null,
              icon: Icon(icons.skipPrevious),
              iconSize: 32,
              color: Colors.white,
            ),
            const SizedBox(width: 24),
            // Play/Pause - Larger
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const PlayPauseButton(size: 48),
            ),
            const SizedBox(width: 24),
            // Next
            IconButton(
              onPressed: hasNext
                  ? () => ref.read(audioPlayerProvider.notifier).skipToNext()
                  : null,
              icon: Icon(icons.skipNext),
              iconSize: 32,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            // Repeat
            IconButton(
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggleRepeatMode(),
              icon: Icon(
                repeatMode == AudioRepeatMode.one
                    ? icons.repeatOne
                    : icons.repeat,
                color: repeatMode != AudioRepeatMode.off
                    ? Colors.white
                    : Colors.white54,
              ),
              iconSize: 24,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bottom actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white70),
              onPressed: () {
                if (currentTrack != null) {
                  Share.share(
                    '🎵 Estoy escuchando: ${currentTrack.title}\n'
                    '🎤 Artista: ${currentTrack.artist ?? "Desconocido"}\n'
                    '💿 Álbum: ${currentTrack.album ?? "Desconocido"}',
                    subject: 'Compartir canción desde REMUH',
                  );
                }
              },
              tooltip: 'Compartir',
            ),
            IconButton(
              icon: Icon(icons.queue, color: Colors.white70),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QueueScreen()),
                );
              },
              tooltip: 'Ver cola',
            ),
            IconButton(
              icon: Icon(icons.album, color: Colors.white70),
              onPressed: () {
                if (currentTrack != null) {
                  final albumTracks = ref
                      .read(libraryViewModelProvider.notifier)
                      .getTracksByAlbum(currentTrack.album ?? 'Desconocido');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EntityDetailScreen(
                        title: currentTrack.album ?? 'Álbum',
                        tracks: albumTracks,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'Ver álbum',
            ),
          ],
        ),

        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildAlbumCover(Track? track, List<Track> queue, int currentIndex) {
    if (track == null || queue.isEmpty) {
      return _buildPlaceholderCover();
    }

    return Container(
      key: ValueKey(track.id),
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! > 500) {
              ref.read(audioPlayerProvider.notifier).skipToNext();
            } else if (details.primaryVelocity! < -500) {
              ref.read(audioPlayerProvider.notifier).skipToPrevious();
            }
          },
          child: TrackArtwork(trackId: track.id, size: 280, borderRadius: 12),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 100, color: Colors.white24),
      ),
    );
  }
}
