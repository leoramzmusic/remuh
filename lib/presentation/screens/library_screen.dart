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
import 'settings_screen.dart';
import 'entity_detail_screen.dart';
import 'player_screen.dart';

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
          final customization = ref.watch(customizationProvider);
          final icons = AppIconSet.fromStyle(customization.iconStyle);

          final isGrid = ref.watch(isGridViewProvider);
          final sortOption = ref.watch(sortOptionProvider);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Biblioteca'),
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
                PopupMenuButton<SortOption>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Ordenar',
                  onSelected: (option) {
                    ref.read(sortOptionProvider.notifier).state = option;
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: SortOption.name,
                      child: Text('Nombre'),
                    ),
                    PopupMenuItem(value: SortOption.date, child: Text('Fecha')),
                    PopupMenuItem(
                      value: SortOption.artist,
                      child: Text('Artista'),
                    ),
                    PopupMenuItem(
                      value: SortOption.album,
                      child: Text('Álbum'),
                    ),
                  ],
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
                IconButton(
                  icon: Icon(icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Ajustes',
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
              onRefresh: () =>
                  ref.read(libraryViewModelProvider.notifier).scanLibrary(),
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
    if (state.tracks.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref, icons);
    }
    if (state.isScanning && state.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final tracks = state.tracks;
    return ListView.builder(
      itemCount: tracks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Consumer(
                builder: (context, ref, _) {
                  final isShuffleActive = ref.watch(
                    audioPlayerProvider.select((s) => s.shuffleMode),
                  );
                  return Icon(
                    Icons.shuffle,
                    size: 28,
                    color: isShuffleActive
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.white,
                  );
                },
              ),
            ),
            title: const Text(
              'Modo Aleatorio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${tracks.length} canciones'),
            onTap: () {
              ref
                  .read(audioPlayerProvider.notifier)
                  .loadPlaylist(tracks, 0, startShuffled: true);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
            },
          );
        }

        final track = tracks[index - 1];
        return ListTile(
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
                .loadPlaylist(tracks, index - 1);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
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
    if (artists.isEmpty && !state.isScanning)
      return _buildEmptyState(ref, icons);

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
    if (albums.isEmpty && !state.isScanning)
      return _buildEmptyState(ref, icons);

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
            'No se encontró música.\nAsegúrate de dar permisos.',
            textAlign: TextAlign.center,
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
