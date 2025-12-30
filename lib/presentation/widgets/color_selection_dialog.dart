import 'package:flutter/material.dart';
import '../providers/customization_provider.dart';

class ColorSelectionDialog extends StatelessWidget {
  final String currentColorName;
  final Function(String) onColorSelected;

  const ColorSelectionDialog({
    super.key,
    required this.currentColorName,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Seleccionar Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: themeColors.length + 1, // +1 for Personalizado
                itemBuilder: (context, index) {
                  if (index < themeColors.length) {
                    final name = themeColors.keys.elementAt(index);
                    final color = themeColors.values.elementAt(index);
                    final isSelected = name == currentColorName;

                    return _ColorItem(
                      color: color,
                      label: name,
                      isSelected: isSelected,
                      onTap: () {
                        onColorSelected(name);
                        Navigator.pop(context);
                      },
                    );
                  } else {
                    return _ColorItem(
                      color: Colors.grey,
                      label: 'Personalizado (Selector RGB)',
                      isSelected: false, // Handle this if needed
                      onTap: () {
                        // For now just show a simple snackbar or placeholder
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selector RGB próximamente'),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: Color(0xFF10B981), // Teal/Green color from image
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorItem({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
            ),
            const SizedBox(width: 24),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
