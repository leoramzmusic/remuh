/// Entidad de dominio para una pista de audio
class Track {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final String? artworkPath;
  final String filePath;
  final String? fileUrl;

  const Track({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.artworkPath,
    required this.filePath,
    this.fileUrl,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? artworkPath,
    String? filePath,
    String? fileUrl,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Track && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Track(id: $id, title: $title, artist: $artist)';
}
