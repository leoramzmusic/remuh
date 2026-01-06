class Playlist {
  final int? id;
  final String name;
  final String? description;
  final String? coverUrl;
  final List<String> trackIds;
  final DateTime createdAt;
  final bool isSmart;
  final String? smartType;

  Playlist({
    this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.trackIds = const [],
    DateTime? createdAt,
    this.isSmart = false,
    this.smartType,
  }) : createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    String? coverUrl,
    List<String>? trackIds,
    DateTime? createdAt,
    bool? isSmart,
    String? smartType,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
      isSmart: isSmart ?? this.isSmart,
      smartType: smartType ?? this.smartType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map, List<String> trackIds) {
    return Playlist(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      coverUrl: map['coverUrl'] as String?,
      trackIds: trackIds,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isSmart: false,
      smartType: null,
    );
  }
}
