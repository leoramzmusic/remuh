import 'dart:io';
import 'package:flutter/services.dart';
import '../domain/entities/eq_band.dart';
import '../domain/entities/eq_profile.dart';

class EqualizerService {
  static const _androidChannel = MethodChannel('remuh/eq');
  static const _iosChannel = MethodChannel('remuh/eq_ios');

  MethodChannel get _channel =>
      Platform.isAndroid ? _androidChannel : _iosChannel;

  Future<bool> init(int sessionIdOrBands) async {
    try {
      final bool? success = await _channel.invokeMethod('initEq', {
        if (Platform.isAndroid)
          'sessionId': sessionIdOrBands
        else
          'bands': sessionIdOrBands,
      });
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<BandDefinition>> getBands() async {
    try {
      if (Platform.isAndroid) {
        final List<dynamic>? bands = await _channel.invokeMethod('getBands');
        if (bands == null) return [];
        return bands
            .map(
              (b) => BandDefinition(
                id: b['band'] as int,
                centerHz: (b['centerHz'] as int).toDouble(),
                minGainDb:
                    (b['minMb'] as int).toDouble() / 100, // 100 mB = 1 dB
                maxGainDb: (b['maxMb'] as int).toDouble() / 100,
                currentGainDb: 0.0,
              ),
            )
            .toList();
      } else {
        // iOS doesn't easily return current state from AVAudioUnitEQ via bridge easily
        // so we define 10 default bands and configure them
        final freqs = [
          31.0,
          62.0,
          125.0,
          250.0,
          500.0,
          1000.0,
          2000.0,
          4000.0,
          8000.0,
          16000.0,
        ];
        final bands = List.generate(
          freqs.length,
          (i) => BandDefinition(
            id: i,
            centerHz: freqs[i],
            minGainDb: -12.0,
            maxGainDb: 12.0,
            currentGainDb: 0.0,
          ),
        );

        // Configure them initially on iOS
        for (final band in bands) {
          await _channel.invokeMethod('configureBand', {
            'index': band.id,
            'freq': band.centerHz,
            'gainDb': band.currentGainDb,
            'bw': 1.0, // 1 octave bandwidth
          });
        }
        return bands;
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> setBandLevel(int band, double gainDb) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('setBandLevel', {
          'band': band,
          'levelMb': (gainDb * 100).toInt(),
        });
      } else {
        await _channel.invokeMethod('setGain', {
          'index': band,
          'gainDb': gainDb,
        });
      }
    } catch (e) {
      // Log or ignore
    }
  }

  static List<EqProfile> get defaultPresets => [
    EqProfile(
      name: 'Flat',
      description: 'Sonido neutro, sin alteraciones',
      bands: _createBands([0, 0, 0, 0, 0]),
    ),
    EqProfile(
      name: 'Rock',
      description: 'Fuerza a guitarras eléctricas y batería',
      bands: _createBands([4, 2, 0, 1, 2]),
    ),
    EqProfile(
      name: 'Pop',
      description: 'Resalta voces y brillo moderno',
      bands: _createBands([2, 1, 0, 2, 2]),
    ),
    EqProfile(
      name: 'EDM',
      description: 'Graves profundos y agudos brillantes',
      bands: _createBands([5, 2, 0, 1, 3]),
    ),
    EqProfile(
      name: 'Ballad',
      description: 'Suavidad y claridad vocal',
      bands: _createBands([0, 1, 2, 3, 1]),
    ),
    EqProfile(
      name: 'Country',
      description: 'Realza guitarras acústicas y voces',
      bands: _createBands([2, 3, 1, 2, 1]),
    ),
    EqProfile(
      name: 'Jazz',
      description: 'Claridad en instrumentos acústicos',
      bands: _createBands([2, 1.5, 1, 2.5, 1.5]),
    ),
    EqProfile(
      name: 'Classical',
      description: 'Equilibrio y detalle en cuerdas/vientos',
      bands: _createBands([0, 1, 2, 1, 2.5]),
    ),
    EqProfile(
      name: 'Hip-Hop',
      description: 'Graves potentes y voz clara',
      bands: _createBands([5, 2.5, 0, 1, 2]),
    ),
    EqProfile(
      name: 'Metal',
      description: 'Agresividad en guitarras y batería',
      bands: _createBands([3.5, 2, 1, 3, 2]),
    ),
    EqProfile(
      name: 'Vocal Boost',
      description: 'Máxima claridad en voces o podcasts',
      bands: _createBands([0, 1, 2.5, 3.5, 2]),
    ),
    EqProfile(
      name: 'Ambient',
      description: 'Atmósfera etérea y relajante',
      bands: _createBands([-2, 0, 1.5, 2, 3.5]),
    ),
  ];

  static List<BandDefinition> _createBands(List<double> gains) {
    // This is a helper for 5-band presets, they will be interpolated if more bands exist
    final freqs = [60.0, 230.0, 910.0, 3600.0, 14000.0];
    return List.generate(
      gains.length,
      (i) => BandDefinition(
        id: i,
        centerHz: freqs[i],
        minGainDb: -12.0,
        maxGainDb: 12.0,
        currentGainDb: gains[i],
      ),
    );
  }
}
