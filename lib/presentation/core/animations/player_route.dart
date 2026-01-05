import 'package:flutter/material.dart';
import 'dart:ui';

class PlayerPageRoute extends PageRouteBuilder {
  final Widget page;

  PlayerPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide animation with elastic effect
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                  reverseCurve: Curves.easeInQuart,
                ),
              );

          // Background blur animation
          final blurAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.linear),
            ),
          );

          // Background fade animation
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
            ),
          );

          return Stack(
            children: [
              // Animated background blur and fade
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  if (animation.value == 0) return const SizedBox.shrink();
                  return Opacity(
                    opacity: fadeAnimation.value,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurAnimation.value,
                        sigmaY: blurAnimation.value,
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              ),
              // The sliding page
              SlideTransition(position: slideAnimation, child: child),
            ],
          );
        },
      );
}
