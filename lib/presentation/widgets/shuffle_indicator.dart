import 'package:flutter/material.dart';

class ShuffleIndicator extends StatelessWidget {
  final bool isActive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const ShuffleIndicator({
    super.key,
    required this.isActive,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
        : (inactiveColor ?? Colors.white54);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.shuffle_rounded, color: color, size: size),
        if (isActive)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
