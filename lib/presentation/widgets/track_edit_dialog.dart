import 'package:flutter/material.dart';
import '../../domain/entities/track.dart';

class TrackEditDialog extends StatefulWidget {
  final Track track;
  final Function(Map<String, dynamic>) onSave;

  const TrackEditDialog({super.key, required this.track, required this.onSave});

  @override
  State<TrackEditDialog> createState() => _TrackEditDialogState();
}

class _TrackEditDialogState extends State<TrackEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _artistController = TextEditingController(text: widget.track.artist ?? '');
    _albumController = TextEditingController(text: widget.track.album ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar metadatos'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.music_note_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artista',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(
                labelText: 'Álbum',
                prefixIcon: Icon(Icons.album_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ruta: ${widget.track.filePath}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave({
              'title': _titleController.text,
              'artist': _artistController.text,
              'album': _albumController.text,
            });
            Navigator.pop(context);
          },
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}
