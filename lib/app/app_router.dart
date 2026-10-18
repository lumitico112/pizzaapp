import 'package:flutter/material.dart';
import 'package:pizzaapp/screens/auth/login_screen.dart';
import 'package:pizzaapp/screens/auth/onboarding_screen.dart';
import 'package:pizzaapp/screens/dashboard/dashboard_screen.dart';
import 'package:pizzaapp/screens/insumos/insumos_screen.dart';
import 'package:pizzaapp/screens/insumos/insumo_form_screen.dart';
import 'package:pizzaapp/screens/catalogo/catalogo_screen.dart';
import 'package:pizzaapp/screens/catalogo/producto_form_screen.dart';
import 'package:pizzaapp/screens/compras/compras_screen.dart';
import 'package:pizzaapp/screens/compras/por_pagar_screen.dart';
import 'package:pizzaapp/screens/pos/pos_screen.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';
import 'package:pizzaapp/screens/preparacion/sugerencias_screen.dart';
import 'package:pizzaapp/screens/mermas/mermas_screen.dart';
import 'package:pizzaapp/features/assets/presentation/screens/assets_screen.dart';
import 'package:pizzaapp/features/assets/presentation/screens/asset_form_screen.dart';
import 'package:pizzaapp/screens/caja/caja_screen.dart';
import 'package:pizzaapp/screens/reportes/reportes_screen.dart';
import 'package:pizzaapp/screens/usuarios/usuarios_screen.dart';
import 'package:pizzaapp/screens/usuarios/usuario_form_screen.dart';
import 'package:pizzaapp/screens/proveedores/proveedores_screen.dart';
import 'package:pizzaapp/screens/promociones/promociones_screen.dart';
import 'package:pizzaapp/screens/promociones/promocion_form_screen.dart';

/// Router centralizado de la aplicaciÃ³n.
/// NUNCA usar Navigator.push con MaterialPageRoute hardcoded.
/// Siempre usar AppRouter.push(context, AppRoutes.xxx)

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static const String insumos = '/insumos';
  static const String insumoForm = '/insumos/form';

  static const String catalogo = '/catalogo';
  static const String productoForm = '/catalogo/form';
  static const String receta = '/catalogo/receta';

  static const String compras = '/compras';
  static const String porPagar = '/compras/por-pagar';

  static const String pos = '/pos';

  static const String preparacion = '/preparacion';
  static const String sugerencias = '/preparacion/sugerencias';

  static const String mermas = '/mermas';

  static const String activosFijos = '/activos';
  static const String activoFijoForm = '/activos/form';

  static const String caja = '/caja';
  static const String reportes = '/reportes';

  static const String usuarios = '/usuarios';
  static const String usuarioForm = '/usuarios/form';
  static const String proveedores = '/proveedores';

  static const String promociones = '/promociones';
  static const String promocionForm = '/promociones/form';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return _build(const OnboardingScreen());
      case AppRoutes.login:
        return _build(const LoginScreen());
      case AppRoutes.dashboard:
        return _build(const DashboardScreen());
      case AppRoutes.insumos:
        return _build(const InsumosScreen());
      case AppRoutes.insumoForm:
        return _build(
          InsumoFormScreen(insumoAEditar: settings.arguments as dynamic),
        );
      case AppRoutes.catalogo:
        return _build(const CatalogoScreen());
      case AppRoutes.productoForm:
        return _build(
          ProductoFormScreen(productoAEditar: settings.arguments as dynamic),
        );
      case AppRoutes.compras:
        return _build(const ComprasScreen());
      case AppRoutes.porPagar:
        return _build(const PorPagarScreen());
      case AppRoutes.pos:
        return _build(const PosScreen());
      case AppRoutes.preparacion:
        return _build(const RegistroPreparacionScreen());
      case AppRoutes.sugerencias:
        return _build(const SugerenciasScreen());
      case AppRoutes.mermas:
        return _build(const MermasScreen());
      case AppRoutes.activosFijos:
        return _build(const ActivosFijosScreen());
      case AppRoutes.activoFijoForm:
        return _build(
          ActivoFijoFormScreen(activoAEditar: settings.arguments as dynamic),
        );
      case AppRoutes.caja:
        return _build(const CajaScreen());
      case AppRoutes.reportes:
        return _build(const ReportesScreen());
      case AppRoutes.usuarios:
        return _build(const UsuariosScreen());
      case AppRoutes.usuarioForm:
        return _build(UsuarioFormScreen(usuarioId: settings.arguments as int?));
      case AppRoutes.proveedores:
        return _build(const ProveedoresScreen());
      case AppRoutes.promociones:
        return _build(const PromocionesScreen());
      case AppRoutes.promocionForm:
        return _build(
          PromocionFormScreen(promocionAEditar: settings.arguments as dynamic),
        );
      default:
        return _build(
          const Scaffold(body: Center(child: Text('Pantalla no encontrada'))),
        );
    }
  }

  static PageRouteBuilder _build(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Navegar a una ruta con fade transition
  static Future<T?> push<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) async {
    // generateRoute crea PageRouteBuilder<dynamic>. Solicitar aquí una ruta
    // tipada (por ejemplo bool para los formularios) provoca un cast antes
    // incluso de que la pantalla llegue a abrirse.
    final result = await Navigator.pushNamed<dynamic>(
      context,
      route,
      arguments: arguments,
    );
    return result as T?;
  }

  /// Reemplazar la ruta actual
  static Future<T?> replace<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, void>(
      context,
      route,
      arguments: arguments,
    );
  }

  /// Ir al login eliminando todo el stack
  static void toLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Ir al dashboard eliminando todo el stack
  static void toDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }
}
