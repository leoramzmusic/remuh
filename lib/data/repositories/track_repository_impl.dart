import 'package:sqflite/sqflite.dart';
import '../../domain/repositories/track_repository.dart';
import '../../services/database_service.dart';

class TrackRepositoryImpl implements TrackRepository {
  final DatabaseService _dbService;

  TrackRepositoryImpl(this._dbService);

  @override
  Future<void> toggleFavorite(String trackId, bool isFavorite) async {
    final db = await _dbService.database;
    await db.insert('track_stats', {
      'trackId': trackId,
      'isFavorite': isFavorite ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> incrementPlayCount(String trackId) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Use ignore to handle the case where it might already exist but query missed it
      // or to ensure we have a row to update.
      await txn.insert('track_stats', {
        'trackId': trackId,
        'playCount': 0,
        'lastPlayedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.rawUpdate(
        'UPDATE track_stats SET playCount = playCount + 1, lastPlayedAt = ? WHERE trackId = ?',
        [now, trackId],
      );
    });
  }

  @override
  Future<Map<String, TrackStats>> getAllTrackStats() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('track_stats');

    return Map.fromEntries(
      maps.map(
        (map) => MapEntry(
          map['trackId'] as String,
          TrackStats(
            isFavorite: (map['isFavorite'] as int) == 1,
            playCount: map['playCount'] as int,
            lastPlayedAt: map['lastPlayedAt'] != null
                ? DateTime.parse(map['lastPlayedAt'] as String)
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> updateTrackMetadata(
    String trackId,
    Map<String, dynamic> metadata,
  ) async {
    final db = await _dbService.database;
    final row = Map<String, dynamic>.from(metadata);
    row['trackId'] = trackId;

    await db.insert(
      'track_overrides',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getAllTrackOverrides() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('track_overrides');

    return {for (var map in maps) map['trackId'] as String: map};
  }

  @override
  Future<void> deleteTrackData(String trackId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete(
        'track_stats',
        where: 'trackId = ?',
        whereArgs: [trackId],
      );
      await txn.delete(
        'track_overrides',
        where: 'trackId = ?',
        whereArgs: [trackId],
      );
      await txn.delete(
        'playlist_tracks',
        where: 'trackId = ?',
        whereArgs: [trackId],
      );
    });
  }
}
