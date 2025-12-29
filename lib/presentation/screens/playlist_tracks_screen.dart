import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../widgets/track_artwork.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/track.dart';

class PlaylistTracksScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistTracksScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryViewModelProvider);

    // Filtrar canciones de la biblioteca que están en esta lista
    final List<Track> playlistTracks = libraryState.tracks
        .where((t) => playlist.trackIds.contains(t.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(playlist.name)),
      body: playlistTracks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('Esta lista está vacía'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Ir a la biblioteca para añadir canciones',
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: playlistTracks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isShuffleActive = ref.watch(
                            audioPlayerProvider.select((s) => s.shuffleMode),
                          );
                          return Icon(
                            Icons.shuffle,
                            size: 28,
                            color: isShuffleActive
                                ? Colors.orangeAccent
                                : Colors.white,
                          );
                        },
                      ),
                    ),
                    title: const Text(
                      'Modo Aleatorio',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${playlistTracks.length} canciones'),
                    onTap: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .loadPlaylist(playlistTracks, 0, startShuffled: true);
                    },
                  );
                }

                final track = playlistTracks[index - 1];
                return ListTile(
                  leading: Hero(
                    tag: 'artwork_${track.id}',
                    child: TrackArtwork(
                      trackId: track.id,
                      size: 50,
                      borderRadius: 4,
                    ),
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
                  onTap: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .loadPlaylist(playlistTracks, index - 1);
                  },
                );
              },
            ),
    );
  }
}
