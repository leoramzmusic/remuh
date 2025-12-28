import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../providers/playlists_provider.dart';
import '../widgets/track_artwork.dart';
import '../../domain/entities/playlist.dart';
import 'settings_screen.dart';
import 'entity_detail_screen.dart';

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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Música'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
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
            tabs: [
              Tab(text: 'Canciones'),
              Tab(text: 'Artistas'),
              Tab(text: 'Álbumes'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(libraryViewModelProvider.notifier).scanLibrary(),
          child: TabBarView(
            children: [
              _buildTracksList(context, ref, libraryState),
              _buildArtistsList(context, ref, libraryState),
              _buildAlbumsList(context, ref, libraryState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTracksList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
  ) {
    if (state.tracks.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref);
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
              child: Icon(
                Icons.shuffle_rounded,
                color: Theme.of(context).colorScheme.primary,
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
              Navigator.pop(context);
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
          trailing: _buildPlaylistMenu(context, ref, track),
          onTap: () {
            ref
                .read(audioPlayerProvider.notifier)
                .loadPlaylist(tracks, index - 1);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildArtistsList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
  ) {
    final artists = ref.read(libraryViewModelProvider.notifier).getArtists();
    if (artists.isEmpty && !state.isScanning) return _buildEmptyState(ref);

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
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
  ) {
    final albums = ref.read(libraryViewModelProvider.notifier).getAlbums();
    if (albums.isEmpty && !state.isScanning) return _buildEmptyState(ref);

    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.album_rounded)),
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
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final playlistsProviderState = ref.watch(playlistsProvider);
        return PopupMenuButton<int>(
          icon: const Icon(Icons.playlist_add_rounded),
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

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_off_rounded,
            size: 64,
            color: Color.fromRGBO(0, 0, 0, 0.5),
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
