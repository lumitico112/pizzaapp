import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/app/app_router.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/controllers/onboarding_controller.dart';
import 'package:pizzaapp/core/theme/app_theme.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/screens/auth/login_screen.dart';
import 'package:pizzaapp/screens/auth/onboarding_screen.dart';
import 'package:pizzaapp/screens/dashboard/dashboard_screen.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/dashboard_service.dart';
import 'package:pizzaapp/services/onboarding_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Servicio de dashboard sin base de datos: devuelve un resumen vacío, de modo
/// que T2 no dependa de consultas reales desde la zona de reloj simulado.
class _FakeDashboardService extends Fake implements DashboardService {
  @override
  Future<DashboardSummary> obtenerResumenDelDia() async => DashboardSummary();
}

/// Fase 9 (H-08): guardas de sesión en rutas protegidas.
/// Alcance aprobado: solo sesión (T4 de rol no aplica).
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // En los widget tests el estilo por defecto usa una fuente de prueba con
  // métricas anchas; se registra la Poppins real (la que empaqueta la app)
  // antes de montar nada para que el layout no difiera de producción.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fontLoader = FontLoader('Poppins');
    for (final file in const [
      'Poppins-Thin',
      'Poppins-ExtraLight',
      'Poppins-Light',
      'Poppins-Regular',
      'Poppins-Italic',
      'Poppins-Medium',
      'Poppins-SemiBold',
      'Poppins-Bold',
      'Poppins-ExtraBold',
      'Poppins-Black',
    ]) {
      fontLoader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await fontLoader.load();

    // google_fonts registra familias compuestas (p. ej. "Poppins_700") que
    // carga de forma asíncrona; se disparan y esperan aquí para que ya el
    // primer frame del test use las métricas reales de Poppins.
    final estilosPoppins = [
      GoogleFonts.poppins(),
      GoogleFonts.poppins(fontWeight: FontWeight.w500),
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.bold),
      GoogleFonts.poppins(fontWeight: FontWeight.w800),
      GoogleFonts.poppins(fontWeight: FontWeight.w900),
    ];
    await GoogleFonts.pendingFonts(estilosPoppins);
  });

  late Database db;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Widget buildApp({
    required String initialRoute,
    required List<SingleChildWidget> providers,
  }) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        onGenerateInitialRoutes: (route) => [
          AppRouter.generateRoute(RouteSettings(name: route)),
        ],
        initialRoute: initialRoute,
      ),
    );
  }

  /// Deja que las cargas asíncronas reales (lecturas de configuración contra
  /// la base en memoria) terminen y repinta: `pump` no basta dentro del reloj
  /// simulado de los widget tests.
  Future<void> settleRealAsync(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
  }

  testWidgets(
    'T1 H-08: /dashboard sin sesión muestra LoginScreen (y no monta el Dashboard)',
    (tester) async {
      usePhoneSurface(tester);
      final authController = AuthController(AuthService(UsuarioRepository()));

      await tester.pumpWidget(
        buildApp(
          initialRoute: AppRoutes.dashboard,
          providers: [ChangeNotifierProvider.value(value: authController)],
        ),
      );
      await tester.pump();

      expect(authController.haySesion, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      await settleRealAsync(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'T2 H-08: /dashboard con sesión activa (admin del harness de fase 4) muestra DashboardScreen',
    (tester) async {
      usePhoneSurface(tester);
      late AuthController authController;

      await tester.runAsync(() async {
        await db.insert('Usuarios', {
          'nombre': 'Admin Guardia',
          'username': 'admin_guard',
          'password_hash': HashUtils.hashPassword(
            'AdminPass123',
            iterations: 10000,
          ),
          'rol': 'admin',
          'activo': 1,
          'bloqueado': 0,
        });
        final authService = AuthService(UsuarioRepository());
        await authService.login('admin_guard', 'AdminPass123');
        authController = AuthController(authService);
      });

      await tester.pumpWidget(
        buildApp(
          initialRoute: AppRoutes.dashboard,
          providers: [
            ChangeNotifierProvider.value(value: authController),
            ChangeNotifierProvider(
              create: (_) => DashboardController(_FakeDashboardService()),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await settleRealAsync(tester);

      expect(authController.haySesion, isTrue);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets(
    'T3 H-08: /login y /onboarding son rutas públicas (accesibles sin sesión)',
    (tester) async {
      usePhoneSurface(tester);
      final authController = AuthController(AuthService(UsuarioRepository()));

      await tester.pumpWidget(
        buildApp(
          initialRoute: AppRoutes.login,
          providers: [ChangeNotifierProvider.value(value: authController)],
        ),
      );
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
      await settleRealAsync(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      final onboardingController = OnboardingController(
        OnboardingService(
          ConfiguracionRepository(),
          AuthService(UsuarioRepository()),
        ),
      );
      await tester.pumpWidget(
        buildApp(
          initialRoute: AppRoutes.onboarding,
          providers: [
            ChangeNotifierProvider.value(value: onboardingController),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await settleRealAsync(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );
}
