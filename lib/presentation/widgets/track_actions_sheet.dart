import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../providers/playlists_provider.dart';
import '../screens/entity_detail_screen.dart';
import 'track_artwork.dart';
import 'equalizer_sheet.dart';
import 'add_to_playlist_sheet.dart';

class TrackActionsSheet extends ConsumerWidget {
  final Track track;
  final int? playlistId;

  const TrackActionsSheet({super.key, required this.track, this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader(context),
          const Divider(color: Colors.white10),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildSection(context, 'Navegación', [
                  _ActionItem(
                    icon: Icons.album,
                    label: 'Ver álbum',
                    onTap: () {
                      Navigator.pop(context);
                      if (track.album != null) {
                        final albumTracks = ref
                            .read(libraryViewModelProvider.notifier)
                            .getTracksByAlbum(track.album!);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntityDetailScreen(
                              title: track.album!,
                              tracks: albumTracks,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _ActionItem(
                    icon: Icons.person,
                    label: 'Ver artista',
                    onTap: () {
                      Navigator.pop(context);
                      if (track.artist != null) {
                        final artistTracks = ref
                            .read(libraryViewModelProvider.notifier)
                            .getTracksByArtist(track.artist!);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntityDetailScreen(
                              title: track.artist!,
                              tracks: artistTracks,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ]),
                _buildSection(context, 'Organización', [
                  _ActionItem(
                    icon: Icons.playlist_add,
                    label: 'Añadir a playlist',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddToPlaylistSheet(track: track),
                      );
                    },
                  ),
                  if (playlistId != null &&
                      playlistId! > 0) // Only for real user playlists
                    _ActionItem(
                      icon: Icons.playlist_remove_rounded,
                      label: 'Quitar de esta lista',
                      onTap: () {
                        Navigator.pop(context);
                        ref
                            .read(playlistsProvider.notifier)
                            .removeTrackFromPlaylist(playlistId!, track.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Eliminado de la lista'),
                          ),
                        );
                      },
                    ),
                  _ActionItem(
                    icon: track.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: track.isFavorite
                        ? 'Quitar de favoritos'
                        : 'Marcar como favorito',
                    onTap: () {
                      Navigator.pop(context);
                      ref
                          .read(libraryViewModelProvider.notifier)
                          .toggleFavorite(track.id);
                    },
                  ),
                ]),
                _buildSection(context, 'Compartir', [
                  _ActionItem(
                    icon: Icons.copy,
                    label: 'Copiar información',
                    onTap: () {
                      Navigator.pop(context);
                      final info = '${track.title} - ${track.artist}';
                      Clipboard.setData(ClipboardData(text: info));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Información copiada')),
                      );
                    },
                  ),
                  _ActionItem(
                    icon: Icons.share,
                    label: 'Compartir pista',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ]),
                _buildSection(context, 'Experiencia', [
                  _ActionItem(
                    icon: Icons.info_outline,
                    label: 'Ver detalles',
                    onTap: () {
                      Navigator.pop(context);
                      _showDetailsDialog(context, track);
                    },
                  ),
                  _ActionItem(
                    icon: Icons.playlist_play,
                    label: 'Reproducir siguiente',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(audioPlayerProvider.notifier).playNext(track);
                    },
                  ),
                  _ActionItem(
                    icon: Icons.equalizer,
                    label: 'Ecualizador',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const EqualizerSheet(),
                      );
                    },
                  ),
                  _ActionItem(
                    icon: Icons.playlist_add_circle_outlined,
                    label: 'Reproducir después',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(audioPlayerProvider.notifier).addToEnd(track);
                    },
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          TrackArtwork(trackId: track.id, size: 60, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist ?? 'Desconocido',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showDetailsDialog(BuildContext context, Track track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Detalles de la pista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem('Título', track.title),
            _detailItem('Artista', track.artist ?? 'Desconocido'),
            _detailItem('Álbum', track.album ?? 'Desconocido'),
            _detailItem('Ruta', track.filePath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 24),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
