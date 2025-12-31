class BandDefinition {
  final int id;
  final double centerHz;
  final double minGainDb;
  final double maxGainDb;
  final double currentGainDb;

  BandDefinition({
    required this.id,
    required this.centerHz,
    required this.minGainDb,
    required this.maxGainDb,
    required this.currentGainDb,
  });

  BandDefinition copyWith({
    int? id,
    double? centerHz,
    double? minGainDb,
    double? maxGainDb,
    double? currentGainDb,
  }) {
    return BandDefinition(
      id: id ?? this.id,
      centerHz: centerHz ?? this.centerHz,
      minGainDb: minGainDb ?? this.minGainDb,
      maxGainDb: maxGainDb ?? this.maxGainDb,
      currentGainDb: currentGainDb ?? this.currentGainDb,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'centerHz': centerHz,
    'minGainDb': minGainDb,
    'maxGainDb': maxGainDb,
    'currentGainDb': currentGainDb,
  };

  factory BandDefinition.fromJson(Map<String, dynamic> json) => BandDefinition(
    id: json['id'],
    centerHz: json['centerHz'].toDouble(),
    minGainDb: json['minGainDb'].toDouble(),
    maxGainDb: json['maxGainDb'].toDouble(),
    currentGainDb: json['currentGainDb'].toDouble(),
  );
}
