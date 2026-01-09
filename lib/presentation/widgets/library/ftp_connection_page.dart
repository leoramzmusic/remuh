import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remuh/presentation/providers/network_provider.dart';

class FtpConnectionPage extends ConsumerStatefulWidget {
  const FtpConnectionPage({super.key});

  @override
  ConsumerState<FtpConnectionPage> createState() => _FtpConnectionPageState();
}

class _FtpConnectionPageState extends ConsumerState<FtpConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '21');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  String _security = 'SSL/TLS';
  bool _isAnonymous = false;
  bool _isPasswordVisible = false;
  String _encoding = 'UTF-8';
  String _transferMode = 'Pasivo';
  String _encryption = 'Explícito';

  final List<String> _securityOptions = ['Ninguna', 'SSL/TLS', 'SFTP (SSH)'];
  final List<String> _transferModes = ['Pasivo', 'Activo'];
  final List<String> _encryptionOptions = ['Explícito', 'Implícito'];

  final List<String> _encodings = [
    'AUTO',
    'UTF-8',
    'UTF-16',
    'UTF-16BE',
    'UTF-16LE',
    'ISO-8859-1',
    'ISO-8859-2',
    'GBK',
    'Shift_JIS',
    'Big5',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(networkProvider.notifier).cancelFlow();
          },
        ),
        title: const Text('Añadir servidor FTP'),
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
            _buildDropdown(
              label: 'Seguridad',
              value: _security,
              items: _securityOptions,
              onChanged: (v) => setState(() => _security = v!),
            ),
            const SizedBox(height: 20),

            if (!_isAnonymous) ...[
              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de usuario',
              ),
              const SizedBox(height: 20),
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
              ),
              const SizedBox(height: 20),
            ],

            _buildAnonymousSwitch(),
            const SizedBox(height: 24),

            _buildDropdown(
              label: 'Encriptación',
              value: _encryption,
              items: _encryptionOptions,
              onChanged: (v) => setState(() => _encryption = v!),
            ),
            const SizedBox(height: 20),

            _buildDropdown(
              label: 'Modo de transferencia',
              value: _transferMode,
              items: _transferModes,
              onChanged: (v) => setState(() => _transferMode = v!),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _showEncodingSelector,
              child: AbsorbPointer(
                child: _buildTextField(
                  controller: TextEditingController(text: _encoding),
                  label: 'Codificación',
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
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
                        content: Text('Conexión FTP próximamente...'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    // Estilo Samsung OneUI: Label en azul pequeño arriba, linea abajo
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

  Widget _buildAnonymousSwitch() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _isAnonymous ? const Color(0xFF3E91FF) : Colors.white38,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: _isAnonymous
                ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF3E91FF),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _isAnonymous = !_isAnonymous;
              if (_isAnonymous) {
                _usernameController.clear();
                _passwordController.clear();
              }
            });
          },
          child: const Text(
            'Iniciar sesión de forma anónima',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _showEncodingSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Codificación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _encodings.length,
                  itemBuilder: (context, index) {
                    final item = _encodings[index];
                    final isSelected = item == _encoding;
                    return ListTile(
                      title: Text(
                        item,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF3E91FF)
                              : Colors.white,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF3E91FF))
                          : null,
                      onTap: () {
                        setState(() => _encoding = item);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
