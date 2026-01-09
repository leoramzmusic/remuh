enum RemoteSourceType { pc, cloud, nas, custom }

class RemoteSource {
  final String id;
  final String name; // Ej: "PC de Leo", "Google Drive"
  final RemoteSourceType type;
  final String address; // IP, URL, etc.
  final String? username;
  final String? password;
  final bool isConnected;

  RemoteSource({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.username,
    this.password,
    this.isConnected = false,
  });

  RemoteSource copyWith({
    String? id,
    String? name,
    RemoteSourceType? type,
    String? address,
    String? username,
    String? password,
    bool? isConnected,
  }) {
    return RemoteSource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      username: username ?? this.username,
      password: password ?? this.password,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
