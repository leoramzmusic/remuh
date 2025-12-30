import 'package:flutter/material.dart';
import '../providers/customization_provider.dart';

class TypographySelectionDialog extends StatelessWidget {
  final AppTypography currentTypography;
  final Function(AppTypography) onTypographySelected;

  const TypographySelectionDialog({
    super.key,
    required this.currentTypography,
    required this.onTypographySelected,
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
                'Seleccione tipo de letra',
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
                itemCount: AppTypography.values.length,
                itemBuilder: (context, index) {
                  final type = AppTypography.values[index];
                  final isSelected = type == currentTypography;
                  final name = _getTypographyName(type);

                  return InkWell(
                    onTap: () {
                      onTypographySelected(type);
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
                                fontWeight: _getFontWeight(type),
                                // Note: In a real app, you would apply the actual font family here
                                // e.g., fontFamily: name,
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
      AppTypography.custom => 'Tipo de letra personalizada',
    };
  }

  FontWeight _getFontWeight(AppTypography type) {
    return switch (type) {
      AppTypography.robotoThin => FontWeight.w100,
      AppTypography.robotoBlack => FontWeight.w900,
      AppTypography.robotoCondensedLight => FontWeight.w300,
      _ => FontWeight.normal,
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
