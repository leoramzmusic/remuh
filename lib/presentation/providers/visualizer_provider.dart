import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart'; // Added for Color and Colors
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_player_provider.dart';
import 'dynamic_color_provider.dart'; // Corrected singular name

enum VisualizerMode { bars, waveform, circle, symmetry, particles, spectrum }

enum VisualizerColorMode {
  red,
  purple,
  blue,
  yellow,
  orange,
  pink,
  custom,
  rainbow,
  album,
}

class VisualizerState {
  final VisualizerMode mode;
  final List<double> amplitudes;
  final bool isActive;
  final double sensitivity;
  final double speed;
  final bool autoMode;
  final VisualizerColorMode colorMode;
  final Color customColor;
  final Color albumColor;
  final double animationTime;

  VisualizerState({
    this.mode = VisualizerMode.bars,
    this.amplitudes = const [],
    this.isActive = false,
    this.sensitivity = 1.0,
    this.speed = 1.0,
    this.autoMode = false,
    this.colorMode = VisualizerColorMode.album,
    this.customColor = Colors.white,
    this.albumColor = Colors.blue,
    this.animationTime = 0.0,
  });

  VisualizerState copyWith({
    VisualizerMode? mode,
    List<double>? amplitudes,
    bool? isActive,
    double? sensitivity,
    double? speed,
    bool? autoMode,
    VisualizerColorMode? colorMode,
    Color? customColor,
    Color? albumColor,
    double? animationTime,
  }) {
    return VisualizerState(
      mode: mode ?? this.mode,
      amplitudes: amplitudes ?? this.amplitudes,
      isActive: isActive ?? this.isActive,
      sensitivity: sensitivity ?? this.sensitivity,
      speed: speed ?? this.speed,
      autoMode: autoMode ?? this.autoMode,
      colorMode: colorMode ?? this.colorMode,
      customColor: customColor ?? this.customColor,
      albumColor: albumColor ?? this.albumColor,
      animationTime: animationTime ?? this.animationTime,
    );
  }
}

class VisualizerNotifier extends StateNotifier<VisualizerState> {
  final Ref _ref;
  Timer? _timer;
  Timer? _autoModeTimer;
  final math.Random _random = math.Random();
  static const String _modeKey = 'visualizer_mode';
  static const String _sensitivityKey = 'visualizer_sensitivity';
  static const String _speedKey = 'visualizer_speed';
  static const String _colorModeKey = 'visualizer_color_mode';
  static const String _customColorKey = 'visualizer_custom_color';

  VisualizerNotifier(this._ref) : super(VisualizerState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModeIndex = prefs.getInt(_modeKey);
    final savedSensitivity = prefs.getDouble(_sensitivityKey);
    final savedSpeed = prefs.getDouble(_speedKey);
    final savedColorModeIndex = prefs.getInt(_colorModeKey);
    final savedCustomColorValue = prefs.getInt(_customColorKey);

    if (mounted) {
      state = state.copyWith(
        mode: savedModeIndex != null
            ? VisualizerMode.values[savedModeIndex]
            : VisualizerMode.bars,
        sensitivity: savedSensitivity ?? 1.0,
        speed: savedSpeed ?? 1.0,
        colorMode: savedColorModeIndex != null
            ? VisualizerColorMode.values[savedColorModeIndex]
            : VisualizerColorMode.album,
        customColor: savedCustomColorValue != null
            ? Color(savedCustomColorValue)
            : Colors.white,
      );
    }

    // Listen to playback state to start/stop "simulation"
    _ref.listen(audioPlayerProvider.select((s) => s.isPlaying), (
      previous,
      next,
    ) {
      if (next) {
        _startSimulation();
      } else {
        _stopSimulation();
      }
    });

    // Listen to album colors from dynamicColorProvider
    _ref.listen(dynamicColorsProvider, (previous, next) {
      next.whenData((colors) {
        if (colors.isNotEmpty && mounted) {
          state = state.copyWith(albumColor: colors[0]);
        }
      });
    });

    if (_ref.read(audioPlayerProvider).isPlaying) {
      _startSimulation();
    }
  }

  void setMode(VisualizerMode mode) {
    state = state.copyWith(mode: mode);
    _savePreference(_modeKey, mode.index);
  }

  void setColorMode(VisualizerColorMode mode) {
    state = state.copyWith(colorMode: mode);
    _savePreference(_colorModeKey, mode.index);
  }

  void setCustomColor(Color color) {
    state = state.copyWith(customColor: color);
    _savePreference(_customColorKey, color.toARGB32());
  }

  void setSensitivity(double value) {
    state = state.copyWith(sensitivity: value);
    _savePreference(_sensitivityKey, value);
  }

  void setSpeed(double value) {
    state = state.copyWith(speed: value);
    _savePreference(_speedKey, value);
    if (state.isActive) _startSimulation(); // Restart with new speed
  }

  void toggleAutoMode() {
    state = state.copyWith(autoMode: !state.autoMode);
    if (state.autoMode) {
      _startAutoModeTimer();
    } else {
      _autoModeTimer?.cancel();
    }
  }

  void _startAutoModeTimer() {
    _autoModeTimer?.cancel();
    _autoModeTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!state.autoMode || !mounted) {
        timer.cancel();
        return;
      }
      final nextIndex = (state.mode.index + 1) % VisualizerMode.values.length;
      setMode(VisualizerMode.values[nextIndex]);
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) await prefs.setInt(key, value);
    if (value is double) await prefs.setDouble(key, value);
  }

  void _startSimulation() {
    _timer?.cancel();
    state = state.copyWith(isActive: true);

    // Smooth simulation at 60fps, adjusted by speed settings
    final fps = (60 * state.speed).toInt().clamp(20, 120);
    final interval = Duration(milliseconds: 1000 ~/ fps);

    _timer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final count = switch (state.mode) {
        VisualizerMode.circle => 60,
        VisualizerMode.particles => 40,
        VisualizerMode.spectrum => 64,
        _ => 32,
      };

      final List<double> newAmplitudes = List.generate(count, (index) {
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final base =
            math.sin(time * 5 + index * 0.2) * 0.3 * state.sensitivity + 0.5;
        final noise = _random.nextDouble() * 0.2 * state.sensitivity;
        return (base + noise).clamp(0.05, 1.2);
      });

      // Update animation time for rainbow shader
      final newTime = state.animationTime + (1.0 / fps) * state.speed;

      state = state.copyWith(amplitudes: newAmplitudes, animationTime: newTime);
    });
  }

  void _stopSimulation() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      isActive: false,
      amplitudes: List.filled(state.amplitudes.length, 0.05),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoModeTimer?.cancel();
    super.dispose();
  }
}

final visualizerProvider =
    StateNotifierProvider<VisualizerNotifier, VisualizerState>((ref) {
      return VisualizerNotifier(ref);
    });
