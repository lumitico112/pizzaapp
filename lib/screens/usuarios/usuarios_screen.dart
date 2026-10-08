import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/usuario_controller.dart';
import 'package:pizzaapp/screens/usuarios/usuario_form_screen.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioController>().loadUsuarios();
    });
  }

  void _showRecuperarDialog(String email) {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El usuario no tiene correo registrado.')));
      return;
    }
    final code = context.read<UsuarioController>().simularEnvioRecuperacion(email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer Usuario'),
        content: Text('Simulación: Se ha enviado el código $code al correo $email.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de Usuarios'),
            backgroundColor: AppColors.secondary,
          ),
          body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: controller.usuarios.length,
                itemBuilder: (context, index) {
                  final u = controller.usuarios[index];
                  final isBloqueado = u.bloqueado == 1;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isBloqueado ? Colors.red.shade100 : Colors.blue.shade100,
                        backgroundImage: u.fotoRuta != null ? FileImage(File(u.fotoRuta!)) : null,
                        child: u.fotoRuta == null ? Icon(Icons.person, color: isBloqueado ? Colors.red : Colors.blue) : null,
                      ),
                      title: Text(u.nombre, style: TextStyle(
                        decoration: isBloqueado ? TextDecoration.lineThrough : null,
                        color: isBloqueado ? Colors.red : Colors.black,
                      )),
                      subtitle: Text('${u.rol.toUpperCase()} - ${u.correo ?? "Sin correo"}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) async {
                          if (val == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => UsuarioFormScreen(usuarioId: u.id)));
                          } else if (val == 'block') {
                            await controller.toggleBloqueo(u.id!, isBloqueado);
                          } else if (val == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('¿Dar de baja?'),
                                content: const Text('El usuario ya no podrá ingresar al sistema.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true), 
                                    child: const Text('Dar de baja')
                                  ),
                                ],
                              )
                            );
                            if (confirm == true && mounted) {
                              await controller.darDeBaja(u.id!);
                            }
                          } else if (val == 'reset') {
                            _showRecuperarDialog(u.correo ?? '');
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('Editar Datos')),
                          PopupMenuItem(value: 'block', child: Text(isBloqueado ? 'Desbloquear' : 'Bloquear')),
                          const PopupMenuItem(value: 'reset', child: Text('Restablecer (Enviar código)')),
                          const PopupMenuItem(value: 'delete', child: Text('Dar de baja', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  );
                },
              ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.secondary,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuarioFormScreen())),
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }
}
