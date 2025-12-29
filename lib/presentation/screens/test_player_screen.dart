import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';

/// Test player screen - simplified for debugging
class TestPlayerScreen extends ConsumerWidget {
  const TestPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );

    return Scaffold(
      backgroundColor: Colors.blue, // Bright color to test visibility
      appBar: AppBar(
        title: const Text('TEST PLAYER'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'TEST PLAYER SCREEN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentTrack?.title ?? 'No track',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(audioPlayerProvider.notifier).togglePlayPause();
              },
              child: const Text('PLAY/PAUSE'),
            ),
          ],
        ),
      ),
    );
  }
}
