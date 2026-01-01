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
        : (inactiveColor ?? Colors.white.withValues(alpha: 0.4));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shuffle_rounded, color: color, size: size),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: size * 0.25,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
