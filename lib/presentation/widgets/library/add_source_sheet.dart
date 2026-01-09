import 'package:flutter/material.dart';
import '../../../domain/entities/remote_source.dart';

class AddSourceSheet extends StatelessWidget {
  final Function(RemoteSourceType) onSourceSelected;

  const AddSourceSheet({super.key, required this.onSourceSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Conectar nueva fuente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          _buildSourceOption(
            context,
            type: RemoteSourceType.pc,
            icon: Icons.computer_rounded,
            title: 'Computadora Personal',
            subtitle: 'SMB, FTP, WebDAV (Local)',
          ),
          _buildSourceOption(
            context,
            type: RemoteSourceType.cloud,
            icon: Icons.cloud_circle_rounded,
            title: 'Servicios en la Nube',
            subtitle: 'Google Drive, Dropbox, OneDrive',
          ),
          _buildSourceOption(
            context,
            type: RemoteSourceType.nas,
            icon: Icons.storage_rounded,
            title: 'Servidor Local o NAS',
            subtitle: 'IP, Hostname, Servidor dedicado',
          ),
          _buildSourceOption(
            context,
            type: RemoteSourceType.custom,
            icon: Icons.api_rounded,
            title: 'Servicio Personalizado',
            subtitle: 'API REST, GraphQL, REMUH Cloud',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required RemoteSourceType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.white60),
      ),
      onTap: () {
        Navigator.pop(context);
        onSourceSelected(type);
      },
    );
  }
}
