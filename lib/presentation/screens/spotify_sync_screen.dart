import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spotify_provider.dart';

class SpotifySyncScreen extends ConsumerWidget {
  const SpotifySyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotifyState = ref.watch(spotifyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar Spotify'),
        actions: [
          if (spotifyState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(spotifyProvider.notifier).logout(),
            ),
        ],
      ),
      body: spotifyState.isAuthenticated
          ? _buildPlaylistList(context, ref, spotifyState)
          : _buildLoginScreen(context, ref),
    );
  }

  Widget _buildLoginScreen(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_rounded, size: 80, color: Colors.greenAccent),
          const SizedBox(height: 24),
          const Text(
            'Conecta tu cuenta de Spotify',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'REMUH comparará tus playlists de Spotify con tu biblioteca local para encontrar lo que te falta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.login_rounded),
            label: const Text('AUTENTICAR CON SPOTIFY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => ref.read(spotifyProvider.notifier).login(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistList(
    BuildContext context,
    WidgetRef ref,
    SpotifyState state,
  ) {
    if (state.userPlaylists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: state.userPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = state.userPlaylists[index];

        return ListTile(
          leading: playlist.coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    playlist.coverUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.playlist_play_rounded),
          title: Text(playlist.name),
          subtitle: Text('${playlist.trackCount} canciones'),
          trailing: state.isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded),
          onTap: () async {
            await ref
                .read(spotifyProvider.notifier)
                .syncPlaylist(playlist.id, playlist.name);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sincronización completada')),
              );
            }
          },
        );
      },
    );
  }
}
