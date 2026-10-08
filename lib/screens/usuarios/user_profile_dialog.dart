import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/screens/auth/login_screen.dart';
import 'package:pizzaapp/screens/usuarios/usuarios_screen.dart';
import 'package:pizzaapp/screens/usuarios/usuario_form_screen.dart';

class UserProfileDialog extends StatelessWidget {
  const UserProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final user = authCtrl.currentUser;

    if (user == null) return const SizedBox();

    return AlertDialog(
      title: const Text('Perfil de Usuario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange.shade100,
            backgroundImage: user.fotoRuta != null ? FileImage(File(user.fotoRuta!)) : null,
            child: user.fotoRuta == null ? const Icon(Icons.person, size: 40, color: Colors.orange) : null,
          ),
          const SizedBox(height: 16),
          Text(user.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(user.rol.toUpperCase(), style: const TextStyle(color: Colors.grey)),
          if (user.correo != null) Text(user.correo!, style: const TextStyle(color: Colors.grey)),
        ],
      ),
      actions: [
        if (user.rol == 'admin')
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuariosScreen()));
            },
            icon: const Icon(Icons.group),
            label: const Text('Gestión de Usuarios'),
          ),
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => UsuarioFormScreen(usuarioId: user.id)));
          },
          icon: const Icon(Icons.edit),
          label: const Text('Editar Perfil'),
        ),
        TextButton.icon(
          onPressed: () {
            authCtrl.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
