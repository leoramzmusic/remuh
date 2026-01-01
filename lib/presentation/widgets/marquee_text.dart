import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double height;
  final double speed;
  final Duration pauseAfterRound;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.height = 30.0,
    this.speed = 30.0,
    this.pauseAfterRound = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textPainter = TextPainter(
            text: TextSpan(text: text, style: style),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(minWidth: 0, maxWidth: double.infinity);

          if (textPainter.width <= constraints.maxWidth) {
            return Text(
              text,
              style: style,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          }

          return Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 50.0,
            velocity: speed,
            pauseAfterRound: pauseAfterRound,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(seconds: 1),
            decelerationCurve: Curves.easeOut,
          );
        },
      ),
    );
  }
}
