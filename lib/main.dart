import 'dart:async';

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
import 'package:pizzaapp/features/insumos/data/repositories/sqlite_insumo_catalog_repository.dart';
import 'package:pizzaapp/features/insumos/domain/usecases/insumo_catalog_use_cases.dart';
import 'package:pizzaapp/features/insumos/presentation/controllers/insumo_controller.dart';
import 'package:pizzaapp/services/categoria_insumo_service.dart';
import 'package:pizzaapp/controllers/categoria_insumo_controller.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/services/reportes_service.dart';
import 'package:pizzaapp/controllers/reporte_controller.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/features/purchases/application/compra_service.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/features/purchases/domain/usecases/register_payable_payment.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/compras_controller.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/por_pagar_controller.dart';
import 'package:pizzaapp/services/producto_service.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/controllers/categoria_producto_controller.dart';
import 'package:pizzaapp/services/receta_service.dart';
import 'package:pizzaapp/controllers/receta_controller.dart';
import 'package:pizzaapp/features/preparation/application/preparacion_service.dart';
import 'package:pizzaapp/features/preparation/presentation/controllers/preparacion_controller.dart';
import 'package:pizzaapp/features/preparation/presentation/controllers/sugerencia_controller.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/services/caja_service.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/features/waste/application/merma_service.dart';
import 'package:pizzaapp/features/waste/presentation/controllers/merma_controller.dart';
import 'package:pizzaapp/features/waste/data/repositories/merma_repository.dart';
import 'package:pizzaapp/features/preparation/data/repositories/preparacion_repository.dart';
import 'package:pizzaapp/features/assets/data/repositories/asset_repository.dart';
import 'package:pizzaapp/features/assets/application/asset_service.dart';
import 'package:pizzaapp/features/assets/presentation/controllers/asset_controller.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/app/app_router.dart';
import 'package:pizzaapp/repositories/receta_repository.dart';
import 'package:pizzaapp/features/backup/application/backup_service.dart';

import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/services/promocion_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Forzar inicialización de BD
  await DatabaseHelper.instance.database;
  // Verificar si ya existe el usuario admin
  final usuarioRepo = UsuarioRepository();
  final hasAdmin = await usuarioRepo.adminExists();
  // La copia local es una red de seguridad para fallos del dispositivo actual.
  // El respaldo portátil, con contraseña elegida por la dueña, se genera desde la app.
  if (hasAdmin) {
    // C-17: La copia local diaria se difiere fuera del arranque crítico para evitar congelar la UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackupService().createDailyLocalBackupIfDue().catchError((_) => false);
    });
  }

  // Injection de Dependencias inicial para arquitectura limpia

  final ventaRepo = VentaRepository();
  final insumoRepo = InsumoRepository();
  final purchaseRepo = PurchaseRepository();
  final dashboardService = DashboardService(ventaRepo, purchaseRepo);
  final reporteService = ReportesService();

  final authService = AuthService(usuarioRepo);
  final usuarioService = UsuarioService(usuarioRepo, authService);
  final configRepo = ConfiguracionRepository();
  final onboardingService = OnboardingService(configRepo, authService);

  final insumoCatalog = InsumoCatalogUseCases(
    SqliteInsumoCatalogRepository(insumoRepo),
  );
  final categoriaInsumoService = CategoriaInsumoService(insumoRepo);

  final productoRepo = ProductoRepository();
  final cajaRepo = CajaRepository();

  final posService = PosService(
    productoRepo,
    ventaRepo,
    cajaRepo,
    PromocionRepository(),
  );

  final productoService = ProductoService(productoRepo);
  final recetaRepo = RecetaRepository();
  final recetaService = RecetaService(recetaRepo);
  final preparacionRepo = PreparacionRepository();
  final mermaRepo = MermaRepository();
  final preparacionService = PreparacionService(
    preparacionRepo,
    mermaRepo,
    cajaRepo,
  );
  final gastoRepo = GastoRepository();
  final compraService = CompraService(
    purchaseRepo,
    gastoRepo,
    authService,
    RegisterPayablePayment(purchaseRepo),
  );

  final cajaService = CajaService(cajaRepo, authService);
  final mermaService = MermaService(mermaRepo);
  final activoFijoRepo = ActivoFijoRepository();
  final activoFijoService = ActivoFijoService(activoFijoRepo, authService);
  final categoriaActivoRepo = CategoriaActivoRepository();
  final categoriaActivoService = CategoriaActivoService(categoriaActivoRepo);
  final proveedorRepo = ProveedorRepository();
  final proveedorService = ProveedorService(proveedorRepo);

  final promocionRepo = PromocionRepository();
  final promocionService = PromocionService(promocionRepo);
  final posController = PosController(posService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ActivoFijoController(activoFijoService),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoriaActivoController(categoriaActivoService),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardController(dashboardService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReporteController(reporteService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            authService,
            onLogout: posController.limpiarCarrito,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsuarioController(usuarioService),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingController(onboardingService),
        ),
        ChangeNotifierProvider(create: (_) => InsumoController(insumoCatalog)),
        ChangeNotifierProvider(
          create: (_) => CategoriaInsumoController(categoriaInsumoService),
        ),
        ChangeNotifierProvider.value(value: posController),
        ChangeNotifierProvider(create: (_) => ComprasController(compraService)),
        ChangeNotifierProvider(
          create: (_) => PorPagarController(compraService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductoController(productoService),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoriaProductoController(productoService),
        ),
        ChangeNotifierProvider(create: (_) => RecetaController(recetaService)),
        ChangeNotifierProvider(
          create: (_) =>
              PreparacionController(preparacionService, productoService),
        ),
        ChangeNotifierProvider(
          create: (_) => SugerenciaController(preparacionService),
        ),
        ChangeNotifierProvider(create: (_) => CajaController(cajaService)),
        ChangeNotifierProvider(create: (_) => MermaController(mermaService)),
        ChangeNotifierProvider(
          create: (_) => ProveedorController(proveedorService),
        ),
        ChangeNotifierProvider(
          create: (_) => PromocionController(promocionService),
        ),
      ],
      child: PizzApp(hasAdmin: hasAdmin),
    ),
  );
}

class PizzApp extends StatefulWidget {
  final bool hasAdmin;

  const PizzApp({super.key, required this.hasAdmin});

  @override
  State<PizzApp> createState() => _PizzAppState();
}

class _PizzAppState extends State<PizzApp> with WidgetsBindingObserver {
  final _backupService = BackupService();
  Timer? _backupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _backupService.createDailyLocalBackupIfDue().catchError((_) => false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backupTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.hasAdmin) {
      _backupService.createDailyLocalBackupIfDue().catchError((_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PizzApp',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      // Flutter normalmente descompone rutas como /login en / y /login.
      // Como la app no tiene una pantalla raíz independiente, esa ruta /
      // caía en la pantalla desconocida y quedaba debajo del dashboard.
      onGenerateInitialRoutes: (initialRoute) => [
        AppRouter.generateRoute(RouteSettings(name: initialRoute)),
      ],
      initialRoute: widget.hasAdmin ? AppRoutes.login : AppRoutes.onboarding,
    );
  }
}
