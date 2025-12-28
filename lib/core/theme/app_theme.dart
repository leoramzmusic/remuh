import 'package:flutter/material.dart';
import 'colors.dart';

/// Tema de la aplicación REMUH
class AppTheme {
  AppTheme._();

  /// Tema oscuro (por defecto)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurface: AppColors.darkOnSurface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,

    // Tipografía
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkOnBackground,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkOnBackground,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnBackground,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnBackground,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.darkOnBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkOnBackground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.darkOnBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.darkOnBackground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.darkOnBackground,
      ),
    ),

    // Componentes
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnBackground,
      ),
    ),

    iconTheme: const IconThemeData(color: AppColors.darkOnSurface, size: 24),
  );

  /// Tema claro
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.lightSurface,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurface: AppColors.lightOnSurface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,

    // Tipografía
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.lightOnBackground,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.lightOnBackground,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.lightOnBackground,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightOnBackground,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.lightOnBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.lightOnBackground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.lightOnBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.lightOnBackground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.lightOnBackground,
      ),
    ),

    // Componentes
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightSurfaceVariant, width: 1),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightOnBackground,
      ),
    ),

    iconTheme: const IconThemeData(color: AppColors.lightOnSurface, size: 24),
  );
}
