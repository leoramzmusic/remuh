import 'package:flutter/material.dart';

/// Colores del sistema REMUH
class AppColors {
  // Prevenir instanciación
  AppColors._();

  // Colores primarios
  static const Color primary = Color(0xFF6366F1); // Índigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Colores de acento
  static const Color accent = Color(0xFFEC4899); // Rosa
  static const Color accentDark = Color(0xFFDB2777);
  static const Color accentLight = Color(0xFFF9A8D4);

  // Colores neutros para tema oscuro
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF252525);
  static const Color darkOnBackground = Color(0xFFE5E5E5);
  static const Color darkOnSurface = Color(0xFFFFFFFF);

  // Colores neutros para tema claro
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF0F0F0F);

  // Colores de estado
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
