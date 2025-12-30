import 'package:flutter/material.dart';
import '../providers/customization_provider.dart';

class HeaderWeightSelectionDialog extends StatelessWidget {
  final HeaderWeight currentWeight;
  final Function(HeaderWeight) onWeightSelected;

  const HeaderWeightSelectionDialog({
    super.key,
    required this.currentWeight,
    required this.onWeightSelected,
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
                'Seleccione el grosor de la letra para los encabezados',
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
                itemCount: HeaderWeight.values.length,
                itemBuilder: (context, index) {
                  final weight = HeaderWeight.values[index];
                  final isSelected = weight == currentWeight;
                  final name = _getHeaderWeightName(weight);

                  return InkWell(
                    onTap: () {
                      onWeightSelected(weight);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[400],
                                fontSize: 16,
                                fontWeight: _getFontWeight(weight),
                              ),
                            ),
                          ),
                          _RadioIndicator(isSelected: isSelected),
                        ],
                      ),
                    ),
                  );
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
                      color: Color(0xFF10B981),
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

  String _getHeaderWeightName(HeaderWeight weight) {
    return switch (weight) {
      HeaderWeight.bold => 'NEGRITA (Bold)',
      HeaderWeight.normal => 'NORMAL [Por defecto]',
      HeaderWeight.light => 'FINA (Delgada)',
    };
  }

  FontWeight _getFontWeight(HeaderWeight weight) {
    return switch (weight) {
      HeaderWeight.bold => FontWeight.bold,
      HeaderWeight.normal => FontWeight.normal,
      HeaderWeight.light => FontWeight.w300,
    };
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;

  const _RadioIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : Colors.grey,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
