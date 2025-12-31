import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../widgets/track_edit_dialog.dart';
import '../../core/utils/logger.dart';

class TrackContextualMenu {
  static void show(
    BuildContext context,
    WidgetRef ref,
    Track track,
    List<Track> contextTracks,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera con Info
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                title: Text(
                  track.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track.artist ?? 'Artista desconocido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),

              // Acciones de Cola
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Reproducir ahora'),
                onTap: () {
                  Navigator.pop(context);
                  final index = contextTracks.indexOf(track);
                  ref
                      .read(audioPlayerProvider.notifier)
                      .playTrackManually(
                        contextTracks,
                        index != -1 ? index : 0,
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: const Text('Reproducir a continuación'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(audioPlayerProvider.notifier).playNext(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Se reproducirá a continuación'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: const Text('Añadir al final de la cola'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(audioPlayerProvider.notifier).addToEnd(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Añadido al final de la cola'),
                    ),
                  );
                },
              ),

              const Divider(),

              // Navegación
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: const Text('Ir al artista'),
                onTap: () {
                  Navigator.pop(context);
                  // Podríamos navegar aquí si tenemos la pantalla
                  Logger.info('Navegar al artista: ${track.artist}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.album_rounded),
                title: const Text('Ir al álbum'),
                onTap: () {
                  Navigator.pop(context);
                  Logger.info('Navegar al álbum: ${track.album}');
                },
              ),

              // Compartir
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  Logger.info('Compartir track: ${track.title}');
                },
              ),

              const Divider(),

              // Acciones Críticas
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: const Text('Editar metadatos'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => TrackEditDialog(
                      track: track,
                      onSave: (metadata) {
                        ref
                            .read(libraryViewModelProvider.notifier)
                            .editTrack(track.id, metadata);
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                ),
                title: const Text('Eliminar permanentemente'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, ref, track);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Track track,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar canción?'),
        content: Text(
          'Esta acción eliminará permanentemente el archivo:\n\n'
          '"${track.title}"\n\n'
          'No puedes deshacer esta acción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final success = await ref
                  .read(libraryViewModelProvider.notifier)
                  .deleteTrack(track);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Archivo eliminado'
                        : 'No se pudo eliminar el archivo',
                  ),
                ),
              );
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
