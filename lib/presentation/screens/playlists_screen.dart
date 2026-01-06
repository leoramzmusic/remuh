import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlists_provider.dart';
import '../widgets/create_playlist_dialog.dart';
import 'playlist_tracks_screen.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de reproducción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          final smartPlaylists = playlists.where((p) => p.isSmart).toList();
          final userPlaylists = playlists.where((p) => !p.isSmart).toList();

          return CustomScrollView(
            slivers: [
              if (smartPlaylists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Inteligentes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final playlist = smartPlaylists[index];
                    return _PlaylistTile(playlist: playlist);
                  }, childCount: smartPlaylists.length),
                ),
              ],
              if (userPlaylists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Mis Listas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final playlist = userPlaylists[index];
                    return _PlaylistTile(playlist: playlist);
                  }, childCount: userPlaylists.length),
                ),
              ],
              if (playlists.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No hay listas disponibles')),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreatePlaylistDialog(),
    );
  }
}

class _PlaylistTile extends ConsumerWidget {
  final playlist;

  const _PlaylistTile({required this.playlist});

  IconData _getIcon() {
    if (!playlist.isSmart) return Icons.playlist_play_rounded;
    switch (playlist.smartType) {
      case 'recent':
        return Icons.history_rounded;
      case 'top':
        return Icons.trending_up_rounded;
      case 'genre':
        return Icons.category_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getIcon(), color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${playlist.trackIds.length} canciones',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistTracksScreen(playlist: playlist),
          ),
        );
      },
      trailing: !playlist.isSmart && playlist.name != 'Favoritos'
          ? IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () {
                _showDeleteDialog(context, ref);
              },
            )
          : null,
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${playlist.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(playlistsProvider.notifier).deletePlaylist(playlist.id!);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
