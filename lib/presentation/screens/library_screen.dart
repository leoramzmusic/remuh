import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/library_view_model.dart';
import '../providers/library_helpers.dart';
import '../providers/playlists_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/artist_artwork.dart';
import 'entity_detail_screen.dart';
import '../widgets/library/folders_view.dart';
import '../widgets/library/genres_view.dart';
import '../widgets/spotify_view.dart';
import '../widgets/library/network_view.dart';
import '../../domain/entities/playlist.dart';
import '../providers/customization_provider.dart';
import 'player_screen.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/track_contextual_menu.dart';
import '../widgets/marquee_text.dart';
import '../delegates/library_search_delegate.dart';
import '../widgets/library/magnifying_tab_bar.dart';
import '../../core/theme/icon_sets.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Mi Red',
    'Canciones',
    'Álbumes',
    'Artistas',
    'Carpetas',
    'Géneros',
    'Spotify',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryViewModelProvider);

    // Escuchar cambios para mostrar feedback de escaneo
    ref.listen(libraryViewModelProvider, (previous, next) {
      if (previous?.isScanning == true && next.isScanning == false) {
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al escanear: ${next.error}')),
          );
        } else if (next.lastAddedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Se han añadido ${next.lastAddedCount} nuevas canciones!',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else if (previous != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biblioteca actualizada')),
          );
        }
      }
    });

    final iconStyle = ref.watch(
      customizationProvider.select((s) => s.iconStyle),
    );
    final icons = AppIconSet.fromStyle(iconStyle);
    final isGrid = ref.watch(isGridViewProvider);

    return Scaffold(
      drawer: const AppSidebar(),
      appBar: AppBar(
        title: Text(
          'REMUH',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () {
              ref.read(isGridViewProvider.notifier).state = !isGrid;
            },
            tooltip: isGrid ? 'Vista lista' : 'Vista cuadrícula',
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LibrarySearchDelegate(ref),
              );
            },
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: libraryState.isScanning
                ? null
                : () =>
                      ref.read(libraryViewModelProvider.notifier).scanLibrary(),
            tooltip: 'Actualizar biblioteca',
          ),
        ],
        bottom: MagnifyingTabBar(controller: _tabController, tabs: _tabs),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Actualizando tu biblioteca...'),
              duration: Duration(seconds: 2),
            ),
          );
          return ref.read(libraryViewModelProvider.notifier).scanLibrary();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            const NetworkView(),
            _buildTracksList(context, ref, libraryState, icons),
            _buildAlbumsList(context, ref, libraryState, icons),
            _buildArtistsList(context, ref, libraryState, icons),
            const FoldersView(),
            const GenresView(),
            const SpotifyView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    AppIconSet icons,
  ) {
    final tracks = ref.watch(sortedTracksProvider);

    // If we have no tracks and we are NOT scanning, show the empty state
    if (tracks.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref, icons);
    }

    // If we are scanning and have no tracks yet, show a dedicated scanning screen
    if (state.isScanning && tracks.isEmpty) {
      return _buildFullscreenScanningState(context, state);
    }

    // Obtener track actual para resaltar
    final currentTrack = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrack),
    );

    final isGrid = ref.watch(isGridViewProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Play button with current sort label
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final sortOption = ref.watch(sortOptionProvider);
                          final label = getSortLabel(sortOption).toUpperCase();
                          final primaryColor = Theme.of(
                            context,
                          ).colorScheme.primary;

                          return Material(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                final notifier = ref.read(
                                  audioPlayerProvider.notifier,
                                );
                                if (tracks.isNotEmpty) {
                                  notifier.loadPlaylist(tracks, 0);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlayerScreen(),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: MarqueeText(
                                        text: 'REPRODUCIR ($label)',
                                        height: 20,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shuffle button
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isShuffleActive = ref.watch(
                            audioPlayerProvider.select((s) => s.shuffleMode),
                          );
                          final primaryColor = Theme.of(
                            context,
                          ).colorScheme.primary;

                          return Material(
                            color: isShuffleActive
                                ? primaryColor.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                final notifier = ref.read(
                                  audioPlayerProvider.notifier,
                                );
                                int shuffleStartIdx = 0;
                                if (tracks.length > 1) {
                                  shuffleStartIdx = math.Random().nextInt(
                                    tracks.length,
                                  );
                                }
                                final startTrack = tracks[shuffleStartIdx];

                                notifier.loadPlaylist(
                                  tracks,
                                  shuffleStartIdx,
                                  startShuffled: true,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reproducción Aleatoria Activa desde ${startTrack.title}',
                                    ),
                                    backgroundColor: primaryColor,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PlayerScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shuffle,
                                      color: isShuffleActive
                                          ? primaryColor
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ALEATORIO',
                                      style: TextStyle(
                                        color: isShuffleActive
                                            ? primaryColor
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort icon Button
                    Consumer(
                      builder: (context, ref, _) {
                        return PopupMenuButton<SortOption>(
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: Colors.white70,
                          ),
                          onSelected: (option) {
                            ref
                                .read(sortOptionProvider.notifier)
                                .setSortOption(option);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: SortOption.nameAz,
                              child: Text('Ordenar de A-Z'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.nameZa,
                              child: Text('Ordenar de Z-A'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.dateAdded,
                              child: Text('Ordenar por fecha de añadido'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.albumAz,
                              child: Text('Ordenar álbumes A-Z'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.albumZa,
                              child: Text('Ordenar álbumes Z-A'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.artistAz,
                              child: Text('Ordenar artistas A-Z'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.artistZa,
                              child: Text('Ordenar artistas Z-A'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.albumArtistAz,
                              child: Text('Ordenar álbum por artista A-Z'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.albumArtistZa,
                              child: Text('Ordenar álbum por artista Z-A'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.duration,
                              child: Text('Ordenar por duración'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.yearAsc,
                              child: Text('Ordenar por año 0 - 2026'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.yearDesc,
                              child: Text('Ordenar por año 2026 - 0'),
                            ),
                            const PopupMenuItem(
                              value: SortOption.mostPlayed,
                              child: Text('Ordenar por más reproducidas'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress indicator if scanning
                if (state.isScanning && state.scanProgress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.scanProgress!.percentage / 100,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          state.scanProgress!.statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${state.scanProgress!.processed}/${state.scanProgress!.total}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (state.scanProgress!.currentItem != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      state.scanProgress!.currentItem!,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                ] else ...[
                  Text(
                    '${tracks.length} canciones',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: isGrid
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final track = tracks[index];
                    final isActive = currentTrack?.id == track.id;
                    final primaryColor = Theme.of(context).colorScheme.primary;

                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(audioPlayerProvider.notifier)
                            .playTrackManually(tracks, index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlayerScreen(),
                          ),
                        );
                      },
                      onLongPress: () {
                        TrackContextualMenu.show(context, ref, track, tracks);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TrackArtwork(trackId: track.id, size: 200),
                          if (isActive)
                            Container(
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(8, 20, 4, 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          track.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isActive
                                                ? primaryColor
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          track.artist ?? 'Desconocido',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: tracks.length),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final track = tracks[index];
                    final isActive = currentTrack?.id == track.id;
                    final primaryColor = Theme.of(context).colorScheme.primary;

                    return Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? primaryColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isActive
                            ? Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive
                                      ? primaryColor
                                      : Colors.white38,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Hero(
                              tag: 'artwork_${track.id}',
                              child: Stack(
                                children: [
                                  TrackArtwork(
                                    trackId: track.id,
                                    size: 50,
                                    borderRadius: 4,
                                  ),
                                  if (!isActive)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            if (isActive) ...[
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isActive
                                      ? primaryColor
                                      : Colors.white.withValues(alpha: 0.9),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          track.artist ?? 'Desconocido',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive
                                ? primaryColor.withValues(alpha: 0.8)
                                : null,
                          ),
                        ),
                        trailing: _buildPlaylistMenu(
                          context,
                          ref,
                          track,
                          icons,
                        ),
                        onTap: () {
                          ref
                              .read(audioPlayerProvider.notifier)
                              .playTrackManually(tracks, index);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PlayerScreen(),
                            ),
                          );
                        },
                        onLongPress: () {
                          TrackContextualMenu.show(context, ref, track, tracks);
                        },
                      ),
                    );
                  }, childCount: tracks.length),
                ),
        ),
      ],
    );
  }

  Widget _buildArtistsList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    AppIconSet icons,
  ) {
    final artists = ref.watch(sortedArtistsProvider);
    if (artists.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref, icons);
    }

    final isGrid = ref.watch(isGridViewProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Play button with current sort label
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final sortOption = ref.watch(
                            artistSortOptionProvider,
                          );
                          final label = getArtistSortLabel(
                            sortOption,
                          ).toUpperCase();
                          final primaryColor = Theme.of(
                            context,
                          ).colorScheme.primary;

                          return Material(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                final notifier = ref.read(
                                  audioPlayerProvider.notifier,
                                );
                                if (artists.isNotEmpty) {
                                  // Collect all tracks from all artists in current sort order
                                  final allTracks = artists
                                      .expand((a) => a.tracks)
                                      .toList();
                                  notifier.loadPlaylist(allTracks, 0);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlayerScreen(),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: MarqueeText(
                                        text: 'REPRODUCIR ($label)',
                                        height: 20,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shuffle button
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isShuffleActive = ref.watch(
                            audioPlayerProvider.select((s) => s.shuffleMode),
                          );
                          final primaryColor = Theme.of(
                            context,
                          ).colorScheme.primary;

                          return Material(
                            color: isShuffleActive
                                ? primaryColor.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                final notifier = ref.read(
                                  audioPlayerProvider.notifier,
                                );
                                if (artists.isNotEmpty) {
                                  final allTracks = artists
                                      .expand((a) => a.tracks)
                                      .toList();
                                  int shuffleStartIdx = 0;
                                  if (allTracks.length > 1) {
                                    shuffleStartIdx = math.Random().nextInt(
                                      allTracks.length,
                                    );
                                  }

                                  notifier.loadPlaylist(
                                    allTracks,
                                    shuffleStartIdx,
                                    startShuffled: true,
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlayerScreen(),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shuffle,
                                      color: isShuffleActive
                                          ? primaryColor
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ALEATORIO',
                                      style: TextStyle(
                                        color: isShuffleActive
                                            ? primaryColor
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort icon Button
                    Consumer(
                      builder: (context, ref, _) {
                        return PopupMenuButton<ArtistSortOption>(
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: Colors.white70,
                          ),
                          onSelected: (option) {
                            ref
                                .read(artistSortOptionProvider.notifier)
                                .setSortOption(option);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: ArtistSortOption.nameAz,
                              child: Text('Nombre A-Z'),
                            ),
                            const PopupMenuItem(
                              value: ArtistSortOption.nameZa,
                              child: Text('Nombre Z-A'),
                            ),
                            const PopupMenuItem(
                              value: ArtistSortOption.mostPlayed,
                              child: Text('Más escuchados'),
                            ),
                            const PopupMenuItem(
                              value: ArtistSortOption.trackCount,
                              child: Text('Número de pistas'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${artists.length} artistas',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: isGrid
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final artist = artists[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EntityDetailScreen(
                              title: artist.name,
                              tracks: artist.tracks,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ArtistArtwork(
                            key: ValueKey('artist_art_grid_${artist.name}'),
                            artistName: artist.name,
                            size: 200, // Large enough for the square
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(8, 20, 4, 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          artist.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          '${artist.tracks.length} pistas',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: artists.length),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final artist = artists[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: ArtistArtwork(
                        key: ValueKey('artist_art_${artist.name}'),
                        artistName: artist.name,
                        size: 55,
                      ),
                      title: Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${artist.tracks.length} pistas',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EntityDetailScreen(
                              title: artist.name,
                              tracks: artist.tracks,
                            ),
                          ),
                        );
                      },
                    );
                  }, childCount: artists.length),
                ),
        ),
      ],
    );
  }

  Widget _buildAlbumsList(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    AppIconSet icons,
  ) {
    final albums = ref.watch(sortedAlbumsProvider);
    if (albums.isEmpty && !state.isScanning) {
      return _buildEmptyState(ref, icons);
    }

    final isGrid = ref.watch(isGridViewProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Play button with current sort label
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final sortOption = ref.watch(albumSortOptionProvider);
                          final label = getAlbumSortLabel(
                            sortOption,
                          ).toUpperCase();
                          final primaryColor = Theme.of(
                            context,
                          ).colorScheme.primary;

                          return Material(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                final notifier = ref.read(
                                  audioPlayerProvider.notifier,
                                );
                                if (albums.isNotEmpty) {
                                  // Collect all tracks from all albums in current sort order
                                  final allTracks = albums
                                      .expand((a) => a.tracks)
                                      .toList();
                                  notifier.loadPlaylist(allTracks, 0);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlayerScreen(),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: MarqueeText(
                                        text: 'REPRODUCIR ($label)',
                                        height: 20,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shuffle button
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isShuffleActive = ref.watch(
                            audioPlayerProvider.select((s) => s.shuffleMode),
                          );
                          final primaryColor = Theme.of(
                            context,
                          ).colorScheme.primary;

                          return Material(
                            color: isShuffleActive
                                ? primaryColor.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                final notifier = ref.read(
                                  audioPlayerProvider.notifier,
                                );
                                if (albums.isNotEmpty) {
                                  final allTracks = albums
                                      .expand((a) => a.tracks)
                                      .toList();
                                  int shuffleStartIdx = 0;
                                  if (allTracks.length > 1) {
                                    shuffleStartIdx = math.Random().nextInt(
                                      allTracks.length,
                                    );
                                  }

                                  notifier.loadPlaylist(
                                    allTracks,
                                    shuffleStartIdx,
                                    startShuffled: true,
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PlayerScreen(),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shuffle,
                                      color: isShuffleActive
                                          ? primaryColor
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ALEATORIO',
                                      style: TextStyle(
                                        color: isShuffleActive
                                            ? primaryColor
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort icon Button
                    Consumer(
                      builder: (context, ref, _) {
                        return PopupMenuButton<AlbumSortOption>(
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: Colors.white70,
                          ),
                          onSelected: (option) {
                            ref
                                .read(albumSortOptionProvider.notifier)
                                .setSortOption(option);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: AlbumSortOption.titleAsc,
                              child: Text('Título A-Z'),
                            ),
                            const PopupMenuItem(
                              value: AlbumSortOption.titleDesc,
                              child: Text('Título Z-A'),
                            ),
                            const PopupMenuItem(
                              value: AlbumSortOption.artistAz,
                              child: Text('Artista A-Z'),
                            ),
                            const PopupMenuItem(
                              value: AlbumSortOption.yearDesc,
                              child: Text('Año (Reciente primero)'),
                            ),
                            const PopupMenuItem(
                              value: AlbumSortOption.yearAsc,
                              child: Text('Año (Antiguo primero)'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${albums.length} álbumes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: isGrid
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final album = albums[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EntityDetailScreen(
                              title: album.title,
                              tracks: album.tracks,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TrackArtwork(
                            trackId: album.tracks.first.id,
                            artworkPath: album.artworkPath,
                            size: 200,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(8, 20, 4, 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          album.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          album.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: albums.length),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final album = albums[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 55,
                        height: 55,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: TrackArtwork(
                            trackId: album.tracks.first.id,
                            artworkPath: album.artworkPath,
                            size: 55,
                          ),
                        ),
                      ),
                      title: Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EntityDetailScreen(
                              title: album.title,
                              tracks: album.tracks,
                            ),
                          ),
                        );
                      },
                    );
                  }, childCount: albums.length),
                ),
        ),
      ],
    );
  }

  Widget _buildPlaylistMenu(
    BuildContext context,
    WidgetRef ref,
    dynamic track,
    AppIconSet icons,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final playlistsProviderState = ref.watch(playlistsProvider);
        return PopupMenuButton<int>(
          icon: Icon(icons.add),
          onSelected: (playlistId) {
            ref
                .read(playlistsProvider.notifier)
                .addTrackToPlaylist(playlistId, track.id);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Añadido a la lista')));
          },
          itemBuilder: (context) {
            final playlists = playlistsProviderState.maybeWhen(
              data: (p) => p,
              orElse: () => <Playlist>[],
            );
            return playlists.map((Playlist p) {
              return PopupMenuItem<int>(value: p.id ?? 0, child: Text(p.name));
            }).toList();
          },
        );
      },
    );
  }

  Widget _buildFullscreenScanningState(
    BuildContext context,
    LibraryState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 32),
            Text(
              state.scanProgress?.statusMessage ?? 'Preparando biblioteca...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (state.scanProgress != null &&
                state.scanProgress!.total > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.scanProgress!.percentage / 100,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.scanProgress!.processed} de ${state.scanProgress!.total} canciones',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              state.scanProgress != null && state.scanProgress!.total > 0
                  ? 'Organizando tu gran colección...'
                  : 'Estamos preparando tu música...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref, AppIconSet icons) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icons.lyrics, // Usar nota si está disponible
            size: 64,
            color: const Color.fromRGBO(0, 0, 0, 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pudimos encontrar canciones en tu dispositivo.\n¿Están en una carpeta diferente o falta algún permiso?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(libraryViewModelProvider.notifier).scanLibrary(),
            child: const Text('Escanear ahora'),
          ),
        ],
      ),
    );
  }
}
