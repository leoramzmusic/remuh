/// Constantes relacionadas con audio
class AudioConstants {
  // Extensiones de archivo soportadas
  static const List<String> supportedExtensions = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'opus',
  ];

  // Configuración de buffer
  static const Duration bufferDuration = Duration(seconds: 30);
  static const Duration preloadDuration = Duration(seconds: 5);

  // Configuración de crossfade (para futuros hitos)
  static const Duration defaultCrossfadeDuration = Duration(seconds: 5);
  static const Duration minCrossfadeDuration = Duration(seconds: 3);
  static const Duration maxCrossfadeDuration = Duration(seconds: 10);

  // Intervalos de actualización
  static const Duration positionUpdateInterval = Duration(milliseconds: 200);
}
