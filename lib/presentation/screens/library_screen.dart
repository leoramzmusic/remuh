import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Música'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(libraryViewModelProvider.notifier).scanLibrary();
            },
          ),
        ],
      ),
      body: libraryState.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(
              child: Text(
                'No se encontró música.\nAsegúrate de dar permisos.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: const Icon(Icons.music_note),
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
                  // Opcional: Cerrar pantalla si fuera un modal, o mostrar mini-player
                  Navigator.pop(context);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
