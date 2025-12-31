import 'package:flutter/material.dart';

class RGBColorPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorApplied;

  const RGBColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorApplied,
  });

  @override
  State<RGBColorPicker> createState() => _RGBColorPickerState();
}

class _RGBColorPickerState extends State<RGBColorPicker> {
  late int _red;
  late int _green;
  late int _blue;

  @override
  void initState() {
    super.initState();
    _red = widget.initialColor.red;
    _green = widget.initialColor.green;
    _blue = widget.initialColor.blue;
  }

  Color get _currentColor => Color.fromARGB(255, _red, _green, _blue);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: const Text(
        'Selecciona un color personalizado',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: _currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Text(
                '#${_red.toRadixString(16).padLeft(2, '0').toUpperCase()}${_green.toRadixString(16).padLeft(2, '0').toUpperCase()}${_blue.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                style: TextStyle(
                  color: _currentColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _RGBRow(
            label: 'Rojo',
            value: _red,
            color: Colors.red,
            onChanged: (val) => setState(() => _red = val),
          ),
          _RGBRow(
            label: 'Verde',
            value: _green,
            color: Colors.green,
            onChanged: (val) => setState(() => _green = val),
          ),
          _RGBRow(
            label: 'Azul',
            value: _blue,
            color: Colors.blue,
            onChanged: (val) => setState(() => _blue = val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onColorApplied(_currentColor);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentColor,
            foregroundColor: _currentColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white,
          ),
          child: const Text('APLICAR'),
        ),
      ],
    );
  }
}

class _RGBRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Function(int) onChanged;

  const _RGBRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            Text(
              value.toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.white10,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
      ],
    );
  }
}
