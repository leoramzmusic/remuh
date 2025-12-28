import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'presentation/screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.info('Starting REMUH music player...');

  runApp(const ProviderScope(child: RemuhApp()));
}

class RemuhApp extends StatelessWidget {
  const RemuhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REMUH',
      debugShowCheckedModeBanner: false,

      // Temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Seguir configuración del sistema
      // Pantalla inicial
      home: const PlayerScreen(),
    );
  }
}
