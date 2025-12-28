import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<List<Playlist>> getAllPlaylists();
  Future<Playlist?> getPlaylistById(int id);
  Future<int> createPlaylist(Playlist playlist);
  Future<void> updatePlaylist(Playlist playlist);
  Future<void> deletePlaylist(int id);

  Future<void> addTrackToPlaylist(int playlistId, String trackId);
  Future<void> removeTrackFromPlaylist(int playlistId, String trackId);
  Future<List<String>> getTrackIdsForPlaylist(int playlistId);
}
