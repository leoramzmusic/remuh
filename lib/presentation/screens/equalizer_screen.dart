import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/track_artwork.dart';
import '../viewmodels/equalizer_view_model.dart';
import '../widgets/equalizer_widgets.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);
    final audioState = ref.watch(audioPlayerProvider);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecualizador'),
        actions: [
          Switch(
            value: eqState.isEnabled,
            onChanged: (val) => eqNotifier.toggleEnabled(val),
          ),
        ],
      ),
      body: isLandscape
          ? _buildLandscapeLayout(context, eqState, eqNotifier, audioState)
          : _buildPortraitLayout(context, eqState, eqNotifier),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    EqualizerState eqState,
    EqualizerViewModel eqNotifier,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPresetsSection(context, eqState, eqNotifier),
          const SizedBox(height: 48),
          _buildManualAdjustSection(context, eqState, eqNotifier),
          const SizedBox(height: 48),
          Center(
            child: TextButton.icon(
              onPressed: () => eqNotifier.reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Restablecer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    EqualizerState eqState,
    EqualizerViewModel eqNotifier,
    AudioPlayerState audioState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Track Info and Presets
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (audioState.currentTrack != null) ...[
                  Row(
                    children: [
                      TrackArtwork(
                        trackId: audioState.currentTrack!.id,
                        size: 64,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audioState.currentTrack!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              audioState.currentTrack!.artist ??
                                  'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
                _buildPresetsSection(context, eqState, eqNotifier),
                const SizedBox(height: 32),
                Material(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => eqNotifier.reset(),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Restablecer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Right Column: Sliders
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: _buildManualAdjustSection(context, eqState, eqNotifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(
    BuildContext context,
    EqualizerState eqState,
    EqualizerViewModel eqNotifier,
  ) {
    return EqualizerPresetsDropdown(
      selectedPreset: eqState.selectedPreset,
      presets: eqState.presets,
      onChanged: (value) {
        if (value == null) return;
        final preset = eqState.presets.firstWhere((p) => p.name == value);
        eqNotifier.applyPreset(preset);
      },
    );
  }

  Widget _buildManualAdjustSection(
    BuildContext context,
    EqualizerState eqState,
    EqualizerViewModel eqNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajuste Manual',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (eqState.bands.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Obteniendo bandas... (Session: ${eqState.audioSessionId ?? 0})',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => eqNotifier.retryInit(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 200, // Slightly reduced height
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: eqState.bands.asMap().entries.map((entry) {
                final index = entry.key;
                final band = entry.value;
                return BandSlider(
                  index: index,
                  band: band,
                  isEnabled: eqState.isEnabled,
                  onChanged: (val) => eqNotifier.setBandLevel(index, val),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
