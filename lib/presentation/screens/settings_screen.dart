import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_view_model.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Biblioteca'),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: const Text('Re-escanear biblioteca'),
            subtitle: Text(
              libraryState.isScanning
                  ? 'Escaneando...'
                  : 'Busca música nueva en tu dispositivo',
            ),
            trailing: libraryState.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: libraryState.isScanning
                ? null
                : () =>
                      ref.read(libraryViewModelProvider.notifier).scanLibrary(),
          ),

          const Divider(),
          _SectionHeader(title: 'Interfaz'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema'),
            subtitle: const Text('Sigue la configuración del sistema'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El tema sigue la configuración de tu sistema'),
                ),
              );
            },
          ),

          const Divider(),
          _SectionHeader(title: 'Acerca de'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Versión'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const ListTile(
            leading: Icon(Icons.code_rounded),
            title: Text('Desarrollado con Flutter'),
            subtitle: Text('Powered by Riverpod & Just Audio'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
