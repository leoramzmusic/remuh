import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/color_extraction_service.dart';
import 'audio_player_provider.dart';

final colorExtractionServiceProvider = Provider<ColorExtractionService>((ref) {
  return ColorExtractionService();
});

final dynamicColorsProvider = FutureProvider<List<Color>>((ref) async {
  final currentTrack = ref.watch(
    audioPlayerProvider.select((s) => s.currentTrack),
  );
  final service = ref.watch(colorExtractionServiceProvider);

  if (currentTrack == null) {
    return [Colors.black, Colors.black];
  }

  return service.getBackgroundColors(currentTrack.id);
});
