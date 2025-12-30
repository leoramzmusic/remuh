import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/lyrics_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/lyrics_sync_service.dart';

class LyricsEditorScreen extends ConsumerStatefulWidget {
  const LyricsEditorScreen({super.key});

  @override
  ConsumerState<LyricsEditorScreen> createState() => _LyricsEditorScreenState();
}

class _LyricsEditorScreenState extends ConsumerState<LyricsEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoadingSync = false;

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

  void _syncNextLine() {
    final position = ref.read(audioPlayerProvider).position;
    final m = position.inMinutes.toString().padLeft(2, '0');
    final s = (position.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (position.inMilliseconds % 1000 ~/ 10).toString().padLeft(
      2,
      '0',
    );
    final timestamp = '[$m:$s.$ms]';

    final text = _controller.text;
    // Split keeping newlines to preserve structure accurately if needed,
    // but standard split is easier.
    final lines = text.split('\n');

    // Regex para detectar si la línea YA empieza con timestamp [00:00.00]
    final regex = RegExp(r'^\s*\[\d{2}:\d{2}\.\d{2}\]');

    int targetIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      // Ignoramos líneas vacías, o sincronizamos? Mejor saltar vacías.
      if (lines[i].trim().isNotEmpty && !regex.hasMatch(lines[i])) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != -1) {
      final oldLine = lines[targetIndex];
      lines[targetIndex] = '$timestamp ${oldLine.trimLeft()}';

      final newText = lines.join('\n');

      setState(() {
        _controller.text = newText;
        // Opcional: Mover scroll/cursor a la siguiente línea
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Todas las líneas están sincronizadas!'),
          ),
        );
      }
    }
  }

  Future<void> _autoSync() async {
    final track = ref.read(audioPlayerProvider).currentTrack;
    if (track == null || _controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carga un track y pega la letra primero')),
      );
      return;
    }

    setState(() => _isLoadingSync = true);

    try {
      final syncService = ref.read(lyricsSyncServiceProvider);
      final syncedLrc = await syncService.syncLyrics(
        audioPath: track.filePath,
        lyricsText: _controller.text,
      );

      if (syncedLrc != null && mounted) {
        setState(() {
          _controller.text = syncedLrc;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Sincronización completada!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error en la sincronización. Verifica la configuración del API Hub.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSync = false);
      }
    }
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingSync ? null : _syncNextLine,
                    icon: const Icon(Icons.touch_app_outlined),
                    label: const Text('Sincronizar (Karaoke)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingSync ? null : _autoSync,
                    icon: _isLoadingSync
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: const Text('Auto-Sync'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
