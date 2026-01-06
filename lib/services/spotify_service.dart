import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import '../core/utils/logger.dart';
import '../domain/entities/spotify_track.dart';

class SpotifyService {
  // Configuración de la aplicación Spotify (valores de ejemplo, el usuario debe configurarlos)
  static const String clientId = 'YOUR_CLIENT_ID'; // Reemplazar con ID real
  static const String redirectUri = 'remuh://callback';
  static const String scope =
      'playlist-read-private playlist-read-collaborative';

  /// Inicia el flujo de OAuth 2.0
  Future<String?> authenticate() async {
    try {
      final url = Uri.https('accounts.spotify.com', '/authorize', {
        'response_type': 'token',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scope,
      });

      Logger.info('SpotifyService: Launching auth URL: $url');

      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'remuh',
      );

      final token = Uri.parse(
        result.replaceFirst('#', '?'),
      ).queryParameters['access_token'];
      Logger.info('SpotifyService: Token obtained successfully');
      return token;
    } catch (e) {
      Logger.error('SpotifyService: Error during authentication: $e');
      return null;
    }
  }

  /// Obtiene las playlists del usuario
  Future<List<Map<String, dynamic>>> getUserPlaylists(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items']);
      } else {
        Logger.error(
          'SpotifyService: Failed to fetch playlists: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      Logger.error('SpotifyService: Error fetching playlists: $e');
      return [];
    }
  }

  /// Obtiene los tracks de una playlist
  Future<List<SpotifyTrack>> getPlaylistTracks(
    String accessToken,
    String playlistId,
    String playlistName,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'];

        return items.map((item) {
          final track = item['track'];
          final album = track['album'];
          final images = album['images'] as List;

          return SpotifyTrack(
            id: track['id'],
            title: track['name'],
            artist: (track['artists'] as List).map((a) => a['name']).join(', '),
            album: album['name'],
            imageUrl: images.isNotEmpty ? images[0]['url'] : null,
            spotifyId: track['id'],
            playlistName: playlistName,
            dateImported: DateTime.now(),
          );
        }).toList();
      } else {
        Logger.error(
          'SpotifyService: Failed to fetch tracks: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      Logger.error('SpotifyService: Error fetching tracks: $e');
      return [];
    }
  }
}
