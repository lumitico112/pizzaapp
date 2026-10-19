import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/screens/auth/login_screen.dart';

/// Guarda de sesión para las rutas protegidas del router (H-08).
///
/// Lee [AuthController] del árbol de providers: con sesión activa muestra
/// [child]; sin sesión devuelve la pantalla de inicio de sesión, sin añadir
/// navegación propia (el login ya navega con `replace` al dashboard).
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.haySesion) {
      return const LoginScreen();
    }
    return child;
  }
}
