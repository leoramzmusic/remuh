import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_view_model.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
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
          _SectionHeader(title: 'Personalización'),

          // Selector de Color
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color de Acento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: themeColors.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final name = themeColors.keys.elementAt(index);
                      final color = themeColors.values.elementAt(index);
                      final isSelected =
                          ref.watch(customizationProvider).colorName == name;

                      return GestureDetector(
                        onTap: () => ref
                            .read(customizationProvider.notifier)
                            .setColor(name),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selector de Estilo de Iconos
          ListTile(
            leading: const Icon(Icons.star_outline_rounded),
            title: const Text('Estilo de Iconos'),
            subtitle: Text(
              ref.watch(customizationProvider).iconStyle == IconStyle.material
                  ? 'Material (Android)'
                  : 'Cupertino (iOS)',
            ),
            trailing: Switch(
              value:
                  ref.watch(customizationProvider).iconStyle ==
                  IconStyle.cupertino,
              onChanged: (isCupertino) {
                ref
                    .read(customizationProvider.notifier)
                    .setIconStyle(
                      isCupertino ? IconStyle.cupertino : IconStyle.material,
                    );
              },
            ),
          ),

          const Divider(),
          _SectionHeader(title: 'Servicios Online'),

          ListTile(
            leading: const Icon(Icons.vpn_key_rounded),
            title: const Text('Genius API Token'),
            subtitle: const Text(
              'Necesario para buscar letras online automáticamente',
            ),
            onTap: () async {
              final customization = ref.read(customizationProvider);
              final controller = TextEditingController(
                text: customization.geniusToken,
              );

              final newToken = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Configurar Genius API'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pega tu Client Access Token de Genius:'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Token aquí...',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // TODO: Abrir URL en navegador real si es posible
                          // Por ahora solo un hint visual
                        },
                        child: const Text('¿Cómo obtener un token?'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              );

              if (newToken != null) {
                ref
                    .read(customizationProvider.notifier)
                    .setGeniusToken(newToken);
              }
            },
            trailing: Icon(
              ref.watch(customizationProvider).geniusToken.isEmpty
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              color: ref.watch(customizationProvider).geniusToken.isEmpty
                  ? Colors.orange
                  : Colors.green,
            ),
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
