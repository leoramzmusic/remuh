import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/audio_player_provider.dart';

/// Barra de progreso del reproductor
class ProgressBar extends ConsumerWidget {
  const ProgressBar({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '$minutes:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration =
        ref.watch(audioPlayerProvider.select((s) => s.duration)) ??
        Duration.zero;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: duration.inMilliseconds > 0
                ? position.inMilliseconds.toDouble()
                : 0.0,
            min: 0.0,
            max: duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0,
            onChanged: (value) {
              ref
                  .read(audioPlayerProvider.notifier)
                  .seekTo(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal:
                AppConstants.defaultPadding + 8, // Un poco más de margen
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
