import '../../domain/entities/lyric_line.dart';

class LrcParser {
  /// Parsea un string en formato LRC a una lista de LyricLine.
  /// Formato esperado: [mm:ss.xx] texto
  static List<LyricLine> parse(String lrcContent) {
    if (lrcContent.isEmpty) return [];

    final lines = lrcContent.split('\n');
    final List<LyricLine> lyricLines = [];

    // Regexp para capturar el tiempo [00:00.00] o [00:00:00]
    final timeRegex = RegExp(r'\[(\d{2}):(\d{2})[.:](\d{2,3})\]');

    for (var line in lines) {
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);

        final startTime = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds * (match.group(3)!.length == 2 ? 10 : 1),
        );

        // El texto es todo lo que sigue al match del tiempo
        final text = line.replaceFirst(timeRegex, '').trim();

        if (text.isNotEmpty) {
          lyricLines.add(LyricLine(startTime: startTime, text: text));
        }
      }
    }

    if (lyricLines.isEmpty && lrcContent.trim().isNotEmpty) {
      // Fallback para texto plano (estático)
      return lines
          .where((l) => l.trim().isNotEmpty)
          .map((l) => LyricLine(startTime: Duration.zero, text: l.trim()))
          .toList();
    }

    // Ordenar por tiempo de inicio por seguridad
    lyricLines.sort((a, b) => a.startTime.compareTo(b.startTime));

    return lyricLines;
  }
}
