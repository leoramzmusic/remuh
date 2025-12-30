import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/track.dart';
import '../providers/lyrics_provider.dart';
import '../screens/lyrics_editor_screen.dart';

class LyricsActionsSheet extends ConsumerWidget {
  final Track track;

  const LyricsActionsSheet({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsState = ref.watch(lyricsProvider);

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
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
          const Divider(color: Colors.white10, height: 24),
          _buildActionItem(
            context,
            icon: Icons.search,
            label: 'Buscar en Google',
            subtitle: 'Encuentra la letra original online',
            onTap: () => _searchOnGoogle(context),
          ),
          _buildActionItem(
            context,
            icon: Icons.copy,
            label: 'Copiar letra',
            subtitle: 'Copia el texto actual al portapapeles',
            enabled: lyricsState.lines.isNotEmpty,
            onTap: () => _copyLyrics(context, lyricsState),
          ),
          _buildActionItem(
            context,
            icon: Icons.paste,
            label: 'Pegar letra',
            subtitle: 'Sobrescribir con texto del portapapeles',
            onTap: () => _pasteLyrics(context, ref),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildActionItem(
            context,
            icon: Icons.auto_fix_high,
            label: 'Sincronizar automáticamente',
            subtitle: 'Detecta los tiempos usando IA (Forced Alignment)',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LyricsEditorScreen(),
                ),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.timer_outlined,
            label: 'Sincronizar tiempos',
            subtitle: 'Edita la letra y sincroniza con el tiempo actual',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LyricsEditorScreen(),
                ),
              );
            },
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
          const Icon(Icons.lyrics, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Letras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${track.title} - ${track.artist}',
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

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white70 : Colors.white24,
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white24,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.white38 : Colors.white10,
          fontSize: 12,
        ),
      ),
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Future<void> _searchOnGoogle(BuildContext context) async {
    final query = Uri.encodeComponent('${track.title} ${track.artist} lyrics');
    final url = Uri.parse('https://www.google.com/search?q=$query');

    if (await canLaunchUrl(url)) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el navegador')),
        );
      }
    }
  }

  void _copyLyrics(BuildContext context, LyricsState state) {
    if (state.lines.isEmpty) return;

    final lyricsText = state.lines.map((l) => l.text).join('\n');
    Clipboard.setData(ClipboardData(text: lyricsText));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Letra copiada al portapapeles'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pasteLyrics(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El portapapeles está vacío')),
        );
      }
      return;
    }

    if (context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text('¿Pegar letra?'),
          content: const Text(
            'Esto reemplazará la letra actual con el texto del portapapeles.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        await ref
            .read(lyricsProvider.notifier)
            .saveLyrics(track.filePath, data.text!);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Letra actualizada')));
        }
      }
    }
  }
}
