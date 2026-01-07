import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/visualizer_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/visualizer_painters.dart';
import '../widgets/track_artwork.dart';

class FullscreenVisualizer extends ConsumerStatefulWidget {
  const FullscreenVisualizer({super.key});

  @override
  ConsumerState<FullscreenVisualizer> createState() =>
      _FullscreenVisualizerState();
}

class _FullscreenVisualizerState extends ConsumerState<FullscreenVisualizer>
    with SingleTickerProviderStateMixin {
  bool _showOverlay = true;
  Timer? _hideTimer;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Enable immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startHideTimer();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showOverlay = false);
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
    if (_showOverlay) {
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visualizerState = ref.watch(visualizerProvider);
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));

    // Sync rotation with playback state
    if (isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        onDoubleTap: () => Navigator.pop(context),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          final modes = VisualizerMode.values;
          int currentIndex = modes.indexOf(visualizerState.mode);
          if (details.primaryVelocity! < 0) {
            ref
                .read(visualizerProvider.notifier)
                .setMode(modes[(currentIndex + 1) % modes.length]);
          } else {
            ref
                .read(visualizerProvider.notifier)
                .setMode(
                  modes[(currentIndex - 1 + modes.length) % modes.length],
                );
          }
        },
        child: Stack(
          children: [
            // 1. Visualizer Background layer
            Positioned.fill(
              child: CustomPaint(
                painter: _getPainter(visualizerState),
                size: Size.infinite,
              ),
            ),

            // 2. Vinyl Record in the center
            Center(
              child: RotationTransition(
                turns: _rotationController,
                child: _VinylCover(
                  artworkPath: currentTrack?.artworkPath,
                  trackId: currentTrack?.id.toString(),
                ),
              ),
            ),

            // 3. Top Overlay (Track Info)
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 40,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentTrack?.title ?? 'Sin reproducción',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTrack?.artist ?? 'REMUH Music',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Bottom Overlay (Status & Instructions)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'DESLIZA PARA CAMBIAR MODO • DOBLE TOQUE PARA SALIR',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          visualizerState.mode.name.toUpperCase() +
                              (visualizerState.autoMode ? ' (AUTO)' : ''),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter _getPainter(VisualizerState state) {
    return switch (state.mode) {
      VisualizerMode.bars => BarsVisualizerPainter(
        amplitudes: state.amplitudes,
        colorMode: state.colorMode,
        customColor: state.customColor,
        albumColor: state.albumColor,
        animationTime: state.animationTime,
      ),
      VisualizerMode.waveform => WaveformVisualizerPainter(
        amplitudes: state.amplitudes,
        colorMode: state.colorMode,
        customColor: state.customColor,
        albumColor: state.albumColor,
        animationTime: state.animationTime,
      ),
      VisualizerMode.circle => CircleVisualizerPainter(
        amplitudes: state.amplitudes,
        colorMode: state.colorMode,
        customColor: state.customColor,
        albumColor: state.albumColor,
        animationTime: state.animationTime,
      ),
      VisualizerMode.symmetry => SymmetryVisualizerPainter(
        amplitudes: state.amplitudes,
        colorMode: state.colorMode,
        customColor: state.customColor,
        albumColor: state.albumColor,
        animationTime: state.animationTime,
      ),
      VisualizerMode.particles => ParticlesVisualizerPainter(
        amplitudes: state.amplitudes,
        colorMode: state.colorMode,
        customColor: state.customColor,
        albumColor: state.albumColor,
        animationTime: state.animationTime,
      ),
      VisualizerMode.spectrum => SpectrumVisualizerPainter(
        amplitudes: state.amplitudes,
        colorMode: state.colorMode,
        customColor: state.customColor,
        albumColor: state.albumColor,
        animationTime: state.animationTime,
      ),
    };
  }
}

class _VinylCover extends StatelessWidget {
  final String? artworkPath;
  final String? trackId;

  const _VinylCover({this.artworkPath, this.trackId});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.75;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
        gradient: RadialGradient(
          colors: [Colors.grey[900]!, Colors.black],
          stops: const [0.8, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vinyl Grooves (subtle texture)
          ...List.generate(6, (index) {
            return Container(
              width: size * (0.95 - (index * 0.08)),
              height: size * (0.95 - (index * 0.08)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
            );
          }),

          // Album Art using TrackArtwork for consistency
          if (trackId != null)
            TrackArtwork(
              trackId: trackId!,
              artworkPath: artworkPath,
              size: size * 0.45,
              borderRadius: size, // Circular
            )
          else
            const Icon(
              Icons.music_note_rounded,
              color: Colors.white24,
              size: 40,
            ),

          // Center Hub
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Glossy sheen
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
