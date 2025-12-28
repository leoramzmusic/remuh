import 'package:sqflite/sqflite.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../services/database_service.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final DatabaseService _dbService;

  PlaylistRepositoryImpl(this._dbService);

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('playlists');

    List<Playlist> playlists = [];
    for (var map in maps) {
      final trackIds = await getTrackIdsForPlaylist(map['id'] as int);
      playlists.add(Playlist.fromMap(map, trackIds));
    }
    return playlists;
  }

  @override
  Future<Playlist?> getPlaylistById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final trackIds = await getTrackIdsForPlaylist(id);
      return Playlist.fromMap(maps.first, trackIds);
    }
    return null;
  }

  @override
  Future<int> createPlaylist(Playlist playlist) async {
    final db = await _dbService.database;
    return await db.insert('playlists', playlist.toMap());
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    final db = await _dbService.database;
    await db.update(
      'playlists',
      playlist.toMap(),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  @override
  Future<void> deletePlaylist(int id) async {
    final db = await _dbService.database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addTrackToPlaylist(int playlistId, String trackId) async {
    final db = await _dbService.database;

    // Get current max position
    final result = await db.rawQuery(
      'SELECT MAX(position) as maxPos FROM playlist_tracks WHERE playlistId = ?',
      [playlistId],
    );
    int nextPos = (result.first['maxPos'] as int? ?? -1) + 1;

    await db.insert('playlist_tracks', {
      'playlistId': playlistId,
      'trackId': trackId,
      'position': nextPos,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> removeTrackFromPlaylist(int playlistId, String trackId) async {
    final db = await _dbService.database;
    await db.delete(
      'playlist_tracks',
      where: 'playlistId = ? AND trackId = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  @override
  Future<List<String>> getTrackIdsForPlaylist(int playlistId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.query(
      'playlist_tracks',
      columns: ['trackId'],
      where: 'playlistId = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    return result.map((row) => row['trackId'] as String).toList();
  }
}
