import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/track.dart';
import '../../providers/library_view_model.dart';

/// Folders view - tree-style navigation
class FoldersView extends ConsumerWidget {
  const FoldersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(libraryViewModelProvider).tracks;

    // Group tracks by folder path
    final folderMap = <String, List<Track>>{};
    for (final track in tracks) {
      final pathParts = track.filePath.split('/');
      final path = pathParts.length > 1
          ? pathParts.sublist(0, pathParts.length - 1).join('/')
          : '/';
      folderMap.putIfAbsent(path, () => []).add(track);
    }

    final folders = folderMap.keys.toList()..sort();

    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay carpetas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final folderName = folder.split('/').last;
        final trackCount = folderMap[folder]!.length;

        return ListTile(
          leading: const Icon(Icons.folder_rounded),
          title: Text(folderName.isEmpty ? 'Root' : folderName),
          subtitle: Text(
            '$trackCount ${trackCount == 1 ? 'canción' : 'canciones'}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            // Navigate to folder detail
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Abrir carpeta: $folderName')),
            );
          },
        );
      },
    );
  }
}
