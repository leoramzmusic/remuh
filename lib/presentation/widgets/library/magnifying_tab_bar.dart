import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MagnifyingTabBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<MagnifyingTabBar> createState() => _MagnifyingTabBarState();

  @override
  Size get preferredSize => const Size.fromHeight(65);
}

class _MagnifyingTabBarState extends State<MagnifyingTabBar> {
  late ScrollController _scrollController;
  bool _isUserDragging = false;
  double? _dragValue; // The "virtual" animation value during manual drag

  // Constants for calculation
  static const double _avgTabWidth = 100.0; // Approximation for centering

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.controller.animation!.addListener(_handleAnimation);
  }

  @override
  void dispose() {
    widget.controller.animation!.removeListener(_handleAnimation);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAnimation() {
    // Only follow animation if the user is NOT dragging the tab bar manually
    if (!_isUserDragging && _scrollController.hasClients) {
      final double targetOffset =
          widget.controller.animation!.value * _avgTabWidth;

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction != ScrollDirection.idle) {
        setState(() {
          _isUserDragging = true;
        });
      } else {
        // When drag ends, snap to the nearest tab
        _snapToNearest();
      }
    }

    if (_isUserDragging && notification is ScrollUpdateNotification) {
      // Calculate virtual index: offset / avg_width
      // With dynamic padding, the offset 0 corresponds to index 0 centered
      double virtualIndex = _scrollController.offset / _avgTabWidth;

      setState(() {
        _dragValue = virtualIndex.clamp(0.0, widget.tabs.length - 1.0);
      });
    }

    return false;
  }

  void _snapToNearest() {
    if (_dragValue != null) {
      int nearestIndex = _dragValue!.round();
      widget.controller.animateTo(nearestIndex);
    }

    // Smooth reset to auto-sync mode
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isUserDragging = false;
          _dragValue = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.selectedColor ?? theme.colorScheme.primary;
    final inactiveColor = widget.unselectedColor ?? Colors.white54;

    return SizedBox(
      height: widget.preferredSize.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: AnimatedBuilder(
          animation: widget.controller.animation!,
          builder: (context, child) {
            // Use _dragValue if user is dragging, otherwise use TabController animation
            double currentValue = _isUserDragging
                ? (_dragValue ?? widget.controller.animation!.value)
                : widget.controller.animation!.value;

            final double screenWidth = MediaQuery.of(context).size.width;
            final double horizontalPadding =
                (screenWidth / 2) - (_avgTabWidth / 2);

            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(widget.tabs.length, (index) {
                  // Calculate distance from current focus [0.0, 1.0]
                  double distance = (currentValue - index).abs();

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

                  // Dynamic font size with easing
                  double t = (1.0 - distance).clamp(0.0, 1.0);
                  double eased = Curves.easeOut.transform(t);
                  double fontSize = 16 + (4 * eased); // Between 16 and 20

                  return GestureDetector(
                    onTap: () => widget.controller.animateTo(index),
                    child: Container(
                      width:
                          _avgTabWidth, // Fixed width for precise magnetic snapping
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            widget.tabs[index],
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              shadows: distance < 0.5
                                  ? [
                                      Shadow(
                                        color: activeColor.withValues(
                                          alpha: 0.3,
                                        ),
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
      ),
    );
  }
}
