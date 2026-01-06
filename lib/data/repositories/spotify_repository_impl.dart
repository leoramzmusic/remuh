import 'package:sqflite/sqflite.dart';
import '../../domain/entities/spotify_track.dart';
import '../../domain/repositories/spotify_repository.dart';
import '../../services/database_service.dart';
import '../../core/utils/logger.dart';

class SpotifyRepositoryImpl implements SpotifyRepository {
  final DatabaseService _dbService;

  SpotifyRepositoryImpl(this._dbService);

  @override
  Future<String?> authenticate() async {
    // This will be implemented in a dedicated Service utilizing flutter_web_auth_2
    throw UnimplementedError('Authentication handled by SpotifyService');
  }

  @override
  Future<List<Map<String, dynamic>>> getUserPlaylists(
    String accessToken,
  ) async {
    throw UnimplementedError('API calls handled by SpotifyService');
  }

  @override
  Future<List<SpotifyTrack>> getPlaylistTracks(
    String accessToken,
    String playlistId,
    String playlistName,
  ) async {
    throw UnimplementedError('API calls handled by SpotifyService');
  }

  @override
  Future<void> saveSpotifyTracks(List<SpotifyTrack> tracks) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (final track in tracks) {
      batch.insert(
        'spotify_tracks',
        track.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    Logger.info('SpotifyRepository: Saved ${tracks.length} tracks to database');
  }

  @override
  Future<List<SpotifyTrack>> getAllSavedTracks() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spotify_tracks',
      orderBy: 'dateImported DESC',
    );

    return List.generate(maps.length, (i) {
      return SpotifyTrack.fromMap(maps[i]);
    });
  }

  @override
  Future<void> markAsAcquired(String spotifyId, bool acquired) async {
    final db = await _dbService.database;
    await db.update(
      'spotify_tracks',
      {'isAcquired': acquired ? 1 : 0},
      where: 'spotifyId = ?',
      whereArgs: [spotifyId],
    );
    Logger.info('SpotifyRepository: Marked $spotifyId as acquired: $acquired');
  }

  @override
  Future<void> deleteTrack(String spotifyId) async {
    final db = await _dbService.database;
    await db.delete(
      'spotify_tracks',
      where: 'spotifyId = ?',
      whereArgs: [spotifyId],
    );
    Logger.info('SpotifyRepository: Deleted Spotify track $spotifyId');
  }
}
