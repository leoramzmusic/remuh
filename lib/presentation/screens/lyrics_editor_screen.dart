import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/customization_provider.dart';
import '../../core/theme/icon_sets.dart';
import '../../core/constants/app_constants.dart';

class LyricsEditorScreen extends ConsumerStatefulWidget {
  const LyricsEditorScreen({super.key});

  @override
  ConsumerState<LyricsEditorScreen> createState() => _LyricsEditorScreenState();
}

class _LyricsEditorScreenState extends ConsumerState<LyricsEditorScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentLyrics();
  }

  void _loadCurrentLyrics() {
    final lyricsState = ref.read(lyricsProvider);
    if (lyricsState.lines.isNotEmpty) {
      final buffer = StringBuffer();
      for (var line in lyricsState.lines) {
        final m = line.startTime.inMinutes.toString().padLeft(2, '0');
        final s = (line.startTime.inSeconds % 60).toString().padLeft(2, '0');
        final ms = (line.startTime.inMilliseconds % 1000 ~/ 10)
            .toString()
            .padLeft(2, '0');
        buffer.writeln('[$m:$s.$ms] ${line.text}');
      }
      _controller.text = buffer.toString();
    }
  }

  void _insertTimestamp() {
    final position = ref.read(audioPlayerProvider).position;
    final m = position.inMinutes.toString().padLeft(2, '0');
    final s = (position.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (position.inMilliseconds % 1000 ~/ 10).toString().padLeft(
      2,
      '0',
    );

    final timestamp = '[$m:$s.$ms] ';
    final text = _controller.text;
    TextSelection selection = _controller.selection;

    // Si no hay selección válida (ej: el TextField no ha tenido foco), insertar al final
    if (selection.start == -1) {
      selection = TextSelection.collapsed(offset: text.length);
    }

    // Mejorar lógica: si el cursor está en medio de una línea,
    // buscar el inicio de la línea para insertar el tiempo ahí.
    int insertionPos = selection.start;
    if (insertionPos > 0 && text[insertionPos - 1] != '\n') {
      // Retroceder hasta encontrar el inicio de la línea o el principio del texto
      int lineStart = text.lastIndexOf('\n', insertionPos - 1);
      insertionPos = (lineStart == -1) ? 0 : lineStart + 1;
    }

    final newText = text.replaceRange(
      insertionPos,
      selection.end < insertionPos ? insertionPos : selection.end,
      timestamp,
    );

    setState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: insertionPos + timestamp.length,
      );
    });
  }

  Future<void> _save() async {
    final track = ref.read(audioPlayerProvider).currentTrack;
    if (track == null) return;

    await ref
        .read(lyricsProvider.notifier)
        .saveLyrics(track.filePath, _controller.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Letras guardadas correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Letras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 28),
            onPressed: _save,
            tooltip: 'Guardar cambios',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Text(
              'Escucha la música y pulsa el botón para sincronizar la línea actual.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Pega aquí la letra y añade tiempos...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _insertTimestamp,
              icon: const Icon(Icons.timer_outlined, size: 28),
              label: const Text(
                'Insertar Tiempo Actual',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
