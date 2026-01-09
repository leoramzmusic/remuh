import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/network_provider.dart';

class SftpConnectionPage extends ConsumerStatefulWidget {
  const SftpConnectionPage({super.key});

  @override
  ConsumerState<SftpConnectionPage> createState() => _SftpConnectionPageState();
}

class _SftpConnectionPageState extends ConsumerState<SftpConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passphraseController = TextEditingController();

  String _authMethod = 'Contraseña';
  final List<String> _authMethods = ['Contraseña', 'Clave privada'];

  bool _isPasswordVisible = false;
  String _privateKeyFileName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => ref.read(networkProvider.notifier).cancelFlow(),
        ),
        title: const Text('Añadir servidor SFTP'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _buildTextField(
              controller: _addressController,
              label: 'Dirección',
              hint: '192.168.1.100',
              validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _portController,
              label: 'Puerto',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _usernameController,
              label: 'Nombre de usuario',
              validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),

            _buildDropdown(
              label: 'Método de inicio de sesión',
              value: _authMethod,
              items: _authMethods,
              onChanged: (v) => setState(() => _authMethod = v!),
            ),
            const SizedBox(height: 20),

            if (_authMethod == 'Contraseña')
              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white54,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              )
            else ...[
              // Private Key Section
              GestureDetector(
                onTap: _pickPrivateKey,
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: TextEditingController(
                      text: _privateKeyFileName.isEmpty
                          ? 'Añadir clave privada'
                          : _privateKeyFileName,
                    ),
                    label: 'Clave privada',
                    suffixIcon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _passphraseController,
                label: 'Frases de contraseña',
                obscureText: true,
                hint: 'Opcional si la clave tiene pass',
              ),
            ],

            const SizedBox(height: 20),

            _buildTextField(
              controller: _displayNameController,
              label: 'Nombre para mostrar',
              hint: 'Opcional',
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  onPressed: () {
                    //Implement actual connection logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conexión SFTP próximamente...'),
                      ),
                    );
                  },
                  child: const Text(
                    'Añadir',
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

  void _pickPrivateKey() async {
    // Mock picker logic
    setState(() {
      _privateKeyFileName = "id_rsa";
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF3E91FF), fontSize: 13),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.blue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            suffixIcon: suffixIcon,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3E91FF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF3E91FF), fontSize: 13),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: const Color(0xFF2C2C2C),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
