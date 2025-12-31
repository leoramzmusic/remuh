import 'package:flutter/material.dart';
import '../../presentation/providers/customization_provider.dart';
import 'colors.dart';
import 'fonts.dart';

/// Tema de la aplicación REMUH
class AppTheme {
  AppTheme._();

  /// Genera el tema oscuro con un color primario personalizado
  static ThemeData getDarkTheme({
    required Color primaryColor,
    required AppTypography typography,
    required HeaderWeight headerWeight,
  }) {
    final fontFamily = _getFontFamily(typography);
    final hWeight = _getFontWeight(headerWeight);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryColor,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        onSurfaceVariant: Colors.white70,
        error: AppColors.error,
        onError: Colors.white,
        outline: Colors.white24,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      dialogBackgroundColor: AppColors.darkSurface,

      // Tipografía
      fontFamily: fontFamily,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: hWeight,
          color: AppColors.darkOnBackground,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: hWeight,
          color: AppColors.darkOnBackground,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: hWeight,
          color: AppColors.darkOnBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: hWeight,
          color: AppColors.darkOnBackground,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: hWeight,
          color: AppColors.darkOnBackground,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: hWeight,
          color: AppColors.darkOnBackground,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.darkOnBackground,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.darkOnBackground,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.darkOnBackground,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled))
                  return Colors.white10;
                if (states.contains(WidgetState.pressed)) {
                  return primaryColor.withValues(alpha: 0.8);
                }
                return primaryColor;
              }),
            ),
      ),

      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled))
                  return Colors.white30;
                return primaryColor;
              }),
            ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ).copyWith(
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return const BorderSide(color: Colors.white10);
                }
                if (states.contains(WidgetState.pressed)) {
                  return BorderSide(color: primaryColor);
                }
                return const BorderSide(color: Colors.white24);
              }),
            ),
      ),

      // Componentes
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkBackground,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: Colors.white54);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Colors.white54, fontSize: 12);
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: hWeight,
          color: AppColors.darkOnSurface,
          fontFamily: fontFamily,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.darkOnBackground,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: hWeight,
          color: AppColors.darkOnBackground,
          fontFamily: fontFamily,
        ),
      ),

      iconTheme: IconThemeData(color: primaryColor, size: 24),

      // Controles Interactivos
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          if (states.contains(WidgetState.disabled)) return Colors.white24;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.disabled)) return Colors.white12;
          return Colors.white10;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Colors.white70, width: 2),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.white70;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIconColor: primaryColor,
        labelStyle: const TextStyle(color: Colors.white70),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.15),
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
    );
  }

  /// Genera el tema claro con un color primario personalizado
  static ThemeData getLightTheme({
    required Color primaryColor,
    required AppTypography typography,
    required HeaderWeight headerWeight,
  }) {
    final fontFamily = _getFontFamily(typography);
    final hWeight = _getFontWeight(headerWeight);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryColor,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        onSurfaceVariant: Colors.black54,
        error: AppColors.error,
        onError: Colors.white,
        outline: Colors.black12,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      dialogBackgroundColor: AppColors.lightSurface,

      // Tipografía
      fontFamily: fontFamily,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: hWeight,
          color: AppColors.lightOnBackground,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: hWeight,
          color: AppColors.lightOnBackground,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: hWeight,
          color: AppColors.lightOnBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: hWeight,
          color: AppColors.lightOnBackground,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: hWeight,
          color: AppColors.lightOnBackground,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: hWeight,
          color: AppColors.lightOnBackground,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.lightOnBackground,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.lightOnBackground,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.lightOnBackground,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled))
                  return Colors.grey.shade300;
                if (states.contains(WidgetState.pressed)) {
                  return primaryColor.withValues(alpha: 0.8);
                }
                return primaryColor;
              }),
            ),
      ),

      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled))
                  return Colors.grey.shade400;
                return primaryColor;
              }),
            ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ).copyWith(
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return BorderSide(color: Colors.grey.shade200);
                }
                if (states.contains(WidgetState.pressed)) {
                  return BorderSide(color: primaryColor);
                }
                return BorderSide(color: Colors.grey.shade300);
              }),
            ),
      ),

      // Componentes
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.lightSurfaceVariant,
            width: 1,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: Colors.black54);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Colors.black54, fontSize: 12);
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: hWeight,
          color: AppColors.lightOnSurface,
          fontFamily: fontFamily,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.lightOnBackground,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: hWeight,
          color: AppColors.lightOnBackground,
          fontFamily: fontFamily,
        ),
      ),

      iconTheme: IconThemeData(color: primaryColor, size: 24),

      // Controles Interactivos
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          if (states.contains(WidgetState.disabled))
            return Colors.grey.shade300;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.disabled))
            return Colors.grey.shade200;
          return Colors.black12;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: Colors.grey.shade400, width: 2),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.grey.shade600;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.black26,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIconColor: primaryColor,
        labelStyle: TextStyle(color: Colors.grey.shade700),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.1),
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
    );
  }

  static String? _getFontFamily(AppTypography typography) {
    return switch (typography) {
      AppTypography.robotoThin => AppFonts.roboto,
      AppTypography.robotoRegular => AppFonts.roboto,
      AppTypography.robotoBlack => AppFonts.roboto,
      AppTypography.robotoCondensed => AppFonts.robotoCondensed,
      AppTypography.robotoCondensedLight => AppFonts.robotoCondensed,
      AppTypography.robotoSlab => AppFonts.robotoSlab,
      AppTypography.sansation => AppFonts.sansation,
      AppTypography.ptSans => AppFonts.ptSans,
      AppTypography.sourceSans => AppFonts.sourceSans,
      AppTypography.openSans => AppFonts.openSans,
      AppTypography.quicksand => AppFonts.quicksand,
      AppTypography.ubuntu => AppFonts.ubuntu,
      AppTypography.play => AppFonts.play,
      AppTypography.archivoNarrow => AppFonts.archivoNarrow,
      AppTypography.circularStd => AppFonts.circularStd,
      AppTypography.systemFont => AppFonts.system,
      AppTypography.custom => AppFonts.custom,
    };
  }

  static FontWeight _getFontWeight(HeaderWeight weight) {
    return switch (weight) {
      HeaderWeight.thin => FontWeight.w200,
      HeaderWeight.light => FontWeight.w300,
      HeaderWeight.normal => FontWeight.w400,
      HeaderWeight.medium => FontWeight.w500,
      HeaderWeight.semiBold => FontWeight.w600,
      HeaderWeight.bold => FontWeight.w700,
    };
  }
}
