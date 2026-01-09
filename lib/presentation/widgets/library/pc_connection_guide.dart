import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_settings/app_settings.dart';
import '../../providers/network_provider.dart';

class PcConnectionGuide extends ConsumerStatefulWidget {
  const PcConnectionGuide({super.key});

  @override
  ConsumerState<PcConnectionGuide> createState() => _PcConnectionGuideState();
}

class _PcConnectionGuideState extends ConsumerState<PcConnectionGuide>
    with WidgetsBindingObserver {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(networkProvider.notifier).cancelFlow(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                ),
              ),
              const Text(
                'Conectar con Mi PC',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.greenAccent,
                  secondary: Colors.greenAccent,
                ),
              ),
              child: Stepper(
                physics: const BouncingScrollPhysics(),
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep += 1);
                  } else {
                    _showConnectionDialog(context, networkState);
                  }
                },
                onStepCancel: _currentStep > 0
                    ? () => setState(() => _currentStep -= 1)
                    : null,
                controlsBuilder: (context, controls) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: controls.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _currentStep == 3 ? 'CONECTAR' : 'SIGUIENTE',
                          ),
                        ),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: controls.onStepCancel,
                            child: const Text(
                              'ATRÁS',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  _buildStep(
                    index: 0,
                    title: 'Red Wi-Fi',
                    content:
                        'Asegúrate de que tu PC esté encendida y conectada a la misma red Wi-Fi que este dispositivo.',
                    isActive: _currentStep >= 0,
                    button: OutlinedButton.icon(
                      onPressed: () => AppSettings.openAppSettings(
                        type: AppSettingsType.wifi,
                      ),
                      icon: const Icon(Icons.settings_remote_rounded),
                      label: const Text('ESCANEAR QR CON WI-FI (SISTEMA)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  _buildStep(
                    index: 1,
                    title: 'Compartir Archivos',
                    content:
                        'Activa el "Uso compartido de archivos e impresoras" en el Panel de Control o Preferencias del Sistema de tu PC.',
                    isActive: _currentStep >= 1,
                  ),
                  _buildStep(
                    index: 2,
                    title: 'Carpeta Música',
                    content:
                        'Haz clic derecho en tu carpeta de Música, ve a Propiedades > Compartir y confirma que tiene permisos de lectura.',
                    isActive: _currentStep >= 2,
                  ),
                  _buildStep(
                    index: 3,
                    title: 'Dirección IP',
                    content:
                        'Necesitamos la IP local de tu PC (ej: 192.168.1.10). Puedes encontrarla en los ajustes de red de tu computadora.',
                    isActive: _currentStep >= 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep({
    required int index,
    required String title,
    required String content,
    required bool isActive,
    Widget? button,
  }) {
    StepState state = StepState.indexed;
    bool stepIsActive = _currentStep == index;
    bool stepIsCompleted = _currentStep > index;

    if (!isActive && !stepIsCompleted) {
      state = StepState.disabled;
    }

    return Step(
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (button != null) ...[const SizedBox(height: 12), button],
        ],
      ),
      isActive: stepIsActive || stepIsCompleted,
      state: state,
    );
  }

  void _showConnectionDialog(
    BuildContext context,
    NetworkStateData networkState,
  ) {
    ref.read(networkProvider.notifier).startManualSetup();
  }
}

class PcManualSetupPage extends ConsumerStatefulWidget {
  const PcManualSetupPage({super.key});

  @override
  ConsumerState<PcManualSetupPage> createState() => _PcManualSetupPageState();
}

class _PcManualSetupPageState extends ConsumerState<PcManualSetupPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-completar campos con los últimos datos exitosos guardados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lastState = ref.read(networkProvider);
      if (lastState.lastIp != null && _ipController.text.isEmpty) {
        _ipController.text = lastState.lastIp!;
      }
      if (lastState.lastUsername != null && _userController.text.isEmpty) {
        _userController.text = lastState.lastUsername!;
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Conexión'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(networkProvider.notifier).cancelFlow(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icono / Encabezado
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.desktop_windows_rounded,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Formulario
              TextField(
                controller: _ipController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'IP de tu PC',
                  labelStyle: TextStyle(color: Colors.white60),
                  hintText: 'Ej: 192.168.1.15',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Usuario Windows',
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña (No PIN)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Si usas cuenta Microsoft, es mejor crear un "Usuario Local" en tu PC para evitar errores de red.',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (networkState.state == NetworkState.error) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    networkState.errorMessage ?? 'Error de conexión',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              // Botón Conectar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final ip = _ipController.text.trim();
                    final user = _userController.text.trim();
                    final pass = _passController.text;
                    if (ip.isNotEmpty) {
                      ref
                          .read(networkProvider.notifier)
                          .connectToPc(ip, username: user, password: pass);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  child: networkState.state == NetworkState.connecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'CONECTAR',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
