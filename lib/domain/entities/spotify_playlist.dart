class SpotifyPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int trackCount;
  final bool isFeatured;
  final bool isUserOwned;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.trackCount = 0,
    this.isFeatured = false,
    this.isUserOwned = false,
  });

  factory SpotifyPlaylist.fromJson(
    Map<String, dynamic> json, {
    bool isFeatured = false,
    bool isUserOwned = false,
  }) {
    String? cover;
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      cover = json['images'][0]['url'];
    }

    return SpotifyPlaylist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coverUrl: cover,
      trackCount: json['tracks']?['total'] ?? 0,
      isFeatured: isFeatured,
      isUserOwned: isUserOwned,
    );
  }
}
