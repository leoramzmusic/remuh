abstract class TrackRepository {
  /// Toggle a track's favorite status in the database
  Future<void> toggleFavorite(String trackId, bool isFavorite);

  /// Increment a track's play count in the database
  Future<void> incrementPlayCount(String trackId);

  /// Fetch all track stats from database
  Future<Map<String, TrackStats>> getAllTrackStats();

  /// Update metadata overrides for a track
  Future<void> updateTrackMetadata(
    String trackId,
    Map<String, dynamic> metadata,
  );

  /// Get all metadata overrides
  Future<Map<String, Map<String, dynamic>>> getAllTrackOverrides();

  /// Delete all data associated with a track (stats, overrides)
  Future<void> deleteTrackData(String trackId);
}

class TrackStats {
  final bool isFavorite;
  final int playCount;
  final DateTime? lastPlayedAt;

  TrackStats({
    required this.isFavorite,
    required this.playCount,
    this.lastPlayedAt,
  });
}
