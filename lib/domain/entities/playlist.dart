class Playlist {
  final int? id;
  final String name;
  final List<String> trackIds;
  final DateTime createdAt;

  Playlist({
    this.id,
    required this.name,
    this.trackIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    int? id,
    String? name,
    List<String>? trackIds,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};
  }

  factory Playlist.fromMap(Map<String, dynamic> map, List<String> trackIds) {
    return Playlist(
      id: map['id'] as int?,
      name: map['name'] as String,
      trackIds: trackIds,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
