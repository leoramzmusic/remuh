import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'library_screen.dart';
import 'playlists_screen.dart';
import 'favorites_screen.dart';
import 'equalizer_screen.dart';
import 'visualizer_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/mini_player.dart';
import '../providers/navigation_provider.dart';
import '../widgets/dynamic_blur_background.dart';

/// Main scaffold with bottom navigation
class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    final screens = [
      const LibraryScreen(),
      const PlaylistsScreen(),
      const FavoritesScreen(),
      const EqualizerScreen(),
      const VisualizerScreen(),
    ];

    return DynamicBlurBackground(
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Inherit blurred dynamic background
        drawer: const AppDrawer(),
        body: IndexedStack(index: currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(navigationProvider.notifier).setIndex(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black.withOpacity(0.2), // Subtle contrast
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_rounded),
              label: 'Biblioteca',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.playlist_play_rounded),
              label: 'Playlists',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.equalizer_rounded),
              label: 'Ecualizador',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.graphic_eq_rounded),
              label: 'Visualizador',
            ),
          ],
        ),
        floatingActionButton: const MiniPlayer(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
