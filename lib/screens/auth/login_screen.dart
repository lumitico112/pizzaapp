import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/screens/dashboard/dashboard_screen.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _logoRuta;
  String? _fondoRuta;
  String _nombreNegocio = '';
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final repo = ConfiguracionRepository();
    _logoRuta = await repo.getConfig('logo_ruta');
    _fondoRuta = await repo.getConfig('fondo_login_ruta');
    _nombreNegocio = await repo.getConfig('nombre_negocio') ?? '';
    setState(() {
      _isLoadingConfig = false;
    });
  }

  void _login() async {
    final controller = context.read<AuthController>();
    final success = await controller.login(
      _usernameController.text, 
      _passwordController.text
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Credenciales incorrectas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer Contraseña', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu correo electrónico y te enviaremos un código de recuperación.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulación: Código 1234 enviado a tu correo.'),
                  backgroundColor: Colors.green,
                )
              );
            }, 
            child: const Text('Enviar Código')
          ),
        ],
      )
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    final isLoading = context.watch<AuthController>().isLoading;
    final primaryTextColor = Colors.brown.shade900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          image: _fondoRuta != null 
            ? DecorationImage(
                image: FileImage(File(_fondoRuta!)),
                fit: BoxFit.cover,
                // Leve oscurecimiento para asegurar contraste
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
              )
            : null,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65), // Transparente
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_logoRuta != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_logoRuta!), height: 90, fit: BoxFit.cover),
                        )
                      else
                        const Icon(Icons.store, size: 70, color: Colors.orange),
                      
                      const SizedBox(height: 16),
                      Text(
                        _nombreNegocio, 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryTextColor)
                      ),
                      const SizedBox(height: 32),
                      
                      TextField(
                        controller: _usernameController,
                        style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Usuario / Correo',
                          labelStyle: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
                          prefixIcon: Icon(Icons.person, color: primaryTextColor),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
                          prefixIcon: Icon(Icons.lock, color: primaryTextColor),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          onPressed: isLoading ? null : _login,
                          child: isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ENTRAR', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
