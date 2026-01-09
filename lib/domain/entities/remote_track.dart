class RemoteTrack {
  final String id;
  final String sourceId;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final bool isDownloaded;
  final double downloadProgress; // 0.0 to 1.0

  RemoteTrack({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
  });

  RemoteTrack copyWith({
    String? id,
    String? sourceId,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    bool? isDownloaded,
    double? downloadProgress,
  }) {
    return RemoteTrack(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}
