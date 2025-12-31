import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customization_provider.dart';
import '../widgets/color_selection_dialog.dart';
import '../widgets/typography_selection_dialog.dart';
import '../widgets/header_weight_selection_dialog.dart';

class PersonalizationSettingsScreen extends ConsumerWidget {
  const PersonalizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final notifier = ref.read(customizationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Personalización'), centerTitle: true),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _SectionHeader(title: '🎨 Color de acento'),
          ListTile(
            leading: Icon(
              Icons.palette_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Color de acento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Afecta íconos, textos y elementos visuales clave',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: customization.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Icon(
                Icons.keyboard_arrow_right_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ColorSelectionDialog(
                  currentColorName: customization.colorName,
                  customColor: customization.customColor,
                  onColorSelected: (name) => notifier.setColor(name),
                  onCustomColorSelected: (color) =>
                      notifier.setCustomColor(color),
                ),
              );
            },
          ),

          const Divider(),
          _SectionHeader(title: '🔤 Tipografía'),
          ListTile(
            leading: Icon(
              Icons.font_download_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Tipografía',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Fuente: ${_getTypographyName(customization.typography)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.keyboard_arrow_right_rounded),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => TypographySelectionDialog(
                  currentTypography: customization.typography,
                  onTypographySelected: (type) => notifier.setTypography(type),
                ),
              );
            },
          ),

          ListTile(
            leading: Icon(
              Icons.format_bold_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Fuente de encabezado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Grosor: ${_getHeaderWeightName(customization.headerWeight)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.keyboard_arrow_right_rounded),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => HeaderWeightSelectionDialog(
                  currentWeight: customization.headerWeight,
                  onWeightSelected: (weight) =>
                      notifier.setHeaderWeight(weight),
                ),
              );
            },
          ),

          const Divider(),
          _SectionHeader(title: '🎞️ Efectos de transición'),
          _buildDropdownTile<TransitionEffect>(
            context: context,
            icon: Icons.movie_filter_rounded,
            title: 'Efectos de transición',
            subtitle: 'Animación entre pantallas',
            value: customization.transitionEffect,
            items: TransitionEffect.values.map((effect) {
              return DropdownMenuItem(
                value: effect,
                child: Text(_getTransitionName(effect)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) notifier.setTransitionEffect(value);
            },
          ),

          const Divider(),
          _SectionHeader(title: 'Opciones de Tema'),
          _buildToggleTile(
            context: context,
            icon: Icons.light_mode_rounded,
            title: '🌞 Tema claro',
            subtitle: 'Restablece colores de ventanas principales',
            value: customization.isLightTheme,
            onChanged: notifier.setLightTheme,
          ),

          _buildToggleTile(
            context: context,
            icon: Icons.layers_clear_rounded,
            title: '🧼 Barra de acción transparente',
            subtitle: 'Activar/desactivar transparencia',
            value: customization.isTransparentActionBar,
            onChanged: notifier.setTransparentActionBar,
          ),

          _buildToggleTile(
            context: context,
            icon: Icons.blur_on_rounded,
            title: '🖼️ Fondo principal adaptable',
            subtitle: 'Imagen desenfocada del álbum actual',
            value: customization.isAdaptiveBackground,
            onChanged: notifier.setAdaptiveBackground,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }

  Widget _buildToggleTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  String _getTypographyName(AppTypography type) {
    return switch (type) {
      AppTypography.robotoThin => 'Roboto Thin',
      AppTypography.robotoRegular => 'Roboto Regular',
      AppTypography.robotoBlack => 'Roboto Black',
      AppTypography.robotoCondensed => 'Roboto Condensed',
      AppTypography.robotoCondensedLight => 'Roboto Condensed Light',
      AppTypography.robotoSlab => 'Roboto Slab',
      AppTypography.sansation => 'Sansation',
      AppTypography.ptSans => 'PT Sans',
      AppTypography.sourceSans => 'Source Sans',
      AppTypography.openSans => 'Open Sans',
      AppTypography.quicksand => 'Quicksand',
      AppTypography.ubuntu => 'Ubuntu',
      AppTypography.play => 'Play',
      AppTypography.archivoNarrow => 'Archivo Narrow',
      AppTypography.circularStd => 'Circular Std',
      AppTypography.systemFont => 'System Font',
      AppTypography.custom => 'Personalizada',
    };
  }

  String _getHeaderWeightName(HeaderWeight weight) {
    return switch (weight) {
      HeaderWeight.thin => 'DELGADA',
      HeaderWeight.light => 'LIGERA',
      HeaderWeight.normal => 'NORMAL',
      HeaderWeight.medium => 'MEDIA',
      HeaderWeight.semiBold => 'SEMI NEGRITA',
      HeaderWeight.bold => 'NEGRITA',
    };
  }

  String _getTransitionName(TransitionEffect effect) {
    return switch (effect) {
      TransitionEffect.zoomOut => 'Zoom Out',
      TransitionEffect.fade => 'Fundido',
      TransitionEffect.rotate => 'Girar',
      TransitionEffect.smallScale => 'Small Scale',
      TransitionEffect.cards => 'Cards',
      TransitionEffect.slide => 'Slide',
      TransitionEffect.flip => 'Flip',
    };
  }

  Future<void> _showTokenDialog(
    BuildContext context,
    WidgetRef ref,
    String currentToken,
  ) async {
    final controller = TextEditingController(text: currentToken);
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
      ref.read(customizationProvider.notifier).setGeniusToken(newToken);
    }
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
