import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../core/utils/logger.dart';

// Provider para el servicio de sincronización
final lyricsSyncServiceProvider = Provider((ref) => LyricsSyncService());

class LyricsSyncService {
  /// Envía un archivo de audio y el texto de la letra para sincronización automática
  /// Retorna el contenido .lrc sincronizado
  Future<String?> syncLyrics({
    required String audioPath,
    required String lyricsText,
    String language = AppConstants.defaultLyricsLanguage,
    String? apiEndpoint,
  }) async {
    final endpoint = apiEndpoint ?? AppConstants.lyricsSyncApiEndpoint;

    if (endpoint.isEmpty) {
      Logger.warning('Lyrics sync failed: API endpoint not configured');
      return null;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));

      request.fields['text'] = lyricsText;
      request.fields['lang'] = language;

      final audioFile = await http.MultipartFile.fromPath('audio', audioPath);
      request.files.add(audioFile);

      Logger.info('Sending auto-sync request to $apiEndpoint');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Logger.info('Auto-sync successful');
        return response.body;
      } else {
        Logger.error(
          'Auto-sync failed with status: ${response.statusCode}',
          response.body,
        );
        return null;
      }
    } catch (e) {
      Logger.error('Error during auto-sync request', e);
      return null;
    }
  }
}
