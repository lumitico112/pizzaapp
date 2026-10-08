import 'package:flutter/material.dart';
import 'package:pizzaapp/core/theme/app_theme.dart';
import 'package:pizzaapp/repositories/categoria_activo_repository.dart';
import 'package:pizzaapp/services/categoria_activo_service.dart';
import 'package:pizzaapp/controllers/categoria_activo_controller.dart';
import 'package:pizzaapp/repositories/proveedor_repository.dart';
import 'package:pizzaapp/services/proveedor_service.dart';
import 'package:pizzaapp/controllers/proveedor_controller.dart';
import 'package:pizzaapp/controllers/promocion_controller.dart';

import 'package:provider/provider.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';
import 'package:pizzaapp/services/dashboard_service.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/services/usuario_service.dart';
import 'package:pizzaapp/controllers/usuario_controller.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/services/onboarding_service.dart';
import 'package:pizzaapp/controllers/onboarding_controller.dart';
import 'package:pizzaapp/services/insumo_service.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/services/categoria_insumo_service.dart';
import 'package:pizzaapp/controllers/categoria_insumo_controller.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/services/reportes_service.dart';
import 'package:pizzaapp/controllers/reporte_controller.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/services/compra_service.dart';
import 'package:pizzaapp/controllers/compras_controller.dart';
import 'package:pizzaapp/controllers/por_pagar_controller.dart';
import 'package:pizzaapp/services/producto_service.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/controllers/categoria_producto_controller.dart';
import 'package:pizzaapp/services/receta_service.dart';
import 'package:pizzaapp/controllers/receta_controller.dart';
import 'package:pizzaapp/services/preparacion_service.dart';
import 'package:pizzaapp/controllers/preparacion_controller.dart';
import 'package:pizzaapp/controllers/sugerencia_controller.dart';
import 'package:pizzaapp/services/gasto_service.dart';
import 'package:pizzaapp/controllers/gasto_controller.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/services/caja_service.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/services/merma_service.dart';
import 'package:pizzaapp/controllers/merma_controller.dart';
import 'package:pizzaapp/repositories/merma_repository.dart';
import 'package:pizzaapp/repositories/preparacion_repository.dart';
import 'package:pizzaapp/repositories/activo_fijo_repository.dart';
import 'package:pizzaapp/services/activo_fijo_service.dart';
import 'package:pizzaapp/controllers/activo_fijo_controller.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/app/app_router.dart';
import 'package:pizzaapp/repositories/receta_repository.dart';

import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/services/promocion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forzar inicialización de BD
  await DatabaseHelper.instance.database;

  // Verificar si ya existe el usuario admin
  final usuarioRepo = UsuarioRepository();
  final hasAdmin = await usuarioRepo.adminExists();

    // Injection de Dependencias inicial para arquitectura limpia

  final ventaRepo = VentaRepository();
  final insumoRepo = InsumoRepository();
  final dashboardService = DashboardService(ventaRepo, insumoRepo);
  final reporteService = ReportesService();

  final authService = AuthService(usuarioRepo);
  final usuarioService = UsuarioService(usuarioRepo, authService);
  final configRepo = ConfiguracionRepository();
  final onboardingService = OnboardingService(configRepo, authService);

  final insumoService = InsumoService(insumoRepo);
  final categoriaInsumoService = CategoriaInsumoService(insumoRepo);

  final productoRepo = ProductoRepository();
  final cajaRepo = CajaRepository();
  
  final posService = PosService(productoRepo, ventaRepo, cajaRepo);
  
  final productoService = ProductoService(productoRepo);
  final recetaRepo = RecetaRepository();
  final recetaService = RecetaService(recetaRepo);
  final preparacionRepo = PreparacionRepository();
  final preparacionService = PreparacionService(preparacionRepo, productoRepo, insumoRepo);
  final gastoRepo = GastoRepository();
  final gastoService = GastoService(gastoRepo);
  final compraService = CompraService(insumoRepo, gastoRepo, cajaRepo);
  
  final cajaService = CajaService(cajaRepo);
  final mermaRepo = MermaRepository();
  final mermaService = MermaService(mermaRepo, insumoRepo, productoRepo);
  final activoFijoRepo = ActivoFijoRepository();
  final activoFijoService = ActivoFijoService(activoFijoRepo, gastoRepo, insumoRepo);
  final categoriaActivoRepo = CategoriaActivoRepository();
  final categoriaActivoService = CategoriaActivoService(categoriaActivoRepo);
  final proveedorRepo = ProveedorRepository();
  final proveedorService = ProveedorService(proveedorRepo);

  final promocionRepo = PromocionRepository();
  final promocionService = PromocionService(promocionRepo);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivoFijoController(activoFijoService)),
        ChangeNotifierProvider(create: (_) => CategoriaActivoController(categoriaActivoService)),
        ChangeNotifierProvider(create: (_) => DashboardController(dashboardService)),
        ChangeNotifierProvider(create: (_) => ReporteController(reporteService)),
        ChangeNotifierProvider(create: (_) => AuthController(authService)),
        ChangeNotifierProvider(create: (_) => UsuarioController(usuarioService)),
        ChangeNotifierProvider(create: (_) => OnboardingController(onboardingService)),
        ChangeNotifierProvider(create: (_) => InsumoController(insumoService)),
        ChangeNotifierProvider(create: (_) => CategoriaInsumoController(categoriaInsumoService)),
        ChangeNotifierProvider(create: (_) => PosController(posService)),
        ChangeNotifierProvider(create: (_) => ComprasController(compraService)),
        ChangeNotifierProvider(create: (_) => PorPagarController(compraService)),
        ChangeNotifierProvider(create: (_) => ProductoController(productoService)),
        ChangeNotifierProvider(create: (_) => CategoriaProductoController(productoService)),
        ChangeNotifierProvider(create: (_) => RecetaController(recetaService)),
        ChangeNotifierProvider(create: (_) => PreparacionController(preparacionService, productoService)),
        ChangeNotifierProvider(create: (_) => SugerenciaController(preparacionService)),
        ChangeNotifierProvider(create: (_) => GastoController(gastoService)),
        ChangeNotifierProvider(create: (_) => CajaController(cajaService)),
        ChangeNotifierProvider(create: (_) => MermaController(mermaService)),
        ChangeNotifierProvider(create: (_) => ProveedorController(proveedorService)),
        ChangeNotifierProvider(create: (_) => PromocionController(promocionService)),
      ],
      child: PizzApp(hasAdmin: hasAdmin),
    ),
  );
}

class PizzApp extends StatelessWidget {
  final bool hasAdmin;

  const PizzApp({super.key, required this.hasAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PizzApp',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: hasAdmin ? AppRoutes.login : AppRoutes.onboarding,
    );
  }
}













