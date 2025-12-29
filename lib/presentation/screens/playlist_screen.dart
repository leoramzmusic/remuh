import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/playlists_provider.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
import 'playlist_tracks_screen.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Listas'),
        actions: [
          IconButton(
            icon: Icon(icons.add),
            onPressed: () => _showCreatePlaylistDialog(context, ref),
          ),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return const Center(
              child: Text('Aún no tienes listas de reproducción'),
            );
          }

          return ListView.builder(
            itemCount: playlists.length,
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(icons.playlist),
                ),
                title: Text(playlist.name),
                subtitle: Text('${playlist.trackIds.length} canciones'),
                trailing: IconButton(
                  icon: Icon(icons.delete),
                  onPressed: () => _showDeleteConfirmation(
                    context,
                    ref,
                    playlist.id!,
                    playlist.name,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlaylistTracksScreen(playlist: playlist),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Lista'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre de la lista'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(playlistsProvider.notifier)
                    .createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Lista'),
        content: Text('¿Estás seguro de que quieres eliminar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(playlistsProvider.notifier).deletePlaylist(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
