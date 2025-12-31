import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/audio_player_provider.dart';
import 'presentation/providers/customization_provider.dart';
import 'presentation/screens/main_scaffold.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.info('Starting REMUH music player...');

  // Attempt to clear cache with delay to avoid SQLITE_BUSY race conditions
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      await DefaultCacheManager().emptyCache();
      Logger.info('Cache cleared successfully');
    } catch (e) {
      Logger.warning('Failed to clear cache: $e');
    }
  });

  AudioPlayerHandler audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.leo.remuh.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );
  } catch (e) {
    Logger.error('Failed to initialize AudioService', e);
    // Initialize a functional handler even if the service binding fails initially
    // so the app UI can still load.
    audioHandler = AudioPlayerHandler();
  }

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
      theme: AppTheme.getLightTheme(
        primaryColor: accentColor,
        typography: customization.typography,
        headerWeight: customization.headerWeight,
      ),
      darkTheme: AppTheme.getDarkTheme(
        primaryColor: accentColor,
        typography: customization.typography,
        headerWeight: customization.headerWeight,
      ),
      themeMode: customization.isLightTheme ? ThemeMode.light : ThemeMode.dark,
      // Pantalla inicial - MainScaffold con navegación
      home: const MainScaffold(),
    );
  }
}
