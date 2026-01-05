import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/track.dart';
import '../../providers/audio_player_provider.dart';

/// Barra superior del reproductor con navegación y acciones
class PlayerTopBar extends ConsumerWidget {
  final Track? displayedTrack;
  final VoidCallback onShowActions;

  const PlayerTopBar({
    super.key,
    required this.displayedTrack,
    required this.onShowActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackRepo = ref.watch(trackRepositoryProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón de retroceso
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Volver',
            ),

            // Botón de favorito
            if (displayedTrack != null)
              IconButton(
                icon: Icon(
                  displayedTrack!.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: displayedTrack!.isFavorite ? Colors.red : null,
                ),
                onPressed: () async {
                  await trackRepo.toggleFavorite(
                    displayedTrack!.id,
                    !displayedTrack!.isFavorite,
                  );
                  // Actualizar el estado en el reproductor
                  ref.read(audioPlayerProvider.notifier).refreshTrackMetadata(
                    displayedTrack!.id,
                    {'isFavorite': !displayedTrack!.isFavorite},
                  );
                },
                tooltip: displayedTrack!.isFavorite
                    ? 'Quitar de favoritos'
                    : 'Añadir a favoritos',
              ),

            // Botón de menú de opciones
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: onShowActions,
              tooltip: 'Más opciones',
            ),
          ],
        ),
      ),
    );
  }
}
