import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../providers/playlists_provider.dart';
import '../widgets/track_artwork.dart';
import '../../domain/entities/playlist.dart';
import 'settings_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Música'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(libraryViewModelProvider.notifier).scanLibrary(),
        child: _buildBody(context, ref, libraryState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, LibraryState state) {
    if (state.tracks.isEmpty) {
      if (state.isScanning) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text('Error: ${state.error}'),
            ],
          ),
        );
      }
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

    final tracks = state.tracks;
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
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
          trailing: Consumer(
            builder: (context, ref, child) {
              final playlistsProviderState = ref.watch(playlistsProvider);
              // Handle loading state for playlists if necessary, but playlists are small and local
              return PopupMenuButton<int>(
                icon: const Icon(Icons.playlist_add_rounded),
                onSelected: (playlistId) {
                  ref
                      .read(playlistsProvider.notifier)
                      .addTrackToPlaylist(playlistId, track.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Añadido a la lista')),
                  );
                },
                itemBuilder: (context) {
                  final playlists = playlistsProviderState.maybeWhen(
                    data: (p) => p,
                    orElse: () => <Playlist>[],
                  );
                  return playlists.map((Playlist p) {
                    return PopupMenuItem<int>(
                      value: p.id ?? 0,
                      child: Text(p.name),
                    );
                  }).toList();
                },
              );
            },
          ),
          onTap: () {
            ref.read(audioPlayerProvider.notifier).loadPlaylist(tracks, index);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
