import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/audio_player_provider.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';

/// Botón de play/pause con animación
class PlayPauseButton extends ConsumerWidget {
  final double size;
  final VoidCallback? onPressed;

  const PlayPauseButton({
    super.key,
    this.size = AppConstants.extraLargeIconSize,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);

    return IconButton(
      onPressed:
          onPressed ??
          () {
            ref.read(audioPlayerProvider.notifier).togglePlayPause();
          },
      icon: AnimatedSwitcher(
        duration: AppConstants.shortAnimationDuration,
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isPlaying ? icons.pause : icons.play,
          key: ValueKey(isPlaying),
          size: size,
        ),
      ),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.all(size * 0.4),
        minimumSize: Size(size * 1.5, size * 1.5),
      ),
    );
  }
}
