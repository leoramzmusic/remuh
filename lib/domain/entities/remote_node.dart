enum RemoteNodeType { folder, file }

class RemoteNode {
  final String id;
  final String parentId;
  final String name;
  final String path;
  final RemoteNodeType type;
  final String? extension;
  final int? size; // in bytes

  RemoteNode({
    required this.id,
    required this.parentId,
    required this.name,
    required this.path,
    required this.type,
    this.extension,
    this.size,
  });

  bool get isAudio =>
      type == RemoteNodeType.file &&
      [
        '.mp3',
        '.flac',
        '.wav',
        '.aac',
        '.ogg',
        '.m4a',
      ].contains(extension?.toLowerCase());

  RemoteNode copyWith({
    String? id,
    String? parentId,
    String? name,
    String? path,
    RemoteNodeType? type,
    String? extension,
    int? size,
  }) {
    return RemoteNode(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      extension: extension ?? this.extension,
      size: size ?? this.size,
    );
  }
}
