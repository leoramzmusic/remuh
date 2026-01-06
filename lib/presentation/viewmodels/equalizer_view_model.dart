import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/eq_band.dart';
import '../../domain/entities/eq_profile.dart';
import '../../services/equalizer_service.dart';
import '../../services/audio_service.dart';
import '../providers/audio_player_provider.dart';

class EqualizerState {
  final bool isEnabled;
  final List<BandDefinition> bands;
  final List<EqProfile> presets;
  final String? selectedPreset;
  final int? audioSessionId;

  EqualizerState({
    this.isEnabled = false,
    this.bands = const [],
    List<EqProfile>? presets,
    this.selectedPreset = 'Flat',
    this.audioSessionId,
  }) : presets = presets ?? EqualizerService.defaultPresets;

  EqualizerState copyWith({
    bool? isEnabled,
    List<BandDefinition>? bands,
    List<EqProfile>? presets,
    String? selectedPreset,
    int? audioSessionId,
  }) {
    return EqualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      bands: bands ?? this.bands,
      presets: presets ?? this.presets,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      audioSessionId: audioSessionId ?? this.audioSessionId,
    );
  }
}

class EqualizerViewModel extends StateNotifier<EqualizerState> {
  final EqualizerService _service;
  final AudioPlayerHandler _audioHandler;
  final Ref _ref;
  bool _isInitializing = false;

  EqualizerViewModel(this._service, this._audioHandler, this._ref)
    : super(EqualizerState()) {
    _init();
  }

  Future<void> _init() async {
    // Initial attempt
    await _tryInitialize();

    // Listen for changes in audioSessionId to re-init if needed
    _ref.listen(audioPlayerProvider.select((s) => s.audioSessionId), (
      previous,
      next,
    ) {
      if (next != null && next != 0 && state.bands.isEmpty) {
        _tryInitialize();
      }
    });

    // Fallback timer if still empty (e.g. some devices take time to report bands even with ID)
    if (state.bands.isEmpty && Platform.isAndroid) {
      _startInitializationTimer();
    }
  }

  Future<void> _tryInitialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final sessionId = _audioHandler.androidAudioSessionId;
      state = state.copyWith(audioSessionId: sessionId);

      if (Platform.isAndroid) {
        if (sessionId != null && sessionId != 0) {
          await _service.init(sessionId);
        } else {
          // Try with 0 as fallback or wait
          await _service.init(0);
        }
      } else if (Platform.isIOS) {
        await _service.init(10);
      }

      final bands = await _service.getBands();
      if (bands.isNotEmpty) {
        state = state.copyWith(
          bands: bands,
          presets: EqualizerService.defaultPresets,
          // Keep equalizer disabled by default - user must manually enable
          isEnabled: false,
        );
      }
    } finally {
      _isInitializing = false;
    }
  }

  Timer? _initTimer;
  void _startInitializationTimer() {
    _initTimer?.cancel();
    _initTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (state.bands.isNotEmpty) {
        timer.cancel();
        return;
      }
      await _tryInitialize();
    });
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    super.dispose();
  }

  void setBandLevel(int index, double gainDb) {
    if (!state.isEnabled) return;

    final newBands = [...state.bands];
    newBands[index] = newBands[index].copyWith(currentGainDb: gainDb);
    state = state.copyWith(bands: newBands, selectedPreset: 'Manual');

    _service.setBandLevel(newBands[index].id, gainDb);
  }

  void applyPreset(EqProfile preset) {
    if (!state.isEnabled || state.bands.isEmpty) return;

    final newBands = state.bands.map((band) {
      double gain = 0.0;

      if (preset.bands.length == state.bands.length) {
        gain = preset.bands[state.bands.indexOf(band)].currentGainDb;
      } else {
        // Linear interpolation for mismatched band counts
        final sortedPresetBands = [...preset.bands]
          ..sort((a, b) => a.centerHz.compareTo(b.centerHz));

        if (band.centerHz <= sortedPresetBands.first.centerHz) {
          gain = sortedPresetBands.first.currentGainDb;
        } else if (band.centerHz >= sortedPresetBands.last.centerHz) {
          gain = sortedPresetBands.last.currentGainDb;
        } else {
          for (int i = 0; i < sortedPresetBands.length - 1; i++) {
            final b1 = sortedPresetBands[i];
            final b2 = sortedPresetBands[i + 1];
            if (band.centerHz >= b1.centerHz && band.centerHz <= b2.centerHz) {
              final t =
                  (band.centerHz - b1.centerHz) / (b2.centerHz - b1.centerHz);
              gain =
                  b1.currentGainDb + t * (b2.currentGainDb - b1.currentGainDb);
              break;
            }
          }
        }
      }

      _service.setBandLevel(band.id, gain);
      return band.copyWith(currentGainDb: gain);
    }).toList();

    state = state.copyWith(bands: newBands, selectedPreset: preset.name);
  }

  Future<void> retryInit() async {
    state = state.copyWith(bands: []); // Clear to show loading
    await _tryInitialize();
  }

  void toggleEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
    // On Android, disabling the EQ object itself is possible,
    // but here we just manage the state in the UI for now.
  }

  void reset() {
    state = state.copyWith(
      bands: state.bands.map((b) {
        _service.setBandLevel(b.id, 0.0);
        return b.copyWith(currentGainDb: 0.0);
      }).toList(),
      selectedPreset: 'Flat',
    );
  }
}

final equalizerServiceProvider = Provider((ref) => EqualizerService());

final equalizerProvider =
    StateNotifierProvider<EqualizerViewModel, EqualizerState>((ref) {
      final service = ref.watch(equalizerServiceProvider);
      final audioHandler = ref.watch(audioHandlerProvider);
      return EqualizerViewModel(service, audioHandler, ref);
    });
