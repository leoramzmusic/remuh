import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dynamic_color_provider.dart';

class DynamicBlurBackground extends ConsumerWidget {
  final Widget? child;
  final double blur;
  final double opacity;

  const DynamicBlurBackground({
    super.key,
    this.child,
    this.blur = 20.0,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicColorsAsync = ref.watch(dynamicColorsProvider);
    final dynamicColors = dynamicColorsAsync.maybeWhen(
      data: (colors) => colors,
      orElse: () => [Colors.black, Colors.black],
    );

    return Stack(
      children: [
        // Base dynamic gradient
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                dynamicColors[0].withOpacity(opacity),
                dynamicColors[1].withOpacity(opacity * 0.8),
                Colors.black,
              ],
            ),
          ),
        ),

        // Blur Layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Optional child (e.g., the Scaffold)
        if (child != null) child!,
      ],
    );
  }
}
