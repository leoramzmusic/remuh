import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/queue/queue_screen.dart';
import 'equalizer_sheet.dart';
import 'package:share_plus/share_plus.dart';

/// Widget for secondary action buttons in player screen
class SecondaryActions extends ConsumerWidget {
  const SecondaryActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final isFavorite = currentTrack != null
        ? ref.watch(favoritesProvider).contains(currentTrack.id)
        : false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.playlist_add_rounded,
            label: 'Playlist',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Añadir a playlist próximamente')),
              );
            },
          ),
          _ActionButton(
            icon: Icons.lyrics_outlined,
            label: 'Letras',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver letras próximamente')),
              );
            },
          ),
          _ActionButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
            label: 'Favorito',
            color: isFavorite ? Colors.red : null,
            onTap: () {
              if (currentTrack != null) {
                ref.read(favoritesProvider.notifier).toggle(currentTrack.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite
                          ? 'Eliminado de favoritos'
                          : 'Añadido a favoritos',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          _ActionButton(
            icon: Icons.share_rounded,
            label: 'Compartir',
            onTap: () {
              if (currentTrack != null) {
                Share.share(
                  '🎵 Estoy escuchando: ${currentTrack.title}\n'
                  '🎤 Artista: ${currentTrack.artist ?? "Desconocido"}\n'
                  '💿 Álbum: ${currentTrack.album ?? "Desconocido"}',
                  subject: 'Compartir canción desde REMUH',
                );
              }
            },
          ),
          _ActionButton(
            icon: Icons.queue_music_rounded,
            label: 'Cola',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.4,
                  maxChildSize: 1.0,
                  expand: false,
                  builder: (context, scrollController) =>
                      QueueScreen(scrollController: scrollController),
                ),
              );
            },
          ),
          _ActionButton(
            icon: Icons.album_rounded,
            label: 'Álbum',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver álbum próximamente')),
              );
            },
          ),
          _ActionButton(
            icon: Icons.timer_outlined,
            label: 'Timer',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Temporizador próximamente')),
              );
            },
          ),
          _ActionButton(
            icon: Icons.equalizer_rounded,
            label: 'EQ',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const EqualizerSheet(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: color ?? Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
