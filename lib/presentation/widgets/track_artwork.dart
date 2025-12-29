import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';

class TrackArtwork extends ConsumerWidget {
  final String trackId;
  final double size;
  final double borderRadius;
  final IconData? placeholderIcon;

  const TrackArtwork({
    super.key,
    required this.trackId,
    this.size = 50,
    this.borderRadius = 8,
    this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);
    final actualPlaceholder =
        placeholderIcon ?? icons.lyrics; // Usar nota/musica si no se provee

    return QueryArtworkWidget(
      id: int.parse(trackId),
      type: ArtworkType.AUDIO,
      artworkWidth: size,
      artworkHeight: size,
      // 'size' en on_audio_query controla la resolución del bitmap.
      // 200 es el default (thumbnail). Para HD usamos 1000.
      size: size > 100 ? 1000 : 200,
      artworkQuality: size > 100 ? FilterQuality.high : FilterQuality.medium,
      artworkBorder: BorderRadius.circular(borderRadius),
      nullArtworkWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          actualPlaceholder,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
