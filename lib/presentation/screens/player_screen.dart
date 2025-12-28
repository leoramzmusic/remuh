import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/audio_repository.dart';

import '../providers/audio_player_provider.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/track_artwork.dart';
import 'library_screen.dart';
import 'playlist_screen.dart';
import 'queue_screen.dart';
import '../widgets/lyrics_view.dart';
import 'lyrics_editor_screen.dart';
import '../providers/playlists_provider.dart';
import '../../domain/entities/playlist.dart';

/// Pantalla principal del reproductor
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late PageController _pageController;
  bool _showLyrics = false;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Sincronizar el PageController con el currentIndex cuando cambia externamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialIndex = ref.read(audioPlayerProvider).currentIndex;
      if (initialIndex >= 0) {
        _pageController.jumpToPage(initialIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    // Swipe Abajo (Velocity > 0) -> Mostrar Cola
    if (details.primaryVelocity! > 500) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QueueScreen()),
      );
    }
    // Swipe Arriba (Velocity < 0) -> Volver a Biblioteca
    else if (details.primaryVelocity! < -500) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LibraryScreen()),
      );
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    // Swipe Derecha (Velocity > 0) -> Siguiente pista
    if (details.primaryVelocity! > 500) {
      ref.read(audioPlayerProvider.notifier).skipToNext();
    }
    // Swipe Izquierda (Velocity < 0) -> Anterior pista
    else if (details.primaryVelocity! < -500) {
      ref.read(audioPlayerProvider.notifier).skipToPrevious();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar solo lo necesario para el build principal
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
    final hasNext = ref.watch(audioPlayerProvider.select((s) => s.hasNext));
    final hasPrevious = ref.watch(
      audioPlayerProvider.select((s) => s.hasPrevious),
    );
    final isBuffering = ref.watch(
      audioPlayerProvider.select((s) => s.isBuffering),
    );
    final error = ref.watch(audioPlayerProvider.select((s) => s.error));
    final hasError = ref.watch(audioPlayerProvider.select((s) => s.hasError));
    final currentIndex = ref.watch(
      audioPlayerProvider.select((s) => s.currentIndex),
    );
    final repeatMode = ref.watch(
      audioPlayerProvider.select((s) => s.repeatMode),
    );
    final shuffleMode = ref.watch(
      audioPlayerProvider.select((s) => s.shuffleMode),
    );

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
          // Si el salto es grande, saltamos directamente para no cargar carátulas intermedias
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

    return GestureDetector(
      onVerticalDragEnd: _onVerticalDragEnd,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('REMUH'),
          actions: [
            IconButton(
              icon: const Icon(Icons.library_music_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LibraryScreen(),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(
                _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                color: _showLyrics
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onSelected: (value) {
                if (value == 'toggle') {
                  setState(() {
                    _showLyrics = !_showLyrics;
                  });
                } else if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LyricsEditorScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    _showLyrics ? 'Ocultar letras' : 'Mostrar letras',
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar letras (LRC)'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.playlist_play_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaylistScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Carátula del álbum o Letras
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Carátula (se desvanece si hay letras)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showOverlay = !_showOverlay),
                        child: Stack(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: _showLyrics ? 0.2 : 1.0,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: queue.length,
                                onPageChanged: (index) {
                                  if (index != currentIndex) {
                                    ref
                                        .read(audioPlayerProvider.notifier)
                                        .loadTrackInQueue(index);
                                  }
                                },
                                itemBuilder: (context, index) {
                                  final track = queue[index];
                                  return _buildArtwork(context, track);
                                },
                              ),
                            ),
                            if (_showOverlay && !_showLyrics)
                              Positioned.fill(
                                child: _buildOverlay(
                                  context,
                                  ref,
                                  currentTrack,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Letras (se muestran sobre la carátula difuminada)
                      if (_showLyrics)
                        const Positioned.fill(child: LyricsView()),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Información de la pista con AnimatedSwitcher
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    currentTrack?.title ?? 'Sin pista',
                    key: ValueKey(currentTrack?.id ?? 'none'),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: AppConstants.smallPadding),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    currentTrack?.artist ?? 'Artista desconocido',
                    key: ValueKey(
                      (currentTrack?.artist ?? 'unknown') +
                          (currentTrack?.id ?? ''),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppConstants.largePadding * 2),

                // Barra de progreso
                const ProgressBar(),

                const SizedBox(height: AppConstants.largePadding),

                // Controles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón Shuffle
                    IconButton(
                      onPressed: () => ref
                          .read(audioPlayerProvider.notifier)
                          .toggleShuffle(),
                      icon: Icon(
                        shuffleMode
                            ? Icons.shuffle_on_rounded
                            : Icons.shuffle_rounded,
                        color: shuffleMode
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      iconSize: AppConstants.mediumIconSize,
                    ),

                    // Botón anterior
                    IconButton(
                      onPressed: hasPrevious
                          ? () => ref
                                .read(audioPlayerProvider.notifier)
                                .skipToPrevious()
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: AppConstants.largeIconSize,
                    ),

                    // Botón play/pause
                    const PlayPauseButton(),

                    // Botón siguiente
                    IconButton(
                      onPressed: hasNext
                          ? () => ref
                                .read(audioPlayerProvider.notifier)
                                .skipToNext()
                          : null,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: AppConstants.largeIconSize,
                    ),

                    // Botón Repeat
                    IconButton(
                      onPressed: () => ref
                          .read(audioPlayerProvider.notifier)
                          .toggleRepeatMode(),
                      icon: Icon(
                        repeatMode == AudioRepeatMode.one
                            ? Icons.repeat_one_on_rounded
                            : repeatMode == AudioRepeatMode.all
                            ? Icons.repeat_on_rounded
                            : Icons.repeat_rounded,
                        color: repeatMode != AudioRepeatMode.off
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      iconSize: AppConstants.mediumIconSize,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Estado de reproducción
                if (isBuffering)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.smallPadding),
                    child: CircularProgressIndicator(),
                  ),

                if (hasError)
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Text(
                      'Error: $error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(BuildContext context, Track? track) {
    if (track == null) return _buildPlaceholderArtwork(context);

    return Container(
      margin: const EdgeInsets.all(AppConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Hero(
        tag: 'artwork_${track.id}',
        child: TrackArtwork(
          trackId: track.id,
          size: 320,
          borderRadius: AppConstants.defaultBorderRadius,
        ),
      ),
    );
  }

  Widget _buildPlaceholderArtwork(BuildContext context) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: 100,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, WidgetRef ref, Track? track) {
    if (track == null) return const SizedBox.shrink();

    final isFav = ref.watch(playlistsProvider.notifier).isFavorite(track.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Stack(
        children: [
          // Esquina superior izquierda: Añadir a Playlist
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(
                Icons.playlist_add_rounded,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () => _showPlaylistPicker(context, ref, track),
            ),
          ),

          // Arriba Centro: Texto Lyrics
          Align(
            alignment: Alignment.topCenter,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showLyrics = true;
                  _showOverlay = false;
                });
              },
              child: const Text(
                'LYRICS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Esquina superior derecha: Favorito
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : Colors.white,
                size: 32,
              ),
              onPressed: () {
                ref.read(playlistsProvider.notifier).toggleFavorite(track.id);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, WidgetRef ref, Track track) {
    final playlistState = ref.read(playlistsProvider);
    final playlists = playlistState.maybeWhen(
      data: (p) => p,
      orElse: () => <Playlist>[],
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Añadir a Playlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay playlists creadas'),
                ),
              ...playlists.map(
                (p) => ListTile(
                  leading: const Icon(Icons.playlist_play_rounded),
                  title: Text(p.name),
                  onTap: () {
                    ref
                        .read(playlistsProvider.notifier)
                        .addTrackToPlaylist(p.id!, track.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Añadido a ${p.name}')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
