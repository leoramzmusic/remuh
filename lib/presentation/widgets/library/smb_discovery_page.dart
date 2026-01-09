import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remuh/presentation/providers/network_provider.dart';

class SmbDiscoveryPage extends ConsumerStatefulWidget {
  const SmbDiscoveryPage({super.key});

  @override
  ConsumerState<SmbDiscoveryPage> createState() => _SmbDiscoveryPageState();
}

class _SmbDiscoveryPageState extends ConsumerState<SmbDiscoveryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkProvider);
    final isScanning = networkState.isScanning;
    final devices = networkState.discoveredDevices;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Añadir unidad de red'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(networkProvider.notifier).cancelFlow(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Área de animación / estado
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isScanning)
                    RotationTransition(
                      turns: _controller,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.blue.withValues(alpha: 0.0),
                              Colors.blue.withValues(alpha: 0.5),
                              Colors.blue,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_input_antenna,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isScanning
                ? 'Buscando unidades en la red actual...'
                : devices.isEmpty
                ? 'No se encontraron unidades.'
                : 'Seleccionar una unidad de red',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),

          // Lista de resultados
          Expanded(
            child: devices.isEmpty && !isScanning
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white24,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Asegúrate de que el PC esté encendido\ny en la misma red Wi-Fi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(networkProvider.notifier)
                              .startSMBDiscovery(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1E1E1E),
                          child: Icon(
                            Icons.desktop_windows,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          device.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          device.address,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          // Al tocar, vamos a la pantalla manual prellenada
                          ref
                              .read(networkProvider.notifier)
                              .startManualSetup(prefillIp: device.address);
                        },
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E91FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Conectar'),
                          onPressed: () {
                            ref
                                .read(networkProvider.notifier)
                                .startManualSetup(prefillIp: device.address);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      ref.read(networkProvider.notifier).cancelFlow(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      ref.read(networkProvider.notifier).startManualSetup(),
                  child: const Text(
                    'Añadir (manual)',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
