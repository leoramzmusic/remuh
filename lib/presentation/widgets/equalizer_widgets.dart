import 'package:flutter/material.dart';
import '../../domain/entities/eq_profile.dart';
import '../../core/theme/colors.dart';

class BandSlider extends StatelessWidget {
  final int index;
  final dynamic band;
  final bool isEnabled;
  final ValueChanged<double> onChanged;
  final double height;

  const BandSlider({
    super.key,
    required this.index,
    required this.band,
    required this.isEnabled,
    required this.onChanged,
    this.height = 240,
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

class EqualizerPresetsDropdown extends StatelessWidget {
  final String? selectedPreset;
  final List<EqProfile> presets;
  final ValueChanged<String?> onChanged;

  const EqualizerPresetsDropdown({
    super.key,
    required this.selectedPreset,
    required this.presets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          value: selectedPreset,
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
            return presets.map((preset) {
              return Text(
                preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          items: presets.map((preset) {
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
