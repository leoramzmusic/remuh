import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

import '../providers/audio_player_provider.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/progress_bar.dart';
import 'library_screen.dart';

/// Pantalla principal del reproductor
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final currentTrack = playerState.currentTrack;

    return Scaffold(
      appBar: AppBar(
        title: const Text('REMUH'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LibraryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              // TODO: Opciones
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Carátula del álbum (placeholder)
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: currentTrack?.artworkPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                        child: Image.network(
                          currentTrack!.artworkPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderArtwork(context);
                          },
                        ),
                      )
                    : _buildPlaceholderArtwork(context),
              ),

              const SizedBox(height: AppConstants.largePadding * 2),

              // Información de la pista
              Text(
                currentTrack?.title ?? 'Sin pista',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.smallPadding),

              Text(
                currentTrack?.artist ?? 'Artista desconocido',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.largePadding * 2),

              // Barra de progreso
              const ProgressBar(),

              const SizedBox(height: AppConstants.largePadding),

              // Controles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón anterior
                  IconButton(
                    onPressed: playerState.hasPrevious
                        ? () => ref
                              .read(audioPlayerProvider.notifier)
                              .skipToPrevious()
                        : null,
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: AppConstants.largeIconSize,
                  ),

                  const SizedBox(width: AppConstants.defaultPadding),

                  // Botón play/pause
                  const PlayPauseButton(),

                  const SizedBox(width: AppConstants.defaultPadding),

                  // Botón siguiente
                  IconButton(
                    onPressed: playerState.hasNext
                        ? () => ref
                              .read(audioPlayerProvider.notifier)
                              .skipToNext()
                        : null,
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: AppConstants.largeIconSize,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Estado de reproducción
              if (playerState.isBuffering)
                const Padding(
                  padding: EdgeInsets.all(AppConstants.smallPadding),
                  child: CircularProgressIndicator(),
                ),

              if (playerState.hasError)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Text(
                    'Error: ${playerState.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArtwork(BuildContext context) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: 100,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}
