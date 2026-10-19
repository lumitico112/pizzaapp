import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/core/theme/app_theme.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/screens/configuracion/configuracion_negocio_screen.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// FS-4 (SEC-022, SEC-023, SEC-024): flujo QR administrativo y de cobro.
/// - SEC-022: rol no autorizado no cambia la configuración ni el QR.
/// - SEC-023: un fallo al persistir conserva los valores previos (incluido el
///   QR) y avisa al usuario.
/// - SEC-024: el cobro Yape/Plin consume la fuente de verdad
///   (`Configuracion.qr_ventas_ruta`), no un archivo temporal obsoleto.
///
/// Consumo verificado por inspección en `pos_cobro_sheet.dart:90-105` (lee
/// `qr_ventas_ruta` al abrir el sheet), `:795-797` (exige archivo existente) y
/// `:841-857` (estado explícito "QR de ventas no configurado").
class _Launcher extends StatelessWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ConfiguracionNegocioScreen(),
            ),
          ),
          child: const Text('Abrir configuración'),
        ),
      ),
    );
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Igual que router_guards_test: en widget tests la fuente por defecto tiene
  // métricas anchas; se registra la Poppins real antes de montar nada.
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
  late ConfiguracionRepository configRepo;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
    configRepo = ConfiguracionRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> crearUsuario({
    required String rol,
    required String username,
    String password = 'ClaveSegura1',
  }) {
    return db.insert('Usuarios', {
      'nombre': rol == 'admin' ? 'Administradora QR' : 'Empleado QR',
      'username': username,
      'password_hash': HashUtils.hashPassword(password, iterations: 1000),
      'rol': rol,
      'activo': 1,
      'bloqueado': 0,
    });
  }

  Future<AuthController> iniciarSesionComo(
    String username, [
    String password = 'ClaveSegura1',
  ]) async {
    final auth = AuthService(UsuarioRepository());
    await auth.login(username, password);
    return AuthController(auth);
  }

  Future<String> valorConfig(String clave) async {
    return await configRepo.getConfig(clave) ?? '<sin valor>';
  }

  Future<void> sembrarConfiguracionBase({required String qrRuta}) {
    return configRepo.saveConfigs({
      'nombre_negocio': 'Negocio Previo',
      'ruc_dni': '10602462353',
      'direccion_negocio': 'Av. Siempre 123',
      'telefono_negocio': '999888777',
      'mensaje_ticket': 'Gracias por su compra',
      'qr_ventas_ruta': qrRuta,
    });
  }

  /// Simula un fallo de persistencia a mitad de la transacción de guardado
  /// (disparador temporal, solo para la prueba).
  Future<void> instalarFalloDePersistencia() {
    return db.execute('''
      CREATE TRIGGER simular_fallo_persistencia
      BEFORE INSERT ON Configuracion
      WHEN NEW.valor = 'FORZAR_FALLO'
      BEGIN
        SELECT RAISE(ABORT, 'fallo simulado de persistencia');
      END
    ''');
  }

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// Deja que las cargas asíncronas reales (BD en memoria) terminen y repinta.
  /// No se usa `pumpAndSettle` mientras hay cargas en curso: el indicador de
  /// progreso anima sin parar y agota el tiempo del reloj simulado.
  Future<void> settleRealAsync(WidgetTester tester, {int rounds = 3}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
  }

  Future<void> abrirPantalla(WidgetTester tester, AuthController auth) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const _Launcher(),
        ),
      ),
    );
    await tester.tap(find.text('Abrir configuración'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settleRealAsync(tester, rounds: 4);
  }

  Directory crearDirectorioTemporal(String prefijo) {
    final dir = Directory.systemTemp.createTempSync(prefijo);
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    return dir;
  }

  /// PNG 1x1 válido: la tarjeta de QR de la pantalla previsualiza el archivo,
  /// así que bytes arbitrarios harían fallar el decodificador de imágenes.
  File crearQrPng(String ruta) {
    final file = File(ruta);
    file.writeAsBytesSync(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );
    return file;
  }

  group('SEC-022: rol no autorizado no cambia el QR', () {
    testWidgets(
      'T1: el empleado ve Acceso Restringido y la configuración queda intacta',
      (tester) async {
        usePhoneSurface(tester);
        final dir = crearDirectorioTemporal('qr_fs4_emp_');
        final qr = crearQrPng('${dir.path}/qr_previo.png');

        late AuthController auth;
        await tester.runAsync(() async {
          await crearUsuario(rol: 'empleado', username: 'empleado_qr');
          await sembrarConfiguracionBase(qrRuta: qr.path);
          auth = await iniciarSesionComo('empleado_qr');
        });

        await abrirPantalla(tester, auth);

        expect(find.text('Acceso Restringido'), findsOneWidget);
        expect(find.text('Guardar cambios'), findsNothing);

        final nombre = await tester.runAsync(
          () => valorConfig('nombre_negocio'),
        );
        final ruta = await tester.runAsync(
          () => valorConfig('qr_ventas_ruta'),
        );
        expect(nombre, 'Negocio Previo');
        expect(ruta, qr.path);
      },
    );

    testWidgets(
      'T2: la administradora guarda y el QR persistido es el configurado',
      (tester) async {
        usePhoneSurface(tester);
        final dir = crearDirectorioTemporal('qr_fs4_admin_');
        final qr = crearQrPng('${dir.path}/qr_actual.png');

        late AuthController auth;
        await tester.runAsync(() async {
          await crearUsuario(rol: 'admin', username: 'admin_qr');
          await sembrarConfiguracionBase(qrRuta: qr.path);
          auth = await iniciarSesionComo('admin_qr');
        });

        await abrirPantalla(tester, auth);
        expect(find.text('Negocio Previo'), findsOneWidget);

        await tester.ensureVisible(find.byType(TextFormField).first);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Negocio Nuevo',
        );
        // Deja que el cursor ajuste su visibilidad antes de desplazarse al
        // botón; si no, ese ajuste revierte el scroll y el tap no impacta.
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Guardar cambios'));
        await tester.pump();
        await tester.tap(find.text('Guardar cambios'));
        await settleRealAsync(tester, rounds: 4);
        await tester.pumpAndSettle();

        expect(find.byType(ConfiguracionNegocioScreen), findsNothing);
        expect(
          find.text('Configuración guardada exitosamente.'),
          findsOneWidget,
        );

        final nombre = await tester.runAsync(
          () => valorConfig('nombre_negocio'),
        );
        final ruta = await tester.runAsync(
          () => valorConfig('qr_ventas_ruta'),
        );
        expect(nombre, 'Negocio Nuevo');
        expect(ruta, qr.path);
      },
    );
  });

  group('SEC-023: fallo al persistir conserva el QR y avisa', () {
    test(
      'T3: el guardado fallido revierte la transacción y conserva el QR previo',
      () async {
        final dir = crearDirectorioTemporal('qr_fs4_rollback_');
        final qrPrevio = crearQrPng('${dir.path}/qr_previo.png');
        final qrNuevo = crearQrPng('${dir.path}/qr_nuevo.png');

        await sembrarConfiguracionBase(qrRuta: qrPrevio.path);
        await instalarFalloDePersistencia();

        await expectLater(
          () => configRepo.saveConfigs({
            'nombre_negocio': 'Negocio Nuevo',
            'qr_ventas_ruta': qrNuevo.path,
            'mensaje_ticket': 'FORZAR_FALLO',
          }),
          throwsA(isA<Exception>()),
        );

        expect(await valorConfig('nombre_negocio'), 'Negocio Previo');
        expect(await valorConfig('qr_ventas_ruta'), qrPrevio.path);
      },
    );

    testWidgets(
      'T4: en la pantalla, el fallo muestra aviso y mantiene los valores previos',
      (tester) async {
        usePhoneSurface(tester);
        final dir = crearDirectorioTemporal('qr_fs4_widget_fallo_');
        final qr = crearQrPng('${dir.path}/qr_previo.png');

        late AuthController auth;
        await tester.runAsync(() async {
          await crearUsuario(rol: 'admin', username: 'admin_qr');
          await sembrarConfiguracionBase(qrRuta: qr.path);
          // El valor sembrado activará el fallo simulado al guardar.
          await configRepo.saveConfig('mensaje_ticket', 'FORZAR_FALLO');
          await instalarFalloDePersistencia();
          auth = await iniciarSesionComo('admin_qr');
        });

        await abrirPantalla(tester, auth);

        await tester.ensureVisible(find.byType(TextFormField).first);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Negocio Nuevo',
        );
        // Deja que el cursor ajuste su visibilidad antes de desplazarse al
        // botón; si no, ese ajuste revierte el scroll y el tap no impacta.
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Guardar cambios'));
        await tester.pump();
        await tester.tap(find.text('Guardar cambios'));
        await settleRealAsync(tester, rounds: 4);

        expect(
          find.text(
            'No se pudo guardar la configuración. Inténtalo de nuevo.',
          ),
          findsOneWidget,
        );
        expect(find.byType(ConfiguracionNegocioScreen), findsOneWidget);

        final nombre = await tester.runAsync(
          () => valorConfig('nombre_negocio'),
        );
        final ruta = await tester.runAsync(
          () => valorConfig('qr_ventas_ruta'),
        );
        expect(nombre, 'Negocio Previo');
        expect(ruta, qr.path);
      },
    );
  });

  group('SEC-024: el cobro usa la fuente de verdad verificada', () {
    test(
      'T5: la ruta configurada manda aunque existan archivos previos en disco',
      () async {
        final dir = crearDirectorioTemporal('qr_fs4_src_');
        final qrViejo = crearQrPng('${dir.path}/qr_viejo.png');
        final qrNuevo = crearQrPng('${dir.path}/qr_nuevo.png');

        await configRepo.saveConfigs({'qr_ventas_ruta': qrViejo.path});
        expect(await valorConfig('qr_ventas_ruta'), qrViejo.path);
        expect(qrViejo.existsSync(), isTrue);

        await configRepo.saveConfigs({'qr_ventas_ruta': qrNuevo.path});
        expect(await valorConfig('qr_ventas_ruta'), qrNuevo.path);
        expect(await valorConfig('qr_ventas_ruta'), isNot(qrViejo.path));
      },
    );

    test(
      'T6: quitar el QR elimina la clave y deja el estado no configurado',
      () async {
        await configRepo.saveConfigs({
          'nombre_negocio': 'Negocio Previo',
          'qr_ventas_ruta': 'C:/ruta/inexistente/qr.png',
        });

        await configRepo.saveConfigs(
          const {},
          deleteKeys: const ['qr_ventas_ruta'],
        );

        expect(await valorConfig('qr_ventas_ruta'), '<sin valor>');
        expect(await valorConfig('nombre_negocio'), 'Negocio Previo');
      },
    );
  });
}
