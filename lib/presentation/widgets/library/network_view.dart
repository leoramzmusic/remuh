import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remuh/presentation/providers/network_provider.dart';
import 'network_dashboard.dart';
import 'smb_discovery_page.dart';
import 'ftp_connection_page.dart';
import 'sftp_connection_page.dart';
import 'pc_connection_guide.dart';
import 'remote_explorer.dart';

class NetworkView extends ConsumerWidget {
  const NetworkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 1. Manejo de Errores Globales
    // Priorizamos el estado de error para que sea visible en cualquier flujo
    // EXCEPTO en la configuración manual, que maneja sus propios errores inline
    if (networkState.state == NetworkState.error &&
        networkState.currentFlow != NetworkFlow.pcManualSetup) {
      return _buildError(
        context,
        ref,
        networkState.errorMessage ?? 'Error desconocido',
        primaryColor,
      );
    }

    // 2. Flujos Específicos (Sub-pantallas)
    if (networkState.currentFlow == NetworkFlow.pcGuide) {
      return const PcConnectionGuide();
    }
    if (networkState.currentFlow == NetworkFlow.pcDiscovery) {
      return const SmbDiscoveryPage();
    }
    if (networkState.currentFlow == NetworkFlow.pcManualSetup) {
      return const PcManualSetupPage();
    }
    if (networkState.currentFlow == NetworkFlow.ftpSetup) {
      return const FtpConnectionPage();
    }
    if (networkState.currentFlow == NetworkFlow.sftpSetup) {
      return const SftpConnectionPage();
    }
    if (networkState.currentFlow == NetworkFlow.pcExplorer) {
      return const RemoteExplorer();
    }

    // 3. Vista Principal (Dashboard Modular)
    // Se muestra por defecto si no hay un flujo activo o si estamos "conectados" pero en la raíz
    return const NetworkDashboard();
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    String? message,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () =>
                    ref.read(networkProvider.notifier).cancelFlow(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            const Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              'Error de conexión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'No se pudo conectar con la red local.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  ref.read(networkProvider.notifier).connectToNetwork(),
              child: const Text('REINTENTAR CONEXIÓN'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(networkProvider.notifier).startPcFlow(),
              child: const Text(
                'VOLVER A CONFIGURAR',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
