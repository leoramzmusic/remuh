abstract class TrackRepository {
  /// Toggle a track's favorite status in the database
  Future<void> toggleFavorite(String trackId, bool isFavorite);

  /// Increment a track's play count in the database
  Future<void> incrementPlayCount(String trackId);

  /// Fetch all track stats from database
  Future<Map<String, TrackStats>> getAllTrackStats();
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
