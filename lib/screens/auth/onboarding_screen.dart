import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/onboarding_controller.dart';
import 'package:pizzaapp/screens/auth/login_screen.dart';
import 'package:pizzaapp/services/image_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();
  
  final _nombreNegocioController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminUsernameController = TextEditingController(text: 'admin');
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();
  
  String _monedaSeleccionada = 'PEN';
  
  String? _logoRuta;
  String? _fondoRuta;
  String? _fotoAdminRuta;

  Future<void> _pickImage(String type) async {
    final path = await _imageService.pickImageFromGallery();
    if (path != null) {
      setState(() {
        if (type == 'logo') _logoRuta = path;
        else if (type == 'fondo') _fondoRuta = path;
        else if (type == 'admin') _fotoAdminRuta = path;
      });
    }
  }
  
  Future<void> _pickImageCamera(String type) async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() {
        if (type == 'logo') _logoRuta = path;
        else if (type == 'fondo') _fondoRuta = path;
        else if (type == 'admin') _fotoAdminRuta = path;
      });
    }
  }

  void _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_adminPasswordController.text != _adminConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red),
      );
      return;
    }

    final controller = context.read<OnboardingController>();

    final success = await controller.setupSystem(
      nombreNegocio: _nombreNegocioController.text,
      moneda: _monedaSeleccionada,
      adminNombre: _adminNameController.text,
      adminUsername: _adminUsernameController.text,
      adminEmail: _adminEmailController.text,
      adminPassword: _adminPasswordController.text,
      logoRuta: _logoRuta,
      fondoRuta: _fondoRuta,
      fotoAdminRuta: _fotoAdminRuta,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _adminNameController.dispose();
    _adminUsernameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    super.dispose();
  }
  
  Widget _imageSelector(String label, String? ruta, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image: ruta != null ? DecorationImage(image: FileImage(File(ruta)), fit: BoxFit.cover) : null,
              ),
              child: ruta == null ? const Icon(Icons.image, color: Colors.grey) : null,
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(type),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImageCamera(type),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<OnboardingController>().isLoading;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.store, size: 60, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('Bienvenido a PizzApp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 8),
                  const Text('Configuremos tu negocio', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),

                  const Align(alignment: Alignment.centerLeft, child: Text('Datos del Negocio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 18))),
                  const Divider(),
                  _imageSelector('Logo de la empresa', _logoRuta, 'logo'),
                  const SizedBox(height: 16),
                  _imageSelector('Fondo para la pantalla de inicio (Login)', _fondoRuta, 'fondo'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreNegocioController,
                    decoration: const InputDecoration(labelText: 'Nombre de la Pizzería', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _monedaSeleccionada,
                    decoration: const InputDecoration(labelText: 'Moneda Principal', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'PEN', child: Text('Soles (PEN)')),
                      DropdownMenuItem(value: 'USD', child: Text('Dólares (USD)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _monedaSeleccionada = val);
                    },
                  ),

                  const SizedBox(height: 32),
                  const Align(alignment: Alignment.centerLeft, child: Text('Usuario Administrador', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 18))),
                  const Divider(),
                  _imageSelector('Foto de Perfil', _fotoAdminRuta, 'admin'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminNameController,
                    decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminUsernameController,
                    decoration: const InputDecoration(labelText: 'Usuario para login', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminEmailController,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => !v!.contains('@') ? 'Correo no válido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminConfirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirmar Contraseña', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: isLoading ? null : _guardarConfiguracion,
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('FINALIZAR Y ENTRAR', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
