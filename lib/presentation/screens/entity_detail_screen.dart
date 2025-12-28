import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';

class EntityDetailScreen extends ConsumerWidget {
  final String title;
  final List<Track> tracks;

  const EntityDetailScreen({
    super.key,
    required this.title,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: tracks.isEmpty
          ? const Center(child: Text('No hay canciones'))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
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
                        .loadPlaylist(tracks, index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
      floatingActionButton: tracks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(audioPlayerProvider.notifier).loadPlaylist(tracks, 0);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Reproducir Todo'),
            )
          : null,
    );
  }
}
