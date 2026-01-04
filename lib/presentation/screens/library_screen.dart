import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../providers/library_helpers.dart';
import '../providers/playlists_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/library/folders_view.dart';
import '../widgets/library/genres_view.dart';
import '../../domain/entities/playlist.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
import 'entity_detail_screen.dart';
import 'player_screen.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/track_contextual_menu.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryViewModelProvider);

    // Escuchar cambios para mostrar feedback de escaneo
    ref.listen(libraryViewModelProvider, (previous, next) {
      if (previous?.isScanning == true && next.isScanning == false) {
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al escanear: ${next.error}')),
          );
        } else if (next.lastAddedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Se han añadido ${next.lastAddedCount} nuevas canciones!',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else if (previous != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biblioteca actualizada')),
          );
        }
      }
    });

    return DefaultTabController(
      length: 5,
      child: Consumer(
        builder: (context, ref, _) {
          final iconStyle = ref.watch(
            customizationProvider.select((s) => s.iconStyle),
          );
          final icons = AppIconSet.fromStyle(iconStyle);

          final isGrid = ref.watch(isGridViewProvider);

          return Scaffold(
            drawer: const AppSidebar(),
            appBar: AppBar(
              title: Text(
                'REMUH',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  ),
                  onPressed: () {
                    ref.read(isGridViewProvider.notifier).state = !isGrid;
                  },
                  tooltip: isGrid ? 'Vista lista' : 'Vista cuadrícula',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: libraryState.isScanning
                      ? null
                      : () => ref
                            .read(libraryViewModelProvider.notifier)
                            .scanLibrary(),
                  tooltip: 'Actualizar biblioteca',
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Canciones'),
                  Tab(text: 'Álbumes'),
                  Tab(text: 'Artistas'),
                  Tab(text: 'Carpetas'),
                  Tab(text: 'Géneros'),
                ],
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Actualizando tu biblioteca...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return ref
                    .read(libraryViewModelProvider.notifier)
                    .scanLibrary();
              },
              child: TabBarView(
                children: [
                  _buildTracksList(context, ref, libraryState, icons),
                  _buildAlbumsList(context, ref, libraryState, icons),
                  _buildArtistsList(context, ref, libraryState, icons),
                  const FoldersView(),
                  const GenresView(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTracksList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    AppIconSet icons,
  ) {
    final tracks = ref.watch(sortedTracksProvider);

    // If we have no tracks and we are NOT scanning, show the empty state
    if (tracks.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref, icons);
    }

    // If we are scanning and have no tracks yet, show a dedicated scanning screen
    if (state.isScanning && tracks.isEmpty) {
      return _buildFullscreenScanningState(context, state);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tracks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle icon + label
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .loadPlaylist(tracks, 0, startShuffled: true);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlayerScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.shuffle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'REPRODUCCIÓN ALEATORIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ordenar icono con combo desplegable
                  Consumer(
                    builder: (context, ref, _) {
                      return PopupMenuButton<SortOption>(
                        icon: const Icon(
                          Icons.sort_rounded,
                          color: Colors.white70,
                        ),
                        onSelected: (option) {
                          ref.read(sortOptionProvider.notifier).state = option;
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: SortOption.nameAz,
                            child: Text('Ordenar de A-Z'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.nameZa,
                            child: Text('Ordenar de Z-A'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.dateAdded,
                            child: Text('Ordenar por fecha de añadido'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.albumAz,
                            child: Text('Ordenar álbumes A-Z'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.albumZa,
                            child: Text('Ordenar álbumes Z-A'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.artistAz,
                            child: Text('Ordenar artistas A-Z'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.artistZa,
                            child: Text('Ordenar artistas Z-A'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.albumArtistAz,
                            child: Text('Ordenar álbum por artista A-Z'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.albumArtistZa,
                            child: Text('Ordenar álbum por artista Z-A'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.duration,
                            child: Text('Ordenar por duración'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.yearAsc,
                            child: Text('Ordenar por año 0 - 2026'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.yearDesc,
                            child: Text('Ordenar por año 2026 - 0'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.mostPlayed,
                            child: Text('Ordenar por más reproducidas'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress indicator if scanning
              if (state.isScanning && state.scanProgress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.scanProgress!.percentage / 100,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        state.scanProgress!.statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${state.scanProgress!.processed}/${state.scanProgress!.total}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (state.scanProgress!.currentItem != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.scanProgress!.currentItem!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  '${tracks.length} canciones',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        }

        final track = tracks[index - 1];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Hero(
            tag: 'artwork_${track.id}',
            child: TrackArtwork(trackId: track.id, size: 50, borderRadius: 4),
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artist ?? 'Desconocido',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _buildPlaylistMenu(context, ref, track, icons),
          onTap: () {
            ref
                .read(audioPlayerProvider.notifier)
                .playTrackManually(tracks, index - 1);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          onLongPress: () {
            TrackContextualMenu.show(context, ref, track, tracks);
          },
        );
      },
    );
  }

  Widget _buildArtistsList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    AppIconSet icons,
  ) {
    final artists = ref.read(libraryViewModelProvider.notifier).getArtists();
    if (artists.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref, icons);
    }

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: CircleAvatar(child: Icon(icons.artist)),
          title: Text(artist),
          onTap: () {
            final artistTracks = ref
                .read(libraryViewModelProvider.notifier)
                .getTracksByArtist(artist);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EntityDetailScreen(title: artist, tracks: artistTracks),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumsList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    AppIconSet icons,
  ) {
    final albums = ref.read(libraryViewModelProvider.notifier).getAlbums();
    if (albums.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref, icons);
    }

    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
          leading: CircleAvatar(child: Icon(icons.album)),
          title: Text(album),
          onTap: () {
            final albumTracks = ref
                .read(libraryViewModelProvider.notifier)
                .getTracksByAlbum(album);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EntityDetailScreen(title: album, tracks: albumTracks),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistMenu(
    BuildContext context,
    WidgetRef ref,
    dynamic track,
    AppIconSet icons,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final playlistsProviderState = ref.watch(playlistsProvider);
        return PopupMenuButton<int>(
          icon: Icon(icons.add),
          onSelected: (playlistId) {
            ref
                .read(playlistsProvider.notifier)
                .addTrackToPlaylist(playlistId, track.id);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Añadido a la lista')));
          },
          itemBuilder: (context) {
            final playlists = playlistsProviderState.maybeWhen(
              data: (p) => p,
              orElse: () => <Playlist>[],
            );
            return playlists.map((Playlist p) {
              return PopupMenuItem<int>(value: p.id ?? 0, child: Text(p.name));
            }).toList();
          },
        );
      },
    );
  }

  Widget _buildFullscreenScanningState(
    BuildContext context,
    LibraryState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 32),
            Text(
              state.scanProgress?.statusMessage ?? 'Preparando biblioteca...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (state.scanProgress != null &&
                state.scanProgress!.total > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.scanProgress!.percentage / 100,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.scanProgress!.processed} de ${state.scanProgress!.total} canciones',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              state.scanProgress != null && state.scanProgress!.total > 0
                  ? 'Organizando tu gran colección...'
                  : 'Estamos preparando tu música...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref, AppIconSet icons) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icons.lyrics, // Usar nota si está disponible
            size: 64,
            color: const Color.fromRGBO(0, 0, 0, 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pudimos encontrar canciones en tu dispositivo.\n¿Están en una carpeta diferente o falta algún permiso?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(libraryViewModelProvider.notifier).scanLibrary(),
            child: const Text('Escanear ahora'),
          ),
        ],
      ),
    );
  }
}
