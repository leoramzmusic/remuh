import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_view_model.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../screens/player_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/visualizer_screen.dart';
import '../screens/equalizer_screen.dart';
import '../screens/playlists_screen.dart';
import '../../domain/entities/track.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostPlayed = ref
        .read(libraryViewModelProvider.notifier)
        .getMostPlayedTracks();
    final recentFavorites = ref
        .read(libraryViewModelProvider.notifier)
        .getRecentFavorites();

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  Icons.library_music_rounded,
                  'Biblioteca',
                  onTap: () => Navigator.pop(context),
                ),
                _buildNavItem(
                  context,
                  Icons.playlist_play_rounded,
                  'Listas de reproducción',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistsScreen(),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  context,
                  Icons.equalizer_rounded,
                  'Ecualizador',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EqualizerScreen(),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  context,
                  Icons.auto_awesome_rounded,
                  'Visualizador',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VisualizerScreen(),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  context,
                  Icons.settings_rounded,
                  'Ajustes',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                if (mostPlayed.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Más reproducidas'),
                  ...mostPlayed.map(
                    (track) => _buildTrackItem(context, ref, track),
                  ),
                  const SizedBox(height: 8),
                ],
                if (recentFavorites.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Favoritos recientes'),
                  ...recentFavorites.map(
                    (track) => _buildTrackItem(context, ref, track),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REMUH',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Tu identidad musical',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text(
            '¡Bienvenido de nuevo!',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, WidgetRef ref, Track track) {
    return ListTile(
      dense: true,
      leading: TrackArtwork(trackId: track.id, size: 40, borderRadius: 4),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        track.artist ?? 'Desconocido',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () {
        Navigator.pop(context);
        ref.read(audioPlayerProvider.notifier).loadAndPlay(track);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
    );
  }
}
