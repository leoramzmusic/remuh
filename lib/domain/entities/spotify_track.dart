/// Entidad que representa una canción importada de Spotify
class SpotifyTrack {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? imageUrl;
  final String spotifyId;
  final String? playlistName;
  final bool isAcquired;
  final DateTime? dateImported;

  const SpotifyTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.imageUrl,
    required this.spotifyId,
    this.playlistName,
    this.isAcquired = false,
    this.dateImported,
  });

  SpotifyTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? imageUrl,
    String? spotifyId,
    String? playlistName,
    bool? isAcquired,
    DateTime? dateImported,
  }) {
    return SpotifyTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      imageUrl: imageUrl ?? this.imageUrl,
      spotifyId: spotifyId ?? this.spotifyId,
      playlistName: playlistName ?? this.playlistName,
      isAcquired: isAcquired ?? this.isAcquired,
      dateImported: dateImported ?? this.dateImported,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'imageUrl': imageUrl,
      'spotifyId': spotifyId,
      'playlistName': playlistName,
      'isAcquired': isAcquired ? 1 : 0,
      'dateImported': dateImported?.millisecondsSinceEpoch,
    };
  }

  factory SpotifyTrack.fromMap(Map<String, dynamic> map) {
    return SpotifyTrack(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String?,
      imageUrl: map['imageUrl'] as String?,
      spotifyId: map['spotifyId'] as String,
      playlistName: map['playlistName'] as String?,
      isAcquired: (map['isAcquired'] as int) == 1,
      dateImported: map['dateImported'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateImported'] as int)
          : null,
    );
  }
}
