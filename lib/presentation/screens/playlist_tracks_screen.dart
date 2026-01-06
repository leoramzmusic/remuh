import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../providers/playlists_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/track_actions_sheet.dart';
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
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (!playlist.isSmart && playlist.name != 'Favoritos')
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded),
              onPressed: () {
                ref
                    .read(playlistsProvider.notifier)
                    .playPlaylist(playlist, shuffle: false);
              },
            ),
        ],
      ),
      body: playlistTracks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    playlist.isSmart
                        ? Icons.auto_awesome_rounded
                        : Icons.music_note_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    playlist.isSmart
                        ? 'No hay canciones suficientes para esta lista'
                        : 'Esta lista está vacía',
                  ),
                  const SizedBox(height: 8),
                  if (!playlist.isSmart)
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
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isShuffleActive = ref.watch(
                            audioPlayerProvider.select((s) => s.shuffleMode),
                          );
                          return Icon(
                            Icons.shuffle,
                            size: 28,
                            color: isShuffleActive
                                ? Theme.of(context).colorScheme.primary
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
                          .read(playlistsProvider.notifier)
                          .playPlaylist(playlist, shuffle: true);
                    },
                  );
                }

                final track = playlistTracks[index - 1];
                return ListTile(
                  leading: Hero(
                    tag: 'playlist_artwork_${track.id}',
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
                  onLongPress: () => _showTrackActions(context, track),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showTrackActions(context, track),
                  ),
                );
              },
            ),
    );
  }

  void _showTrackActions(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrackActionsSheet(
        track: track,
        // Pass extra info if needed to show/hide "Remove from playlist"
        playlistId: playlist.isSmart ? null : playlist.id,
      ),
    );
  }
}
