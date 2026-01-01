import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/equalizer_view_model.dart';
import 'equalizer_widgets.dart';

class EqualizerSheet extends ConsumerWidget {
  const EqualizerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Equalizer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: eqState.isEnabled,
                    onChanged: (val) => eqNotifier.toggleEnabled(val),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              EqualizerPresetsDropdown(
                selectedPreset: eqState.selectedPreset,
                presets: eqState.presets,
                onChanged: (value) {
                  if (value == null) return;
                  final preset = eqState.presets.firstWhere(
                    (p) => p.name == value,
                  );
                  eqNotifier.applyPreset(preset);
                },
              ),
              const SizedBox(height: 40),
              // Sliders
              if (eqState.bands.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  height: 240,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: eqState.bands.asMap().entries.map((entry) {
                      final index = entry.key;
                      final band = entry.value;
                      return BandSlider(
                        index: index,
                        band: band,
                        isEnabled: eqState.isEnabled,
                        onChanged: (val) => eqNotifier.setBandLevel(index, val),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
