import '../entities/spotify_track.dart';

abstract class SpotifyRepository {
  /// Inicia el flujo de autenticación de Spotify
  Future<String?> authenticate();

  /// Obtiene las playlists del usuario autenticado
  Future<List<Map<String, dynamic>>> getUserPlaylists(String accessToken);

  /// Obtiene los tracks de una playlist específica
  Future<List<SpotifyTrack>> getPlaylistTracks(
    String accessToken,
    String playlistId,
    String playlistName,
  );

  /// Guarda una colección de tracks de Spotify en la base de datos local
  Future<void> saveSpotifyTracks(List<SpotifyTrack> tracks);

  /// Obtiene todos los tracks guardados de Spotify
  Future<List<SpotifyTrack>> getAllSavedTracks();

  /// Marca un track como conseguido
  Future<void> markAsAcquired(String spotifyId, bool acquired);

  /// Elimina un track de la lista de pendientes
  Future<void> deleteTrack(String spotifyId);
}
