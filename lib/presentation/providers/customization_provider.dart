import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/icon_sets.dart';

/// Mapa de nombres de temas a colores
final Map<String, Color> themeColors = {
  'Morado (Default)': const Color(0xFF6366F1),
  'Verde': const Color(0xFF10B981),
  'Rojo': const Color(0xFFEF4444),
  'Blanco': Colors.white,
  'Negro': Colors.black,
  'Naranja': const Color(0xFFF59E0B),
  'Rosa': const Color(0xFFEC4899),
  'Azul': const Color(0xFF3B82F6),
};

class CustomizationState {
  final Color accentColor;
  final String colorName;
  final IconStyle iconStyle;
  final String geniusToken;

  CustomizationState({
    required this.accentColor,
    required this.colorName,
    required this.iconStyle,
    this.geniusToken = '',
  });

  CustomizationState copyWith({
    Color? accentColor,
    String? colorName,
    IconStyle? iconStyle,
    String? geniusToken,
  }) {
    return CustomizationState(
      accentColor: accentColor ?? this.accentColor,
      colorName: colorName ?? this.colorName,
      iconStyle: iconStyle ?? this.iconStyle,
      geniusToken: geniusToken ?? this.geniusToken,
    );
  }
}

class CustomizationNotifier extends StateNotifier<CustomizationState> {
  static const String _colorKey = 'app_accent_color_name';
  static const String _styleKey = 'app_icon_style';
  static const String _geniusKey = 'genius_api_token';

  CustomizationNotifier()
    : super(
        CustomizationState(
          accentColor: themeColors['Morado (Default)']!,
          colorName: 'Morado (Default)',
          iconStyle: IconStyle.material,
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final colorName = prefs.getString(_colorKey) ?? 'Morado (Default)';
    final styleIndex = prefs.getInt(_styleKey) ?? IconStyle.material.index;
    final geniusToken = prefs.getString(_geniusKey) ?? '';

    final accentColor =
        themeColors[colorName] ?? themeColors['Morado (Default)']!;
    final iconStyle = IconStyle.values[styleIndex];

    state = CustomizationState(
      accentColor: accentColor,
      colorName: colorName,
      iconStyle: iconStyle,
      geniusToken: geniusToken,
    );
  }

  Future<void> setColor(String name) async {
    final color = themeColors[name];
    if (color == null) return;

    state = state.copyWith(accentColor: color, colorName: name);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, name);
  }

  Future<void> setIconStyle(IconStyle style) async {
    state = state.copyWith(iconStyle: style);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_styleKey, style.index);
  }

  Future<void> setGeniusToken(String token) async {
    state = state.copyWith(geniusToken: token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geniusKey, token);
  }
}

final customizationProvider =
    StateNotifierProvider<CustomizationNotifier, CustomizationState>((ref) {
      return CustomizationNotifier();
    });
