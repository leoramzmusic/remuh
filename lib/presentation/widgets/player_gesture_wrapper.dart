import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dynamic_color_provider.dart';

class PlayerGestureWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onSwipeUp;
  final VoidCallback? onSwipeDown;

  const PlayerGestureWrapper({
    required this.child,
    required this.onSwipeUp,
    this.onSwipeDown,
    super.key,
  });

  @override
  ConsumerState<PlayerGestureWrapper> createState() =>
      _PlayerGestureWrapperState();
}

class _PlayerGestureWrapperState extends ConsumerState<PlayerGestureWrapper> {
  double _dragOffset = 0.0;
  bool _isDraggingDown = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dynamicColorsAsync = ref.watch(dynamicColorsProvider);
    final backgroundColor = dynamicColorsAsync.maybeWhen(
      data: (colors) => colors[0].withOpacity(0.8),
      orElse: () => Theme.of(context).scaffoldBackgroundColor,
    );

    return Stack(
      children: [
        // Background to prevent black gaps during drag
        Container(color: backgroundColor),

        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dy;
              _isDraggingDown = details.delta.dy > 0;
            });
          },
          onVerticalDragEnd: (details) {
            // Collapsing threshold: 25% of screen height
            if (_isDraggingDown && _dragOffset > screenHeight * 0.25) {
              if (widget.onSwipeDown != null) {
                widget.onSwipeDown!();
              } else {
                Navigator.of(context).pop();
              }
            }
            // Swipe Up threshold: 15% of screen height
            else if (!_isDraggingDown && _dragOffset < -screenHeight * 0.15) {
              widget.onSwipeUp();
              setState(() => _dragOffset = 0.0);
            }
            // Release and snap back
            else {
              setState(() => _dragOffset = 0.0);
            }
          },
          onVerticalDragCancel: () {
            setState(() => _dragOffset = 0.0);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              0,
              _dragOffset.clamp(-150, 150),
              0,
            ),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
