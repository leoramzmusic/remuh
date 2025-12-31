import 'eq_band.dart';

class EqProfile {
  final String name;
  final String description;
  final List<BandDefinition> bands;
  final Map<String, dynamic> metadata;

  EqProfile({
    required this.name,
    this.description = '',
    required this.bands,
    this.metadata = const {},
  });

  EqProfile copyWith({
    String? name,
    String? description,
    List<BandDefinition>? bands,
    Map<String, dynamic>? metadata,
  }) {
    return EqProfile(
      name: name ?? this.name,
      description: description ?? this.description,
      bands: bands ?? this.bands,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'bands': bands.map((b) => b.toJson()).toList(),
    'metadata': metadata,
  };

  factory EqProfile.fromJson(Map<String, dynamic> json) => EqProfile(
    name: json['name'],
    description: json['description'] ?? '',
    bands: (json['bands'] as List)
        .map((b) => BandDefinition.fromJson(b))
        .toList(),
    metadata: json['metadata'] ?? {},
  );

  static EqProfile get flat => EqProfile(
    name: 'Flat',
    description: 'Sonido neutro, sin alteraciones',
    bands: [], // Decided dynamically by the platform
    metadata: {'platformSuggested': true},
  );
}
