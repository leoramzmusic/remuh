import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/audio_player_provider.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';

/// Botón de play/pause con animación
class PlayPauseButton extends ConsumerStatefulWidget {
  final double size;
  final VoidCallback? onPressed;

  const PlayPauseButton({
    super.key,
    this.size = AppConstants.extraLargeIconSize,
    this.onPressed,
  });

  @override
  ConsumerState<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends ConsumerState<PlayPauseButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.9),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.9, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(from: 0);
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      ref.read(audioPlayerProvider.notifier).togglePlayPause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);

    if (isPlaying) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Container(
              width: widget.size * 1.8,
              height: widget.size * 1.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  if (isPlaying)
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.4 * _pulseAnimation.value,
                      ),
                      blurRadius: 15 + (10 * _pulseAnimation.value),
                      spreadRadius: 2 + (5 * _pulseAnimation.value),
                    ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppConstants.mediumAnimationDuration,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    isPlaying ? icons.pause : icons.play,
                    key: ValueKey(isPlaying),
                    size: widget.size * 1.1,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
