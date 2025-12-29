import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Servicio para obtener letras de canciones desde la API de Genius.
class GeniusApiService {
  static const String _baseUrl = 'https://api.genius.com';

  // IMPORTANTE: El token debería ser configurado por el usuario o venir de un archivo de config seguro.
  // Por ahora lo dejamos como una variable que el usuario puede inyectar.
  final String _accessToken;

  GeniusApiService(this._accessToken);

  /// Busca la letra de una canción por título y artista.
  /// Retorna un String con el contenido de la letra o null si no se encuentra.
  Future<String?> searchLyrics(String title, String artist) async {
    if (_accessToken.isEmpty) {
      Logger.warning('GeniusApiService: Access Token no proporcionado.');
      return null;
    }

    try {
      final query = Uri.encodeComponent('$title $artist');
      final searchUrl = Uri.parse('$_baseUrl/search?q=$query');

      final response = await http.get(
        searchUrl,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['response']['hits'] as List;

        if (hits.isNotEmpty) {
          // Tomamos el primer resultado (más relevante)
          final songPath = hits[0]['result']['path'];
          final songUrl = 'https://genius.com$songPath';

          // Genius no entrega la letra directamente en el JSON de búsqueda.
          // Debemos obtener el HTML de la página y extraer el contenido.
          return await _extractLyricsFromPage(songUrl);
        }
      }
    } catch (e) {
      Logger.error('Error buscando letras en Genius', e);
    }
    return null;
  }

  /// Extrae el texto de la letra de una página de Genius.
  /// Nota: Genius cambia su estructura a veces. Este scraper busca los contenedores comunes.
  Future<String?> _extractLyricsFromPage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }

      final html = response.body;

      // Buscamos los contenedores de letras (Lyrics__Container) usando Regex
      // Esto es una simplificación básica. Genius usa varios contenedores anidados.
      final regExp = RegExp(
        r'<div data-lyrics-container="true"[^>]*>(.*?)</div>',
        dotAll: true,
      );

      final matches = regExp.allMatches(html);
      if (matches.isEmpty) {
        // Fallback para versiones más viejas/simples del layout
        final oldRegExp = RegExp(
          r'<div class="lyrics"[^>]*>(.*?)</div>',
          dotAll: true,
        );
        final oldMatch = oldRegExp.firstMatch(html);
        if (oldMatch != null) {
          return _cleanLyricsHtml(oldMatch.group(1)!);
        }
        return null;
      }

      final combined = matches.map((m) => m.group(1)).join('\n');
      return _cleanLyricsHtml(combined);
    } catch (e) {
      Logger.error('Error extrayendo letras de la página', e);
      return null;
    }
  }

  /// Limpia el HTML extraído para dejar solo texto plano.
  String _cleanLyricsHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .trim();
  }
}
