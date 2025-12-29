/// Constantes de la aplicación REMUH
class AppConstants {
  // Información de la aplicación
  static const String appName = 'REMUH';
  static const String appVersion = '1.0.0';

  // Duración de animaciones
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Configuración de UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;

  // Tamaños de iconos
  static const double smallIconSize = 20.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  // Tamaños de iconos de control del reproductor
  static const double controlIconSmall =
      24.0; // Secondary controls (timer, equalizer)
  static const double controlIconMedium = 44.0; // Skip buttons
  static const double controlIconLarge = 64.0; // Play/pause button
}
