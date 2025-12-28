import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/lrc_parser.dart';
import '../../domain/entities/lyric_line.dart';
import 'audio_player_provider.dart';

class LyricsState {
  final List<LyricLine> lines;
  final bool isLoading;
  final String? error;
  final int activeLineIndex;

  LyricsState({
    this.lines = const [],
    this.isLoading = false,
    this.error,
    this.activeLineIndex = -1,
  });

  LyricsState copyWith({
    List<LyricLine>? lines,
    bool? isLoading,
    String? error,
    int? activeLineIndex,
  }) {
    return LyricsState(
      lines: lines ?? this.lines,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeLineIndex: activeLineIndex ?? this.activeLineIndex,
    );
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((
  ref,
) {
  return LyricsNotifier(ref);
});

class LyricsNotifier extends StateNotifier<LyricsState> {
  final Ref _ref;
  String? _currentTrackId;

  LyricsNotifier(this._ref) : super(LyricsState()) {
    // Escuchar el cambio de track para cargar letras
    _ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (
      prev,
      next,
    ) {
      if (next != null && next.id != _currentTrackId) {
        _currentTrackId = next.id;
        _loadLyrics(next.filePath);
      } else if (next == null) {
        state = LyricsState();
      }
    });

    // Escuchar la posición para actualizar la línea activa
    _ref.listen(audioPlayerProvider.select((s) => s.position), (prev, next) {
      if (state.lines.isNotEmpty) {
        _updateActiveLine(next);
      }
    });
  }

  Future<void> _loadLyrics(String trackPath) async {
    state = state.copyWith(isLoading: true, lines: [], activeLineIndex: -1);

    try {
      // Buscar archivo .lrc con el mismo nombre que el track
      final lrcPath = trackPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc');
      final file = File(lrcPath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final lines = LrcParser.parse(content);
        state = state.copyWith(lines: lines, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, lines: []);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _updateActiveLine(Duration position) {
    int index = -1;
    for (int i = 0; i < state.lines.length; i++) {
      if (position >= state.lines[i].startTime) {
        index = i;
      } else {
        break;
      }
    }

    if (index != state.activeLineIndex) {
      state = state.copyWith(activeLineIndex: index);
    }
  }

  /// Guardar/Editar letras (para el editor opcional)
  Future<void> saveLyrics(String trackPath, String content) async {
    try {
      final lrcPath = trackPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc');
      final file = File(lrcPath);
      await file.writeAsString(content);

      final lines = LrcParser.parse(content);
      state = state.copyWith(lines: lines);
    } catch (e) {
      state = state.copyWith(error: 'No se pudo guardar: $e');
    }
  }
}
