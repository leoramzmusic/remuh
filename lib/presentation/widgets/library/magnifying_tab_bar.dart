import 'package:flutter/material.dart';

class MagnifyingTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;
  final Color? selectedColor;
  final Color? unselectedColor;

  const MagnifyingTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = selectedColor ?? theme.colorScheme.primary;
    final inactiveColor = unselectedColor ?? Colors.white54;

    return SizedBox(
      height: preferredSize.height,
      child: AnimatedBuilder(
        animation: controller.animation!,
        builder: (context, child) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(tabs.length, (index) {
                // Calculate distance from current focus [0.0, 1.0]
                double distance = (controller.animation!.value - index).abs();

                // Scale effect (1.3 for active, 0.9 for distant)
                double scale = (1.3 - (distance * 0.4)).clamp(0.9, 1.3);

                // Opacity effect
                double opacity = (1.0 - (distance * 0.5)).clamp(0.4, 1.0);

                // Color lerp
                double colorWeight = (1.0 - distance).clamp(0.0, 1.0);
                Color color = Color.lerp(
                  inactiveColor,
                  activeColor,
                  colorWeight,
                )!;

                return GestureDetector(
                  onTap: () => controller.animateTo(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            shadows: distance < 0.5
                                ? [
                                    Shadow(
                                      color: activeColor.withValues(alpha: 0.3),
                                      blurRadius: 10 * (1 - distance),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
