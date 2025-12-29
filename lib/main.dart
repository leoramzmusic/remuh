import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/audio_player_provider.dart';
import 'presentation/providers/customization_provider.dart';
import 'presentation/screens/player_screen.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.info('Starting REMUH music player...');

  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.remuh.remuh.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
      child: const RemuhApp(),
    ),
  );
}

class RemuhApp extends ConsumerWidget {
  const RemuhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final accentColor = customization.accentColor;

    return MaterialApp(
      title: 'REMUH',
      debugShowCheckedModeBanner: false,

      // Temas dinámicos
      theme: AppTheme.getLightTheme(accentColor),
      darkTheme: AppTheme.getDarkTheme(accentColor),
      themeMode: ThemeMode.system, // Seguir configuración del sistema
      // Pantalla inicial
      home: const PlayerScreen(),
    );
  }
}
