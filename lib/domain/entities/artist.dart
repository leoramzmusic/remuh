import 'track.dart';

class Artist {
  final String name;
  final String? imageUrl;
  final List<Track> tracks;

  Artist({required this.name, this.imageUrl, required this.tracks});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artist && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
