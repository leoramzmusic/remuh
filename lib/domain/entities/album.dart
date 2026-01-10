import 'track.dart';

class Album {
  final String title;
  final String artist;
  final String? artworkPath;
  final int? year;
  final List<Track> tracks;

  Album({
    required this.title,
    required this.artist,
    this.artworkPath,
    this.year,
    required this.tracks,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Album && other.title == title && other.artist == artist;
  }

  @override
  int get hashCode => Object.hash(title, artist);
}
