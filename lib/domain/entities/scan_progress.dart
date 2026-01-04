class ScanProgress {
  final int processed;
  final int total;
  final double percentage;
  final String? currentItem;
  final String statusMessage;

  ScanProgress({
    required this.processed,
    required this.total,
    required this.percentage,
    this.currentItem,
    this.statusMessage = 'Escaneando...',
  });

  factory ScanProgress.initial() => ScanProgress(
    processed: 0,
    total: 0,
    percentage: 0,
    statusMessage: 'Iniciando...',
  );
}
