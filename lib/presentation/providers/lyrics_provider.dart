import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/lrc_parser.dart';
import '../../domain/entities/lyric_line.dart';
import '../../core/services/lyrics_api_service.dart';
import 'audio_player_provider.dart';
import 'customization_provider.dart';

class LyricsState {
  final List<LyricLine> lines;
  final bool isLoading;
  final String? error;
  final int activeLineIndex;
  final bool isOnline; // Indica si la letra se obtuvo de internet

  LyricsState({
    this.lines = const [],
    this.isLoading = false,
    this.error,
    this.activeLineIndex = -1,
    this.isOnline = false,
  });

  LyricsState copyWith({
    List<LyricLine>? lines,
    bool? isLoading,
    String? error,
    int? activeLineIndex,
    bool? isOnline,
  }) {
    return LyricsState(
      lines: lines ?? this.lines,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeLineIndex: activeLineIndex ?? this.activeLineIndex,
      isOnline: isOnline ?? this.isOnline,
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
    _ref.listen(audioPlayerProvider.select((s) => s.currentTrack), (_, next) {
      if (next != null && next.id != _currentTrackId) {
        _currentTrackId = next.id;
        _loadLyrics(next.filePath, next.title, next.artist);
      } else if (next == null) {
        state = LyricsState();
      }
    });

    // Escuchar la posición para actualizar la línea activa
    _ref.listen(audioPlayerProvider.select((s) => s.position), (_, next) {
      if (state.lines.isNotEmpty) {
        _updateActiveLine(next);
      }
    });
  }

  Future<void> _loadLyrics(
    String trackPath,
    String? title,
    String? artist,
  ) async {
    state = state.copyWith(
      isLoading: true,
      lines: [],
      activeLineIndex: -1,
      isOnline: false,
    );

    try {
      // 1. Intentar buscar archivo local (.lrc)
      final lrcPath = trackPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc');
      final file = File(lrcPath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final lines = LrcParser.parse(content);
        state = state.copyWith(lines: lines, isLoading: false, isOnline: false);
        return;
      }

      // 2. Si no hay local y tenemos meta-datos, buscar online
      if (title != null && artist != null) {
        // Obtener token dinámico de personalización
        final token = _ref.read(customizationProvider).geniusToken;
        final apiService = GeniusApiService(token);

        final onlineLyrics = await apiService.searchLyrics(title, artist);
        if (onlineLyrics != null && onlineLyrics.isNotEmpty) {
          // Convertir texto plano en líneas (sin tiempo específico = estáticas)
          final linesList = onlineLyrics.split('\n').map((text) {
            return LyricLine(startTime: Duration.zero, text: text.trim());
          }).toList();

          state = state.copyWith(
            lines: linesList,
            isLoading: false,
            isOnline: true,
          );

          // 3. Guardar localmente para futuro uso offline (asíncrono)
          saveLyrics(trackPath, onlineLyrics);
          return;
        }
      }

      // 4. Si nada funciona, estado vacío
      state = state.copyWith(isLoading: false, lines: []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _updateActiveLine(Duration position) {
    // Si no tienen tiempo (estáticas), no actualizamos línea activa por posición
    if (state.lines.isEmpty ||
        state.lines.every((l) => l.startTime == Duration.zero)) {
      return;
    }

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

  /// Guardar/Editar letras
  Future<void> saveLyrics(String trackPath, String content) async {
    try {
      final lrcPath = trackPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc');
      final file = File(lrcPath);
      await file.writeAsString(content);

      // Si el track guardado es el actual, actualizamos el estado
      final currentTrack = _ref.read(audioPlayerProvider).currentTrack;
      if (currentTrack != null && currentTrack.filePath == trackPath) {
        final lines = LrcParser.parse(content);
        state = state.copyWith(lines: lines, isOnline: false);
      }
    } catch (e) {
      state = state.copyWith(error: 'No se pudo guardar: $e');
    }
  }
}
