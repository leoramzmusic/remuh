import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/track.dart';
import '../providers/library_view_model.dart';
import '../../core/utils/logger.dart';

class CoverOptionsMenu extends ConsumerWidget {
  final Track track;

  const CoverOptionsMenu({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(color: Colors.white24),
          _buildOption(
            context,
            icon: Icons.search,
            title: 'Buscar portada en Google',
            onTap: () => _searchOnGoogle(context),
          ),
          _buildOption(
            context,
            icon: Icons.image,
            title: 'Seleccionar de la galería',
            onTap: () => _pickFromGallery(context, ref),
          ),
          if (track.artworkPath != null) ...[
            const Divider(color: Colors.white24),
            _buildOption(
              context,
              icon: Icons.restore,
              title: 'Restaurar portada original',
              onTap: () => _restoreOriginal(context, ref),
              isDestructive: true,
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          Icon(Icons.album, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Portada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  track.title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _searchOnGoogle(BuildContext context) async {
    Navigator.pop(context); // Close sheet first
    final query = '${track.artist ?? ""} ${track.title} album cover'.trim();
    final url = Uri.parse(
      'https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(query)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el navegador')),
          );
        }
      }
    } catch (e) {
      Logger.error('Error launching URL', e);
    }
  }

  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context); // Close sheet
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await ref
            .read(libraryViewModelProvider.notifier)
            .updateTrackCover(track.id, image.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Portada actualizada para ${track.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Error picking image', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar imagen')),
        );
      }
    }
  }

  Future<void> _restoreOriginal(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    try {
      await ref
          .read(libraryViewModelProvider.notifier)
          .updateTrackCover(track.id, null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portada original restaurada')),
        );
      }
    } catch (e) {
      Logger.error('Error restoring cover', e);
    }
  }
}
