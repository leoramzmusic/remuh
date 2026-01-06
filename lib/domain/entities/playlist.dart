class Playlist {
  final int? id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? customCover; // For user-selected specific images
  final List<String> trackIds;
  final DateTime createdAt;

  // Smart Playlist properties
  final bool isSmart;
  final String?
  smartType; // 'recent', 'top', 'added', 'genre', 'spotify_pending'
  final bool canBeHidden;
  final bool canBeDeleted;
  final bool isHidden;

  Playlist({
    this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.customCover,
    this.trackIds = const [],
    DateTime? createdAt,
    this.isSmart = false,
    this.smartType,
    this.canBeHidden = true,
    this.canBeDeleted = true,
    this.isHidden = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    String? coverUrl,
    String? customCover,
    List<String>? trackIds,
    DateTime? createdAt,
    bool? isSmart,
    String? smartType,
    bool? canBeHidden,
    bool? canBeDeleted,
    bool? isHidden,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      customCover: customCover ?? this.customCover,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
      isSmart: isSmart ?? this.isSmart,
      smartType: smartType ?? this.smartType,
      canBeHidden: canBeHidden ?? this.canBeHidden,
      canBeDeleted: canBeDeleted ?? this.canBeDeleted,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'customCover': customCover,
      'createdAt': createdAt.toIso8601String(),
      // We don't typically persist 'isSmart' etc if they are generated dynamically,
      // but if we want to persist visibility settings for smart playlists, we might need a way.
      // However, the current logic generates smart playlists in memory.
      // User playlists are persisted.
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map, List<String> trackIds) {
    return Playlist(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      coverUrl: map['coverUrl'] as String?,
      customCover: map['customCover'] as String?,
      trackIds: trackIds,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isSmart: false,
      smartType: null,
      canBeHidden: true,
      canBeDeleted: true,
      isHidden: false,
    );
  }
}
