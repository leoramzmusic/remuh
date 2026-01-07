import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/playlist.dart';
import '../providers/playlists_provider.dart';
import '../providers/library_view_model.dart';
import 'create_playlist_dialog.dart';

enum PlaylistSortOption { recentlyUpdated, recentlyAdded, alphabetically }

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  final Track track;

  const AddToPlaylistSheet({super.key, required this.track});

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  PlaylistSortOption _sortOption = PlaylistSortOption.recentlyUpdated;

  @override
  void initState() {
    super.initState();
  }

  List<Playlist> _sortPlaylists(List<Playlist> playlists) {
    final sorted = List<Playlist>.from(playlists);
    switch (_sortOption) {
      case PlaylistSortOption.recentlyAdded:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case PlaylistSortOption.alphabetically:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case PlaylistSortOption.recentlyUpdated:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return sorted;
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case PlaylistSortOption.recentlyUpdated:
        return 'Actualizado recientemente';
      case PlaylistSortOption.recentlyAdded:
        return 'Agregados recientemente';
      case PlaylistSortOption.alphabetically:
        return 'Alfabéticamente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Agregar a playlist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Flexible(
                child: playlistsAsync.when(
                  data: (playlists) {
                    final visiblePlaylists = playlists
                        .where((p) => !p.isSmart)
                        .toList();
                    final savedInPlaylists = visiblePlaylists
                        .where((p) => p.trackIds.contains(widget.track.id))
                        .toList();
                    final otherPlaylists = visiblePlaylists
                        .where((p) => !p.trackIds.contains(widget.track.id))
                        .toList();
                    final sortedOtherPlaylists = _sortPlaylists(otherPlaylists);

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nueva Playlist Button
                          _buildNewPlaylistButton(context),

                          const SizedBox(height: 24),

                          // Guardado en section
                          if (savedInPlaylists.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Guardado en',
                              trailing: TextButton(
                                onPressed: () =>
                                    _removeFromAll(savedInPlaylists),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Borrar todo',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ...savedInPlaylists.map(
                              (p) => _buildPlaylistTile(p, true),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // My Playlists section
                          _buildSectionHeader(
                            'Mis Listas',
                            trailing: _buildSortSelector(context),
                          ),

                          if (sortedOtherPlaylists.isEmpty &&
                              savedInPlaylists.isEmpty)
                            _buildEmptyState()
                          else
                            ...sortedOtherPlaylists.map(
                              (p) => _buildPlaylistTile(p, false),
                            ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewPlaylistButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCreatePlaylistDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Nueva playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSortSelector(BuildContext context) {
    return PopupMenuButton<PlaylistSortOption>(
      initialValue: _sortOption,
      onSelected: (value) => setState(() => _sortOption = value),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, color: Colors.white54, size: 18),
            const SizedBox(width: 4),
            Text(
              _getSortLabel(),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildSortItem(PlaylistSortOption.recentlyUpdated, 'Por actualización'),
        _buildSortItem(PlaylistSortOption.recentlyAdded, 'Por creación'),
        _buildSortItem(PlaylistSortOption.alphabetically, 'Alfabético'),
      ],
    );
  }

  PopupMenuItem<PlaylistSortOption> _buildSortItem(
    PlaylistSortOption value,
    String label,
  ) {
    final isSelected = _sortOption == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist, bool isInPlaylist) {
    final hasCover = playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isInPlaylist
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _togglePlaylist(playlist),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Cover
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    image: hasCover
                        ? DecorationImage(
                            image:
                                (playlist.coverUrl!.startsWith('http')
                                        ? NetworkImage(playlist.coverUrl!)
                                        : FileImage(File(playlist.coverUrl!)))
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      if (hasCover)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: !hasCover
                      ? Icon(
                          playlist.name == 'Favoritos'
                              ? Icons.favorite_rounded
                              : Icons.playlist_play_rounded,
                          color: playlist.name == 'Favoritos'
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.white38,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: TextStyle(
                          color: isInPlaylist
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: isInPlaylist
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.trackIds.length} canciones',
                        style: TextStyle(
                          color: isInPlaylist
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7)
                              : Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isInPlaylist
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white24,
                      width: 2,
                    ),
                    color: isInPlaylist
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: isInPlaylist
                      ? const Icon(Icons.check, color: Colors.black, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.playlist_add_rounded, size: 64, color: Colors.white10),
            SizedBox(height: 16),
            Text(
              'No tienes playlists personales',
              style: TextStyle(color: Colors.white24, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlaylist(Playlist playlist) async {
    if (playlist.id == null) return;

    final notifier = ref.read(playlistsProvider.notifier);
    final trackId = widget.track.id;
    final isCurrentlyIn = playlist.trackIds.contains(trackId);

    if (isCurrentlyIn) {
      await notifier.removeTrackFromPlaylist(playlist.id!, trackId);
      if (playlist.name == 'Favoritos' && widget.track.isFavorite) {
        await ref
            .read(libraryViewModelProvider.notifier)
            .toggleFavorite(trackId);
      }
    } else {
      await notifier.addTrackToPlaylist(playlist.id!, trackId);
      if (playlist.name == 'Favoritos' && !widget.track.isFavorite) {
        await ref
            .read(libraryViewModelProvider.notifier)
            .toggleFavorite(trackId);
      }
    }
  }

  void _removeFromAll(List<Playlist> playlists) async {
    final notifier = ref.read(playlistsProvider.notifier);
    final trackId = widget.track.id;

    for (final playlist in playlists) {
      if (playlist.id != null) {
        await notifier.removeTrackFromPlaylist(playlist.id!, trackId);
        if (playlist.name == 'Favoritos' && widget.track.isFavorite) {
          await ref
              .read(libraryViewModelProvider.notifier)
              .toggleFavorite(trackId);
        }
      }
    }
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlaylistDialog(trackId: widget.track.id),
        fullscreenDialog: true,
      ),
    );
  }
}
