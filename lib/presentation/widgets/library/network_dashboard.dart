import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/network_provider.dart';
import '../../../domain/entities/remote_source.dart';

class NetworkDashboard extends ConsumerWidget {
  const NetworkDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // 1. Mis Conexiones (Activas)
        if (networkState.sources.isNotEmpty) ...[
          _SectionHeader(title: 'Mis Conexiones', primaryColor: primaryColor),
          ...networkState.sources.map(
            (source) => _ActiveSourceTile(
              source: source,
              primaryColor: primaryColor,
              onTap: () {
                if (source.type == RemoteSourceType.pc) {
                  ref
                      .read(networkProvider.notifier)
                      .connectToPc(
                        source.address,
                        username: source.username,
                        password: source.password,
                      );
                }
              },
              onRemove: () {
                ref.read(networkProvider.notifier).removeSource(source.id);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 2. Fuentes en la nube
        _SectionHeader(title: 'Fuentes en la nube', primaryColor: primaryColor),
        _SourceTile(
          icon: Icons.cloud_outlined,
          title: 'OneDrive',
          subtitle: 'Conectar cuenta Microsoft',
          onTap: () => _showNotImplemented(context, 'OneDrive'),
        ),
        _SourceTile(
          icon: Icons.add_to_drive_outlined,
          title: 'Google Drive',
          subtitle: 'Conectar cuenta Google',
          onTap: () => _showNotImplemented(context, 'Google Drive'),
        ),
        const SizedBox(height: 24),

        // 3. Fuentes en red local
        _SectionHeader(
          title: 'Fuentes en red local',
          primaryColor: primaryColor,
        ),
        _SourceTile(
          icon: Icons.computer_rounded,
          title: 'Mi PC (SMB)',
          subtitle: 'Windows Shared Folder',
          onTap: () => ref.read(networkProvider.notifier).startSMBDiscovery(),
        ),
        _SourceTile(
          icon: Icons.folder_shared_rounded,
          title: 'Servidor FTP',
          subtitle: 'File Transfer Protocol',
          onTap: () => ref.read(networkProvider.notifier).startFtpFlow(),
        ),
        _SourceTile(
          icon: Icons.lock_outline_rounded,
          title: 'Servidor SFTP',
          subtitle: 'Secure FTP (SSH)',
          onTap: () => ref.read(networkProvider.notifier).startSftpFlow(),
        ),
        _SourceTile(
          icon: Icons.web_asset_rounded,
          title: 'Servidor WebDAV',
          subtitle: 'Web Distributed Authoring',
          onTap: () => _showNotImplemented(context, 'WebDAV'),
        ),
      ],
    );
  }

  void _showNotImplemented(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('La integración con $feature llegará próximamente.'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color primaryColor;

  const _SectionHeader({required this.title, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: primaryColor.withValues(alpha: 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _ActiveSourceTile extends StatelessWidget {
  final RemoteSource source;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ActiveSourceTile({
    required this.source,
    required this.primaryColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (source.type) {
      case RemoteSourceType.pc:
        icon = Icons.computer_rounded;
        break;
      default:
        icon = Icons.dns_rounded;
    }

    return Dismissible(
      key: Key(source.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.withValues(alpha: 0.8),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        title: Text(
          source.name,
          style: TextStyle(
            color: primaryColor, // Destacar activa
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: const Text(
          'Toca para reconectar',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }
}
