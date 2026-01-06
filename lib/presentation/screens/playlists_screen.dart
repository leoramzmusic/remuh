import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist.dart';
import '../providers/playlists_provider.dart';
import '../providers/spotify_provider.dart';
import '../widgets/create_playlist_dialog.dart';
import 'playlist_tracks_screen.dart';
import 'spotify_pending_tracks_screen.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final spotifyState = ref.watch(spotifyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de reproducción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          final userPlaylists = playlists
              .where((p) => !p.isSmart && !p.isHidden)
              .toList();
          final smartPlaylists = playlists
              .where(
                (p) =>
                    p.isSmart &&
                    p.smartType != 'genre' &&
                    p.smartType != 'spotify_pending' &&
                    !p.isHidden,
              )
              .toList();

          // Enforce smart playlists order: Favoritos, Más escuchadas, Recién añadidas
          smartPlaylists.sort((a, b) {
            final orderMap = {'favorites': 0, 'top': 1, 'added': 2};
            final orderA = orderMap[a.smartType] ?? 99;
            final orderB = orderMap[b.smartType] ?? 99;
            return orderA.compareTo(orderB);
          });

          final exportedPlaylists = playlists
              .where((p) => p.smartType == 'spotify_pending' && !p.isHidden)
              .toList();
          final genrePlaylists = playlists
              .where((p) => p.smartType == 'genre' && !p.isHidden)
              .toList();
          final hiddenPlaylists = playlists.where((p) => p.isHidden).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sección 1: Inteligentes
              if (smartPlaylists.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'INTELIGENTES',
                  icon: Icons.psychology_rounded,
                  count: smartPlaylists.length,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _PlaylistTile(
                      playlist: smartPlaylists[index],
                      section: 'smart',
                    );
                  }, childCount: smartPlaylists.length),
                ),
              ],

              // Sección 2: Mis listas
              _buildSectionHeader(
                context,
                'MIS LISTAS',
                icon: Icons.edit_note_rounded,
                count: userPlaylists.length,
                trailing: TextButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nueva', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              if (userPlaylists.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No tienes listas personales',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _PlaylistTile(
                      playlist: userPlaylists[index],
                      section: 'user',
                    );
                  }, childCount: userPlaylists.length),
                ),

              // Sección 3: Exportadas
              if (exportedPlaylists.isNotEmpty ||
                  spotifyState.isAuthenticated) ...[
                _buildSectionHeader(
                  context,
                  'EXPORTADAS',
                  icon: Icons.link_rounded,
                  count: exportedPlaylists.length,
                ),
                if (exportedPlaylists.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Text(
                        'Conectado a Spotify. No hay canciones pendientes de importar.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _PlaylistTile(
                        playlist: exportedPlaylists[index],
                        section: 'exported',
                      );
                    }, childCount: exportedPlaylists.length),
                  ),
              ],

              // Sección 4: Por género
              if (genrePlaylists.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'POR GÉNERO',
                  icon: Icons.music_note_rounded,
                  count: genrePlaylists.length,
                ),
                SliverToBoxAdapter(
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      title: const Text(
                        'Ver por género musical',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      iconColor: Theme.of(context).colorScheme.primary,
                      collapsedIconColor: Colors.white38,
                      children: genrePlaylists
                          .map(
                            (p) => _PlaylistTile(playlist: p, section: 'genre'),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],

              // Sección 5: Ocultas
              if (hiddenPlaylists.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'OCULTAS',
                  icon: Icons.visibility_off_rounded,
                  count: hiddenPlaylists.length,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _PlaylistTile(
                      playlist: hiddenPlaylists[index],
                      section: 'hidden',
                    );
                  }, childCount: hiddenPlaylists.length),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    required IconData icon,
    int? count,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.5,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 0.5,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePlaylistDialog(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _PlaylistTile extends ConsumerWidget {
  final Playlist playlist;
  final String section;

  const _PlaylistTile({required this.playlist, required this.section});

  IconData _getIcon() {
    if (section == 'user') return Icons.edit_rounded;
    if (section == 'exported') return Icons.link_rounded;
    if (section == 'genre') return Icons.music_note_rounded;
    if (section == 'hidden') return Icons.visibility_off_rounded;
    if (section == 'smart') {
      if (playlist.smartType == 'favorites') return Icons.favorite_rounded;
      if (playlist.smartType == 'added') return Icons.new_releases_rounded;
      if (playlist.smartType == 'top') return Icons.trending_up_rounded;
      return Icons.psychology_rounded;
    }
    return Icons.playlist_play_rounded;
  }

  String? _getLabel() {
    if (section == 'smart') return 'AUTO';
    if (section == 'exported') return 'IMPORTADA';
    if (section == 'genre') return 'GÉNERO';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmart = playlist.isSmart;
    final hasCover = playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (playlist.smartType == 'spotify_pending') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpotifyPendingTracksScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistTracksScreen(playlist: playlist),
                ),
              );
            }
          },
          onLongPress: () => _showPlaylistOptions(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSmart
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      width: 1,
                    )
                  : null,
              gradient: isSmart
                  ? LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.1),
                        colorScheme.surface.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSmart
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSmart
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
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
                  ),
                  child: !hasCover
                      ? Icon(
                          _getIcon(),
                          color: isSmart
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              playlist.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_getLabel() != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getLabel()!,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                          if (playlist.isHidden) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSmart
                            ? (playlist.description ?? 'Generada por REMUH')
                            : '${playlist.trackIds.length} canciones',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                if (playlist.canBeDeleted)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    onPressed: () => _showDeleteDialog(context, ref),
                    color: Colors.white.withValues(alpha: 0.4),
                  )
                else if (playlist.canBeHidden)
                  IconButton(
                    icon: Icon(
                      playlist.isHidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 22,
                    ),
                    onPressed: () => _toggleVisibility(context, ref),
                    color: Colors.white.withValues(alpha: 0.4),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      image:
                          playlist.coverUrl != null &&
                              playlist.coverUrl!.isNotEmpty
                          ? DecorationImage(
                              image:
                                  (playlist.coverUrl!.startsWith('http')
                                          ? NetworkImage(playlist.coverUrl!)
                                          : FileImage(File(playlist.coverUrl!)))
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        playlist.coverUrl == null || playlist.coverUrl!.isEmpty
                        ? Icon(_getIcon(), color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      playlist.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            if (playlist.name != 'Por conseguir') ...[
              ListTile(
                leading: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Reproducir',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(playlistsProvider.notifier)
                      .playPlaylist(playlist, shuffle: false);
                },
              ),
            ],

            if (playlist.customCover != null)
              ListTile(
                leading: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Restaurar portada automática',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(playlistsProvider.notifier)
                      .updatePlaylistCover(playlist, null);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Portada de "${playlist.name}" restaurada',
                        ),
                      ),
                    );
                  }
                },
              ),

            ListTile(
              leading: const Icon(Icons.image_outlined, color: Colors.white),
              title: const Text(
                'Cambiar portada (Galería)',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _pickImage(context, ref),
            ),

            if (playlist.canBeHidden)
              ListTile(
                leading: Icon(
                  playlist.isHidden
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white,
                ),
                title: Text(
                  playlist.isHidden ? 'Mostrar lista' : 'Ocultar lista',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleVisibility(context, ref);
                },
              ),

            if (playlist.canBeDeleted)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Eliminar lista',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, ref);
                },
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context); // Ensure sheet is closed

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await ref
            .read(playlistsProvider.notifier)
            .updatePlaylistCover(playlist, image.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Portada de "${playlist.name}" actualizada'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  // Re-implementing existing methods to ensure they are available to the new code if needed,
  // but since we are inside the class, they are already there.

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${playlist.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(playlistsProvider.notifier).deletePlaylist(playlist.id!);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleVisibility(BuildContext context, WidgetRef ref) {
    if (playlist.smartType == 'genre') {
      ref
          .read(playlistsProvider.notifier)
          .toggleGenreVisibility(playlist.name, true);
    } else {
      // Other hideable smart playlists
      // Extract simple name from smartType or use smartType itself
      final keyName = playlist.smartType == 'recent'
          ? 'recent'
          : (playlist.smartType == 'spotify_pending'
                ? 'spotify_pending'
                : playlist.name);
      ref
          .read(playlistsProvider.notifier)
          .toggleGenreVisibility(keyName, false);
    }
  }
}
