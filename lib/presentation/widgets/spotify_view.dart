import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spotify_provider.dart';
import '../../domain/entities/spotify_playlist.dart';

class SpotifyView extends ConsumerWidget {
  const SpotifyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotifyState = ref.watch(spotifyProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: spotifyState.isAuthenticated
          ? const _LinkedSpotifyView()
          : const _UnlinkedSpotifyView(),
    );
  }
}

class _UnlinkedSpotifyView extends ConsumerWidget {
  const _UnlinkedSpotifyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_rounded,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Conecta con Spotify',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vincula tu cuenta para ver tus playlists y listas destacadas directamente en REMUH.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => ref.read(spotifyProvider.notifier).login(),
              icon: const Icon(Icons.login_rounded),
              label: const Text('CONECTAR AHORA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.green.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedSpotifyView extends StatefulWidget {
  const _LinkedSpotifyView();

  @override
  State<_LinkedSpotifyView> createState() => _LinkedSpotifyViewState();
}

class _LinkedSpotifyViewState extends State<_LinkedSpotifyView>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _innerTabController,
          isScrollable: true,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.greenAccent,
          tabs: const [
            Tab(text: "Populares"),
            Tab(text: "Destacadas"),
            Tab(text: "Mis Playlists"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            children: [
              _SpotifyPlaylistGrid(type: 'featured'),
              _SpotifyPlaylistGrid(type: 'category'),
              _SpotifyPlaylistGrid(type: 'user'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpotifyPlaylistGrid extends ConsumerWidget {
  final String type;
  const _SpotifyPlaylistGrid({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spotifyProvider);
    List<SpotifyPlaylist> playlists;

    switch (type) {
      case 'featured':
        playlists = state.featuredPlaylists;
        break;
      case 'category':
        playlists = state.categoryPlaylists;
        break;
      case 'user':
        playlists = state.userPlaylists;
        break;
      default:
        playlists = [];
    }

    if (playlists.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _SpotifyPlaylistCard(playlist: playlist);
      },
    );
  }
}

class _SpotifyPlaylistCard extends ConsumerWidget {
  final SpotifyPlaylist playlist;
  const _SpotifyPlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // Implement viewing playlist tracks or syncing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sincronizando ${playlist.name}...')),
        );
        ref
            .read(spotifyProvider.notifier)
            .syncPlaylist(playlist.id, playlist.name);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (playlist.coverUrl != null)
                    Image.network(playlist.coverUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      color: Colors.white10,
                      child: const Icon(Icons.playlist_play_rounded, size: 50),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${playlist.trackCount} canciones',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
