import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/visualizer_provider.dart';

class VisualizerPainterUtils {
  static void setupPaint(
    Paint paint,
    Rect rect,
    VisualizerColorMode mode,
    Color customColor,
    Color albumColor,
    double time,
  ) {
    if (mode == VisualizerColorMode.rainbow) {
      paint.shader = SweepGradient(
        colors: const [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.red,
        ],
        transform: GradientRotation(time),
      ).createShader(rect);
    } else {
      paint.shader = null;
      paint.color = switch (mode) {
        VisualizerColorMode.red => Colors.red,
        VisualizerColorMode.purple => Colors.purple,
        VisualizerColorMode.blue => Colors.blue,
        VisualizerColorMode.yellow => Colors.yellow,
        VisualizerColorMode.orange => Colors.orange,
        VisualizerColorMode.pink => Colors.pinkAccent,
        VisualizerColorMode.custom => customColor,
        VisualizerColorMode.album => albumColor,
        _ => Colors.white,
      };
    }
  }
}

class BarsVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final VisualizerColorMode colorMode;
  final Color customColor;
  final Color albumColor;
  final double animationTime;

  BarsVisualizerPainter({
    required this.amplitudes,
    required this.colorMode,
    required this.customColor,
    required this.albumColor,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;
    VisualizerPainterUtils.setupPaint(
      paint,
      rect,
      colorMode,
      customColor,
      albumColor,
      animationTime,
    );

    final barWidth = size.width / (amplitudes.length * 1.5);
    final spacing = barWidth * 0.5;

    for (int i = 0; i < amplitudes.length; i++) {
      final barHeight = amplitudes[i] * size.height * 0.8;
      final x = i * (barWidth + spacing);
      final y = size.height - barHeight;

      // Draw bars with the paint already set up
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Add a subtle reflection/glow
      final reflectionPaint = Paint()
        ..shader = paint.shader
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height + 2, barWidth, barHeight * 0.3),
          const Radius.circular(4),
        ),
        reflectionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarsVisualizerPainter oldDelegate) => true;
}

class WaveformVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final VisualizerColorMode colorMode;
  final Color customColor;
  final Color albumColor;
  final double animationTime;

  WaveformVisualizerPainter({
    required this.amplitudes,
    required this.colorMode,
    required this.customColor,
    required this.albumColor,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    VisualizerPainterUtils.setupPaint(
      paint,
      rect,
      colorMode,
      customColor,
      albumColor,
      animationTime,
    );

    final path = Path();
    final step = size.width / (amplitudes.length - 1);
    final centerY = size.height / 2;

    path.moveTo(0, centerY);

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * step;
      final yOffset = amplitudes[i] * size.height * 0.4;
      final y = i % 2 == 0 ? centerY - yOffset : centerY + yOffset;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Add a secondary subtle path
    paint.shader =
        null; // Don't use shader for the secondary subtle path to avoid overload
    if (colorMode == VisualizerColorMode.rainbow) {
      paint.color = Colors.white.withValues(alpha: 0.2);
    } else {
      paint.color = paint.color.withValues(alpha: 0.3);
    }
    paint.strokeWidth = 1.5;
    final secondaryPath = Path();
    secondaryPath.moveTo(0, centerY);
    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * step;
      final yOffset = amplitudes[i] * size.height * 0.2;
      final y = i % 2 != 0 ? centerY - yOffset : centerY + yOffset;
      secondaryPath.lineTo(x, y);
    }
    canvas.drawPath(secondaryPath, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformVisualizerPainter oldDelegate) => true;
}

class CircleVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final VisualizerColorMode colorMode;
  final Color customColor;
  final Color albumColor;
  final double animationTime;

  CircleVisualizerPainter({
    required this.amplitudes,
    required this.colorMode,
    required this.customColor,
    required this.albumColor,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    VisualizerPainterUtils.setupPaint(
      paint,
      rect,
      colorMode,
      customColor,
      albumColor,
      animationTime,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.25;
    final angleStep = (2 * math.pi) / amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final angle = i * angleStep;
      final amplitude = amplitudes[i];

      final innerRadius = radius;
      final outerRadius = radius + (amplitude * radius * 1.5);

      final start = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );

      canvas.drawLine(start, end, paint);
    }

    // Draw a center glow
    final glowPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    if (colorMode == VisualizerColorMode.rainbow) {
      glowPaint.color = Colors.white.withValues(alpha: 0.1);
    }
    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CircleVisualizerPainter oldDelegate) => true;
}

class SymmetryVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final VisualizerColorMode colorMode;
  final Color customColor;
  final Color albumColor;
  final double animationTime;

  SymmetryVisualizerPainter({
    required this.amplitudes,
    required this.colorMode,
    required this.customColor,
    required this.albumColor,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..strokeWidth = 2.0;
    VisualizerPainterUtils.setupPaint(
      paint,
      rect,
      colorMode,
      customColor,
      albumColor,
      animationTime,
    );

    final centerY = size.height / 2;
    final step = size.width / amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final double h = amplitudes[i] * size.height * 0.4;
      final double x = i * step;

      // Top bar
      canvas.drawRect(Rect.fromLTWH(x, centerY - h, step * 0.8, h), paint);
      // Bottom reflection
      final originalColor = paint.color;
      if (colorMode != VisualizerColorMode.rainbow) {
        paint.color = originalColor.withValues(alpha: 0.5);
      }
      canvas.drawRect(Rect.fromLTWH(x, centerY, step * 0.8, h), paint);
      paint.color = originalColor;
    }
  }

  @override
  bool shouldRepaint(covariant SymmetryVisualizerPainter oldDelegate) => true;
}

class ParticlesVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final VisualizerColorMode colorMode;
  final Color customColor;
  final Color albumColor;
  final double animationTime;

  ParticlesVisualizerPainter({
    required this.amplitudes,
    required this.colorMode,
    required this.customColor,
    required this.albumColor,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint();
    VisualizerPainterUtils.setupPaint(
      paint,
      rect,
      colorMode,
      customColor,
      albumColor,
      animationTime,
    );

    final particleColor = paint.color;
    final random = math.Random(42);

    for (int i = 0; i < amplitudes.length; i++) {
      final amp = amplitudes[i];
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Vibrate based on amplitude
      final y =
          baseY +
          (math.sin(DateTime.now().millisecondsSinceEpoch * 0.01 + i) *
              amp *
              20);

      final double radius = amp * 5.0 + 1.0;

      // Draw glow
      canvas.drawCircle(
        Offset(x, y),
        radius * 2.5,
        Paint()
          ..color = particleColor.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlesVisualizerPainter oldDelegate) => true;
}

class SpectrumVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final VisualizerColorMode colorMode;
  final Color customColor;
  final Color albumColor;
  final double animationTime;

  SpectrumVisualizerPainter({
    required this.amplitudes,
    required this.colorMode,
    required this.customColor,
    required this.albumColor,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final step = size.width / amplitudes.length;
    final paint = Paint()..style = PaintingStyle.fill;
    VisualizerPainterUtils.setupPaint(
      paint,
      rect,
      colorMode,
      customColor,
      albumColor,
      animationTime,
    );

    final baseColor = paint.color;

    for (int i = 0; i < amplitudes.length; i++) {
      final amp = amplitudes[i];
      final x = i * step;

      if (colorMode != VisualizerColorMode.rainbow) {
        final rectColor = Color.lerp(Colors.black, baseColor, amp) ?? baseColor;
        paint.color = rectColor;
      }

      final double h = amp * size.height;
      canvas.drawRect(Rect.fromLTWH(x, size.height - h, step, h), paint);

      // Top accent
      final accentColor = colorMode == VisualizerColorMode.rainbow
          ? Colors.white
          : baseColor;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h - 2, step, 2),
        Paint()..color = accentColor.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumVisualizerPainter oldDelegate) => true;
}
