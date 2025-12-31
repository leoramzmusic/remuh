import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'equalizer_screen.dart';
import 'personalization_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), centerTitle: true),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _SettingsTile(
            icon: Icons.color_lens_rounded,
            title: 'Personalización',
            subtitle: 'Colores, fuentes, animaciones, estilo visual',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonalizationSettingsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.theater_comedy_rounded,
            title: 'Temas',
            subtitle: 'Configuración de la pantalla de reproducción',
            onTap: () => _navigateToPlaceholder(context, 'Temas'),
          ),
          _SettingsTile(
            icon: Icons.view_compact_rounded,
            title: 'Reproducción minimizada',
            subtitle: 'Opciones para vista compacta del reproductor',
            onTap: () =>
                _navigateToPlaceholder(context, 'Reproducción minimizada'),
          ),
          _SettingsTile(
            icon: Icons.dashboard_customize_rounded,
            title: 'Interfaz',
            subtitle: 'Menú deslizable, comportamiento de biblioteca',
            onTap: () => _navigateToPlaceholder(context, 'Interfaz'),
          ),
          _SettingsTile(
            icon: Icons.music_note_rounded,
            title: 'Audio',
            subtitle: 'Crossfade, sin pausas, ecualizador, repetir',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EqualizerScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.album_rounded,
            title: 'Metadatos',
            subtitle: 'Carátulas, imágenes de artista, scrobble, lista negra',
            onTap: () => _navigateToPlaceholder(context, 'Metadatos'),
          ),
          _SettingsTile(
            icon: Icons.devices_rounded,
            title: 'Remoto',
            subtitle: 'Widget, notificaciones, pantalla de bloqueo',
            onTap: () => _navigateToPlaceholder(context, 'Remoto'),
          ),
          _SettingsTile(
            icon: Icons.science_rounded,
            title: 'Avanzado',
            subtitle: 'Opciones de desarrollo y características beta',
            onTap: () => _navigateToPlaceholder(context, 'Avanzado'),
          ),
          _SettingsTile(
            icon: Icons.backup_rounded,
            title: 'Copia de seguridad',
            subtitle: 'Exportar/importar configuración y datos',
            onTap: () => _navigateToPlaceholder(context, 'Copia de seguridad'),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'FAQ',
            subtitle: 'Preguntas frecuentes sobre el uso de REMUH',
            onTap: () => _navigateToPlaceholder(context, 'FAQ'),
          ),
          _SettingsTile(
            icon: Icons.list_alt_rounded,
            title: 'Lista de cambios',
            subtitle: 'Historial de versiones y novedades',
            onTap: () => _navigateToPlaceholder(context, 'Lista de cambios'),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de',
            subtitle: 'Información sobre la app y créditos',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _navigateToPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Text(
              'Ajustes de $title\nPróximamente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'REMUH',
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.music_note_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
      children: [
        const Text(
          'Reproductor de música minimalista y escalable que prioriza la identidad y la experiencia del usuario.',
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
