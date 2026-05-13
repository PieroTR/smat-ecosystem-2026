import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  // Liberar memoria (Buena práctica para el parcial)
  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Validación simple antes de disparar la red
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    bool success = await AuthService().login(
      _userController.text,
      _passController.text
    );
    
    if (!mounted) return; 
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage())
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales incorrectas o servidor offline'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso al SMAT')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userController, 
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person),
              )
            ),
            TextField(
              controller: _passController, 
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
              ), 
              obscureText: true
            ),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator() 
              : SizedBox(
                  width: double.infinity, // Botón a lo largo de la pantalla para mejor UX
                  child: ElevatedButton(
                    onPressed: _handleLogin, 
                    child: const Text('Iniciar Sesión')
                  ),
                ),
          ],
        ),
      ),
    );
  }
}