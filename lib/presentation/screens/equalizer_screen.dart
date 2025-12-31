import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../viewmodels/equalizer_view_model.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecualizador'),
        actions: [
          Switch(
            value: eqState.isEnabled,
            onChanged: (val) => eqNotifier.toggleEnabled(val),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presets',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: eqState.selectedPreset,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: AppColors.darkSurface,
              isExpanded: true,
              selectedItemBuilder: (context) {
                return eqState.presets.map((preset) {
                  return Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              items: eqState.presets.map((preset) {
                return DropdownMenuItem<String>(
                  value: preset.name,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(preset.name),
                      if (preset.description.isNotEmpty)
                        Text(
                          preset.description,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.white60, fontSize: 10),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                final preset = eqState.presets.firstWhere(
                  (p) => p.name == value,
                );
                eqNotifier.applyPreset(preset);
              },
            ),
            const SizedBox(height: 48),
            Text(
              'Ajuste Manual',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (eqState.bands.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'Obteniendo bandas de audio...',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(equalizerProvider.notifier).retryInit(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: eqState.bands.asMap().entries.map((entry) {
                    final index = entry.key;
                    final band = entry.value;
                    return _BandSlider(
                      index: index,
                      band: band,
                      isEnabled: eqState.isEnabled,
                      onChanged: (val) => eqNotifier.setBandLevel(index, val),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 48),
            Center(
              child: TextButton.icon(
                onPressed: () => eqNotifier.reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Restablecer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Re-implementing _BandSlider here or moving it to a shared file would be better.
// For now, I'll include it here to avoid complex refactoring in one step.
class _BandSlider extends StatelessWidget {
  final int index;
  final dynamic band;
  final bool isEnabled;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.index,
    required this.band,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: band.currentGainDb,
                min: band.minGainDb,
                max: band.maxGainDb,
                onChanged: isEnabled ? onChanged : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _formatFreq(band.centerHz),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isEnabled ? null : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${band.currentGainDb > 0 ? '+' : ''}${band.currentGainDb.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatFreq(double hz) {
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    }
    return '${hz.toInt()}';
  }
}
