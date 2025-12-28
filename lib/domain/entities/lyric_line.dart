class LyricLine {
  final Duration startTime;
  final String text;

  LyricLine({required this.startTime, required this.text});

  @override
  String toString() => 'LyricLine(startTime: $startTime, text: $text)';
}
