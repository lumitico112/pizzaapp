import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/usuario_controller.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';

class UsuarioFormScreen extends StatefulWidget {
  final int? usuarioId;
  const UsuarioFormScreen({super.key, this.usuarioId});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  final _nombreCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  String _rol = 'empleado';
  String? _fotoRuta;
  String? _qrRuta;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.usuarioId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    final user = await context.read<UsuarioController>().getUsuario(widget.usuarioId!);
    if (user != null) {
      _nombreCtrl.text = user.nombre;
      _usernameCtrl.text = user.username;
      _correoCtrl.text = user.correo ?? '';
      _rol = user.rol;
      _fotoRuta = user.fotoRuta;
    }
    
    final currentUser = context.read<AuthController>().currentUser;
    final isAdmin = currentUser?.rol == 'admin';
    if (isAdmin) {
      final configRepo = ConfiguracionRepository();
      _qrRuta = await configRepo.getConfig('qr_ventas_ruta');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(bool fromCamera) async {
    final path = fromCamera 
      ? await _imageService.pickImageFromCamera()
      : await _imageService.pickImageFromGallery();
    
    if (path != null) {
      setState(() => _fotoRuta = path);
    }
  }

  Future<void> _pickQrImage() async {
    final path = await _imageService.pickImageFromGallery();
    if (path != null) {
      setState(() => _qrRuta = path);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final ctrl = context.read<UsuarioController>();
    final authCtrl = context.read<AuthController>();
    final isAdmin = authCtrl.currentUser?.rol == 'admin';
    
    final success = await ctrl.guardarUsuario(
      id: widget.usuarioId,
      nombre: _nombreCtrl.text,
      username: _usernameCtrl.text,
      correo: _correoCtrl.text,
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      rol: _rol,
      fotoRuta: _fotoRuta,
    );

    if (success && mounted) {
      if (isAdmin && _qrRuta != null) {
        final configRepo = ConfiguracionRepository();
        await configRepo.saveConfig('qr_ventas_ruta', _qrRuta!);
      }
      
      // If editing current user, reload auth to reflect photo changes
      if (widget.usuarioId == authCtrl.currentUser?.id) {
         // The simplest way to reflect photo change is let the user log out/in, or if we had a reload method
      }
      
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.error ?? 'Error desconocido'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUser = context.read<AuthController>().currentUser;
    final isAdmin = currentUser?.rol == 'admin';
    final isCreating = widget.usuarioId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreating ? 'Nuevo Usuario' : 'Editar Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _mostrarOpcionesImagen,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _fotoRuta != null ? FileImage(File(_fotoRuta!)) : null,
                  child: _fotoRuta == null ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nombreCtrl,
                enabled: isAdmin,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _usernameCtrl,
                enabled: isAdmin,
                decoration: const InputDecoration(labelText: 'Usuario (Login)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _correoCtrl,
                enabled: isAdmin,
                decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              if (isAdmin) ...[
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'empleado', child: Text('Empleado (Cajero/Preparador)')),
                  ],
                  onChanged: (v) => setState(() => _rol = v!),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isCreating ? 'Contraseña' : 'Nueva Contraseña (Opcional)', 
                  border: const OutlineInputBorder()
                ),
                validator: (v) {
                  if (isCreating && v!.isEmpty) return 'Requerida';
                  if (v!.isNotEmpty && v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              if (isAdmin) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text('Configuración Global: Pago Yape/Plin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Sube el código QR que se mostrará a los clientes al momento de cobrar.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickQrImage,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _qrRuta != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_qrRuta!), fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Subir QR', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _save,
                  child: const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
