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
    final selection = _controller.selection;

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      timestamp,
    );

    setState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + timestamp.length,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Letras guardadas')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customization = ref.watch(customizationProvider);
    final icons = AppIconSet.fromStyle(customization.iconStyle);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Letras'),
        actions: [
          IconButton(
            icon: Icon(icons.add),
            onPressed: _save,
          ), // Usamos 'add' o guardamos? AppIconSet no tiene 'save' explícito, usaré icons.lyrics o Icons.save por ahora o añadir 'delete'/'add'
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Text(
              'Reproduce la música y toca el botón para insertar el tiempo actual en la línea seleccionada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Pega aquí la letra y añade tiempos...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _insertTimestamp,
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Insertar Tiempo Actual'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
