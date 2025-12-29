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
import '../providers/library_view_model.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
import 'entity_detail_screen.dart';

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
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);

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
              icon: Icon(icons.playlist),
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
                const Spacer(flex: 1), // Empuja hacia abajo para centrar
                // Carátula del álbum o Letras (60-70% del ancho)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.88,
                      maxHeight: MediaQuery.of(context).size.width * 0.88,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Carátula con PageView para swipe entre canciones
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showOverlay = !_showOverlay),
                          child: AnimatedOpacity(
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
                        ),

                        // Overlay de controles rápidos (favorito, editar, etc.)
                        if (_showOverlay && !_showLyrics)
                          Positioned.fill(
                            child: _buildOverlay(context, ref, currentTrack),
                          ),

                        // Vista de letras sincronizadas
                        if (_showLyrics)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => setState(() => _showLyrics = false),
                              onLongPress: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LyricsEditorScreen(),
                                  ),
                                );
                              },
                              child: const LyricsView(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48), // Espaciado emocional premium
                // Información de la pista (Centrada)
                Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        currentTrack?.title ?? 'Sin pista',
                        key: ValueKey(currentTrack?.id ?? 'none'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        currentTrack?.artist ?? 'Artista desconocido',
                        key: ValueKey(
                          (currentTrack?.artist ?? 'unknown') +
                              (currentTrack?.id ?? ''),
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Controles de Reproducción (Shuffle, Prev, Play, Next, Repeat)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => ref
                          .read(audioPlayerProvider.notifier)
                          .toggleShuffle(),
                      icon: Icon(
                        icons.shuffle,
                        color: shuffleMode
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      iconSize: 28,
                    ),
                    IconButton(
                      onPressed: hasPrevious
                          ? () => ref
                                .read(audioPlayerProvider.notifier)
                                .skipToPrevious()
                          : null,
                      icon: Icon(icons.skipPrevious),
                      iconSize: 44,
                    ),
                    const PlayPauseButton(size: 54),
                    IconButton(
                      onPressed: hasNext
                          ? () => ref
                                .read(audioPlayerProvider.notifier)
                                .skipToNext()
                          : null,
                      icon: Icon(icons.skipNext),
                      iconSize: 44,
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(audioPlayerProvider.notifier)
                          .toggleRepeatMode(),
                      icon: Icon(
                        repeatMode == AudioRepeatMode.one
                            ? icons.repeatOne
                            : icons.repeat,
                        color: repeatMode != AudioRepeatMode.off
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      iconSize: 28,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Barra de progreso y tiempos (Bajo los controles)
                const ProgressBar(),

                const SizedBox(height: 32),

                // Acciones adicionales e información de navegación
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(icons.album),
                      onPressed: () {
                        if (currentTrack != null) {
                          final albumTracks = ref
                              .read(libraryViewModelProvider.notifier)
                              .getTracksByAlbum(
                                currentTrack.album ?? 'Desconocido',
                              );
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
                    IconButton(
                      icon: Icon(icons.queue),
                      onPressed: () => _showSmartQueue(context, ref),
                      tooltip: 'Ver cola',
                    ),
                    IconButton(
                      icon: Icon(icons.artist),
                      onPressed: () {
                        if (currentTrack != null) {
                          final artistTracks = ref
                              .read(libraryViewModelProvider.notifier)
                              .getTracksByArtist(
                                currentTrack.artist ?? 'Desconocido',
                              );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EntityDetailScreen(
                                title: currentTrack.artist ?? 'Artista',
                                tracks: artistTracks,
                              ),
                            ),
                          );
                        }
                      },
                      tooltip: 'Ver artista',
                    ),
                  ],
                ),

                // Indicador de buffering o errores (discreto)
                if (isBuffering || hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: isBuffering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Error: $error',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                  ),

                const Spacer(flex: 2), // Espacio inferior equilibrado
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Hero(
        tag: 'artwork_${track.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TrackArtwork(
            trackId: track.id,
            size: 500, // HD size
            borderRadius: 20,
          ),
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
              onLongPress: () {
                setState(() => _showOverlay = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LyricsEditorScreen(),
                  ),
                );
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

  void _showSmartQueue(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Consumer(
              builder: (context, ref, _) {
                final playerState = ref.watch(audioPlayerProvider);
                final effectiveQueue = playerState.effectiveQueue;
                final currentTrack = playerState.currentTrack;

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Siguiente en reproducción',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: effectiveQueue.length,
                          itemBuilder: (context, index) {
                            final track = effectiveQueue[index];
                            final isCurrent = track.id == currentTrack?.id;

                            return ListTile(
                              leading: TrackArtwork(
                                trackId: track.id,
                                size: 40,
                                borderRadius: 4,
                              ),
                              title: Text(
                                track.title,
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                track.artist ?? 'Desconocido',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isCurrent
                                  ? const Icon(Icons.equalizer_rounded)
                                  : null,
                              onTap: () {
                                // Encontrar el índice original en la cola real
                                final originalIndex = playerState.queue
                                    .indexWhere((t) => t.id == track.id);
                                if (originalIndex != -1) {
                                  ref
                                      .read(audioPlayerProvider.notifier)
                                      .loadTrackInQueue(originalIndex);
                                }
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
