import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/icon_sets.dart';

/// Mapa de nombres de temas a colores
final Map<String, Color> themeColors = {
  'Blue Grey': const Color(0xFF607D8B),
  'Cyan': const Color(0xFF00BCD4),
  'Mint': const Color(0xFF3EB489),
  'Light Teal': const Color(0xFF4DB6AC),
  'Teal': const Color(0xFF009688),
  'Blue': const Color(0xFF2196F3),
  'Indigo': const Color(0xFF3F51B5),
  'Purple': const Color(0xFF9C27B0),
  'Pink Red': const Color(0xFFE91E63),
  'Red': const Color(0xFFF44336),
  'Orange': const Color(0xFFFF9800),
  'Gold': const Color(0xFFFFD700),
  'Yellow': const Color(0xFFFFEB3B),
  'Lime Green': const Color(0xFFCDDC39),
  'Green': const Color(0xFF4CAF50),
  'Brown': const Color(0xFF795548),
  'Blanco': Colors.white,
  'Negro': Colors.black,
};

enum AppTypography {
  robotoThin,
  robotoRegular,
  robotoBlack,
  robotoCondensed,
  robotoCondensedLight,
  robotoSlab,
  sansation,
  ptSans,
  sourceSans,
  openSans,
  quicksand,
  ubuntu,
  play,
  archivoNarrow,
  circularStd,
  systemFont,
  custom,
}

enum HeaderWeight { thin, light, normal, medium, semiBold, bold }

enum TransitionEffect { zoomOut, fade, rotate, smallScale, cards, slide, flip }

class CustomizationState {
  final Color accentColor;
  final String colorName;
  final IconStyle iconStyle;
  final String geniusToken;
  final AppTypography typography;
  final HeaderWeight headerWeight;
  final TransitionEffect transitionEffect;
  final bool isLightTheme;
  final bool isTransparentActionBar;
  final bool isAdaptiveBackground;
  final Color customColor;

  CustomizationState({
    required this.accentColor,
    required this.colorName,
    required this.iconStyle,
    this.geniusToken = '',
    this.typography = AppTypography.robotoRegular,
    this.headerWeight = HeaderWeight.bold,
    this.transitionEffect = TransitionEffect.slide,
    this.isLightTheme = false,
    this.isTransparentActionBar = true,
    this.isAdaptiveBackground = true,
    this.customColor = Colors.white,
  });

  CustomizationState copyWith({
    Color? accentColor,
    String? colorName,
    IconStyle? iconStyle,
    String? geniusToken,
    AppTypography? typography,
    HeaderWeight? headerWeight,
    TransitionEffect? transitionEffect,
    bool? isLightTheme,
    bool? isTransparentActionBar,
    bool? isAdaptiveBackground,
    Color? customColor,
  }) {
    return CustomizationState(
      accentColor: accentColor ?? this.accentColor,
      colorName: colorName ?? this.colorName,
      iconStyle: iconStyle ?? this.iconStyle,
      geniusToken: geniusToken ?? this.geniusToken,
      typography: typography ?? this.typography,
      headerWeight: headerWeight ?? this.headerWeight,
      transitionEffect: transitionEffect ?? this.transitionEffect,
      isLightTheme: isLightTheme ?? this.isLightTheme,
      isTransparentActionBar:
          isTransparentActionBar ?? this.isTransparentActionBar,
      isAdaptiveBackground: isAdaptiveBackground ?? this.isAdaptiveBackground,
      customColor: customColor ?? this.customColor,
    );
  }
}

class CustomizationNotifier extends StateNotifier<CustomizationState> {
  static const String _colorKey = 'app_accent_color_name';
  static const String _styleKey = 'app_icon_style';
  static const String _geniusKey = 'genius_api_token';
  static const String _typographyKey = 'app_typography';
  static const String _headerWeightKey = 'app_header_weight';
  static const String _transitionKey = 'app_transition_effect';
  static const String _isLightKey = 'app_is_light_theme';
  static const String _isTransparentKey = 'app_is_transparent_action_bar';
  static const String _isAdaptiveKey = 'app_is_adaptive_background';
  static const String _customColorKey = 'app_custom_accent_color';

  CustomizationNotifier()
    : super(
        CustomizationState(
          accentColor: Colors.white,
          colorName: 'Blanco',
          iconStyle: IconStyle.material,
          typography: AppTypography.robotoRegular,
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final colorName = prefs.getString(_colorKey) ?? 'Blanco';
    final styleIndex = prefs.getInt(_styleKey) ?? IconStyle.material.index;
    final geniusToken = prefs.getString(_geniusKey) ?? '';
    final typographyIndex =
        prefs.getInt(_typographyKey) ?? AppTypography.robotoRegular.index;
    final headerWeightIndex =
        prefs.getInt(_headerWeightKey) ?? HeaderWeight.bold.index;
    final transitionIndex =
        prefs.getInt(_transitionKey) ?? TransitionEffect.slide.index;
    final isLightTheme = prefs.getBool(_isLightKey) ?? false;
    final isTransparent = prefs.getBool(_isTransparentKey) ?? true;
    final isAdaptive = prefs.getBool(_isAdaptiveKey) ?? true;
    final customColorInt = prefs.getInt(_customColorKey) ?? Colors.white.value;

    final customColor = Color(customColorInt);
    final accentColor = colorName == 'Personalizado'
        ? customColor
        : (themeColors[colorName] ?? themeColors['Blanco']!);
    final iconStyle = IconStyle.values[styleIndex];
    final typography = AppTypography.values[typographyIndex];
    final headerWeight = HeaderWeight.values[headerWeightIndex];
    final transition = TransitionEffect.values[transitionIndex];

    state = CustomizationState(
      accentColor: accentColor,
      colorName: colorName,
      iconStyle: iconStyle,
      geniusToken: geniusToken,
      typography: typography,
      headerWeight: headerWeight,
      transitionEffect: transition,
      isLightTheme: isLightTheme,
      isTransparentActionBar: isTransparent,
      isAdaptiveBackground: isAdaptive,
      customColor: customColor,
    );
  }

  Future<void> setColor(String name) async {
    final color = name == 'Personalizado'
        ? state.customColor
        : themeColors[name];
    if (color == null) return;

    state = state.copyWith(accentColor: color, colorName: name);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, name);
  }

  Future<void> setCustomColor(Color color) async {
    state = state.copyWith(
      customColor: color,
      accentColor: color,
      colorName: 'Personalizado',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customColorKey, color.value);
    await prefs.setString(_colorKey, 'Personalizado');
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

  Future<void> setTypography(AppTypography typography) async {
    state = state.copyWith(typography: typography);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_typographyKey, typography.index);
  }

  Future<void> setHeaderWeight(HeaderWeight weight) async {
    state = state.copyWith(headerWeight: weight);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_headerWeightKey, weight.index);
  }

  Future<void> setTransitionEffect(TransitionEffect effect) async {
    state = state.copyWith(transitionEffect: effect);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_transitionKey, effect.index);
  }

  Future<void> setLightTheme(bool value) async {
    state = state.copyWith(isLightTheme: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLightKey, value);
  }

  Future<void> setTransparentActionBar(bool value) async {
    state = state.copyWith(isTransparentActionBar: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isTransparentKey, value);
  }

  Future<void> setAdaptiveBackground(bool value) async {
    state = state.copyWith(isAdaptiveBackground: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdaptiveKey, value);
  }
}

final customizationProvider =
    StateNotifierProvider<CustomizationNotifier, CustomizationState>((ref) {
      return CustomizationNotifier();
    });
