import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/playlist.dart';
import '../providers/playlists_provider.dart';
import '../providers/library_view_model.dart';

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  final Track track;

  const AddToPlaylistSheet({super.key, required this.track});

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  final Set<int> _selectedPlaylistIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSelection();
  }

  void _initSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlistsAsync = ref.read(playlistsProvider);
      playlistsAsync.whenData((playlists) {
        if (mounted) {
          setState(() {
            for (final playlist in playlists) {
              if (playlist.trackIds.contains(widget.track.id)) {
                if (playlist.id != null) {
                  _selectedPlaylistIds.add(playlist.id!);
                }
              }
            }
            _isLoading = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Añadir a playlist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              '${widget.track.title} - ${widget.track.artist}',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            )
          else
            playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'No tienes playlists creadas',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final isSelected = _selectedPlaylistIds.contains(
                        playlist.id,
                      );

                      return CheckboxListTile(
                        title: Text(
                          playlist.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: isSelected,
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Colors.black,
                        onChanged: (value) {
                          if (playlist.id == null) return;
                          setState(() {
                            if (value == true) {
                              _selectedPlaylistIds.add(playlist.id!);
                            } else {
                              _selectedPlaylistIds.remove(playlist.id!);
                            }
                          });
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _saveAndClose(playlistsAsync.value ?? []),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Listo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _saveAndClose(List<Playlist> allPlaylists) async {
    final notifier = ref.read(playlistsProvider.notifier);
    final trackId = widget.track.id;

    for (final playlist in allPlaylists) {
      if (playlist.id == null) continue;

      final wasInPlaylist = playlist.trackIds.contains(trackId);
      final shouldBeInPlaylist = _selectedPlaylistIds.contains(playlist.id);

      if (shouldBeInPlaylist && !wasInPlaylist) {
        await notifier.addTrackToPlaylist(playlist.id!, trackId);
        // If it's Favoritos, sync with library flag
        if (playlist.name == 'Favoritos' && !widget.track.isFavorite) {
          await ref
              .read(libraryViewModelProvider.notifier)
              .toggleFavorite(trackId);
        }
      } else if (!shouldBeInPlaylist && wasInPlaylist) {
        await notifier.removeTrackFromPlaylist(playlist.id!, trackId);
        // If it's Favoritos, sync with library flag
        if (playlist.name == 'Favoritos' && widget.track.isFavorite) {
          await ref
              .read(libraryViewModelProvider.notifier)
              .toggleFavorite(trackId);
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
