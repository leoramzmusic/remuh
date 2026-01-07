import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/visualizer_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/visualizer_painters.dart';
import 'fullscreen_visualizer.dart';

class VisualizerScreen extends ConsumerWidget {
  const VisualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visualizerState = ref.watch(visualizerProvider);
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [primaryColor.withValues(alpha: 0.15), Colors.black],
                ),
              ),
            ),
          ),

          // Main Visualizer Area
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                final modes = VisualizerMode.values;
                int currentIndex = modes.indexOf(visualizerState.mode);
                if (details.primaryVelocity! < 0) {
                  // Swipe Left -> Next Mode
                  ref
                      .read(visualizerProvider.notifier)
                      .setMode(modes[(currentIndex + 1) % modes.length]);
                } else {
                  // Swipe Right -> Prev Mode
                  ref
                      .read(visualizerProvider.notifier)
                      .setMode(
                        modes[(currentIndex - 1 + modes.length) % modes.length],
                      );
                }
              },
              child: CustomPaint(
                painter: _getPainter(visualizerState),
                size: Size.infinite,
              ),
            ),
          ),

          // Header Info
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            currentTrack?.title ?? 'Silencio',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentTrack?.artist ?? 'REMUH',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FullscreenVisualizer(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () => _showSettings(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mode Indicator
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  visualizerState.mode.name.toUpperCase() +
                      (visualizerState.autoMode ? ' (AUTO)' : ''),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Controls (Minimalist)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeButton(
                    mode: VisualizerMode.bars,
                    currentMode: visualizerState.mode,
                    icon: Icons.bar_chart_rounded,
                  ),
                  _ModeButton(
                    mode: VisualizerMode.waveform,
                    currentMode: visualizerState.mode,
                    icon: Icons.waves_rounded,
                  ),
                  _ModeButton(
                    mode: VisualizerMode.circle,
                    currentMode: visualizerState.mode,
                    icon: Icons.blur_circular_rounded,
                  ),
                  _ModeButton(
                    mode: VisualizerMode.symmetry,
                    currentMode: visualizerState.mode,
                    icon: Icons.unfold_more_rounded,
                  ),
                  _ModeButton(
                    mode: VisualizerMode.particles,
                    currentMode: visualizerState.mode,
                    icon: Icons.grain_rounded,
                  ),
                  _ModeButton(
                    mode: VisualizerMode.spectrum,
                    currentMode: visualizerState.mode,
                    icon: Icons.grid_view_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
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

  void _showSettings(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(visualizerProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentState = ref.watch(visualizerProvider);
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajustes del Visualizador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color Modes
                  const Text(
                    'Color',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _ColorOption(
                          mode: VisualizerColorMode.album,
                          icon: Icons.album_rounded,
                          label: 'Álbum',
                          currentState: currentState,
                          onTap: () =>
                              notifier.setColorMode(VisualizerColorMode.album),
                        ),
                        _ColorOption(
                          mode: VisualizerColorMode.rainbow,
                          icon: Icons.looks_rounded,
                          label: 'Arcoiris',
                          currentState: currentState,
                          onTap: () => notifier.setColorMode(
                            VisualizerColorMode.rainbow,
                          ),
                        ),
                        _ColorOption(
                          mode: VisualizerColorMode.red,
                          color: Colors.red,
                          label: 'Rojo',
                          currentState: currentState,
                          onTap: () =>
                              notifier.setColorMode(VisualizerColorMode.red),
                        ),
                        _ColorOption(
                          mode: VisualizerColorMode.blue,
                          color: Colors.blue,
                          label: 'Azul',
                          currentState: currentState,
                          onTap: () =>
                              notifier.setColorMode(VisualizerColorMode.blue),
                        ),
                        _ColorOption(
                          mode: VisualizerColorMode.purple,
                          color: Colors.purple,
                          label: 'Púrpura',
                          currentState: currentState,
                          onTap: () =>
                              notifier.setColorMode(VisualizerColorMode.purple),
                        ),
                        _ColorOption(
                          mode: VisualizerColorMode.yellow,
                          color: Colors.yellow,
                          label: 'Amarillo',
                          currentState: currentState,
                          onTap: () =>
                              notifier.setColorMode(VisualizerColorMode.yellow),
                        ),
                        _ColorOption(
                          mode: VisualizerColorMode.custom,
                          icon: Icons.palette_rounded,
                          label: 'Personalizado',
                          currentState: currentState,
                          onTap: () =>
                              notifier.setColorMode(VisualizerColorMode.custom),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSettingRow(
                    context,
                    'Sensibilidad',
                    currentState.sensitivity,
                    (v) => notifier.setSensitivity(v),
                    0.5,
                    2.0,
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    context,
                    'Velocidad',
                    currentState.speed,
                    (v) => notifier.setSpeed(v),
                    0.5,
                    2.0,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modo Automático',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Switch(
                        value: currentState.autoMode,
                        onChanged: (v) => notifier.toggleAutoMode(),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
    double min,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Colors.white10,
        ),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  final VisualizerColorMode mode;
  final Color? color;
  final IconData? icon;
  final String label;
  final VisualizerState currentState;
  final VoidCallback onTap;

  const _ColorOption({
    required this.mode,
    this.color,
    this.icon,
    required this.label,
    required this.currentState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentState.colorMode == mode;
    final themeColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? themeColor : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 16,
                color: isSelected ? themeColor : Colors.white70,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends ConsumerWidget {
  final VisualizerMode mode;
  final VisualizerMode currentMode;
  final IconData icon;

  const _ModeButton({
    required this.mode,
    required this.currentMode,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = mode == currentMode;
    final color = Theme.of(context).colorScheme.primary;

    return IconButton(
      icon: Icon(icon),
      color: isActive ? color : Colors.white24,
      iconSize: 28,
      onPressed: () => ref.read(visualizerProvider.notifier).setMode(mode),
    );
  }
}
