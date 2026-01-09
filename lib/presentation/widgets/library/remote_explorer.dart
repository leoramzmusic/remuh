import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/network_provider.dart';
import '../../../domain/entities/remote_node.dart';
import '../../../domain/entities/remote_track.dart';

class RemoteExplorer extends ConsumerWidget {
  const RemoteExplorer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        _buildBreadcrumbs(context, ref, networkState.currentPath, primaryColor),
        Expanded(
          child: networkState.remoteNodes.isEmpty
              ? _buildEmptyFolder(networkState)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: networkState.remoteNodes.length,
                  itemBuilder: (context, index) {
                    final node = networkState.remoteNodes[index];
                    return _buildNodeTile(context, ref, node, primaryColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(
    BuildContext context,
    WidgetRef ref,
    List<String> path,
    Color primaryColor,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.03),
      child: Row(
        children: [
          IconButton(
            onPressed: () => ref.read(networkProvider.notifier).navigateBack(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: path.length,
              separatorBuilder: (_, _) => const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.white24,
              ),
              itemBuilder: (context, index) {
                final isLast = index == path.length - 1;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      path[index],
                      style: TextStyle(
                        color: isLast ? primaryColor : Colors.white60,
                        fontWeight: isLast
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(networkProvider.notifier).refreshCurrentPath(),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white54,
              size: 20,
            ),
            tooltip: 'Recargar carpeta',
          ),
        ],
      ),
    );
  }

  Widget _buildNodeTile(
    BuildContext context,
    WidgetRef ref,
    RemoteNode node,
    Color primaryColor,
  ) {
    final isAudio = node.isAudio;
    final isFolder = node.type == RemoteNodeType.folder;

    // if (!isAudio && !isFolder) {
    //   // Ocultar archivos que no sean audio o carpetas (seguridad/privacidad)
    //   return const SizedBox.shrink();
    // }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        isFolder ? Icons.folder_rounded : Icons.audiotrack_rounded,
        color: isFolder ? Colors.amber.withValues(alpha: 0.8) : primaryColor,
      ),
      title: Text(
        node.name,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: isAudio
          ? Text(
              '${(node.size! / (1024 * 1024)).toStringAsFixed(1)} MB',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            )
          : null,
      trailing: isAudio
          ? _buildActionButtons(ref, node, primaryColor)
          : const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white24,
            ),
      onTap: () {
        if (isFolder) {
          if (node.id == 'shortcut_public_folder') {
            // Navegación inteligente a la carpeta pública
            ref.read(networkProvider.notifier).jumpToPath(['Users', 'Public']);
          } else {
            ref.read(networkProvider.notifier).exploreFolder(node.name);
          }
        } else {
          // Streaming
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Streaming ${node.name}...')));
        }
      },
    );
  }

  Widget _buildActionButtons(
    WidgetRef ref,
    RemoteNode node,
    Color primaryColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.download_for_offline_rounded,
            size: 20,
            color: Colors.white38,
          ),
          onPressed: () {
            // Conversión de Node a Track para descarga simplificada
            final track = RemoteTrack(
              id: node.id,
              sourceId: 'PC',
              title: node.name,
              artist: 'Desconocido',
              album: 'Carpeta Remota',
              duration: Duration.zero,
            );
            ref.read(networkProvider.notifier).downloadTrack(track);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyFolder(NetworkStateData state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_open_rounded,
            size: 48,
            color: Colors.white12,
          ),
          const SizedBox(height: 16),
          const Text(
            'Carpeta vacía',
            style: TextStyle(color: Colors.white24, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              'DEBUG INFO:\nIP: ${state.lastIp}\nPath: ${state.currentPath.join('/')}\nItems: ${state.remoteNodes.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
