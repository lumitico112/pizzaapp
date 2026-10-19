import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/controllers/usuario_controller.dart';
import 'package:pizzaapp/core/theme/app_theme.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/screens/usuarios/usuarios_screen.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:pizzaapp/services/usuario_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase FS-6: acceso, cuentas y sesión (SEC-001…SEC-010).
///
/// Límite declarado (S2 de AGENTS.md de la edición): la app es local-only. Las
/// pruebas verifican las defensas reales (login, sesión, autorización de
/// servicio, auditoría y UI); no prometen resistencia frente a un atacante con
/// control del dispositivo, root o un APK modificado.
class _FakePosService extends Fake implements PosService {}

class _FakeUsuarioService extends Fake implements UsuarioService {
  @override
  Future<List<Usuario>> obtenerUsuarios({bool incluirInactivos = false}) async {
    return <Usuario>[];
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() async {
    // Poppins real del bundle: evita overflow por métricas de la fuente de test.
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
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.bold),
    ]);
  });

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> insertUser({
    required String nombre,
    required String username,
    required String password,
    String rol = 'empleado',
    int activo = 1,
    int bloqueado = 0,
  }) {
    return db.insert('Usuarios', {
      'nombre': nombre,
      'username': username,
      'password_hash': HashUtils.hashPassword(password, iterations: 1000),
      'rol': rol,
      'activo': activo,
      'bloqueado': bloqueado,
    });
  }

  Future<Map<String, dynamic>> userRow(int id) async {
    final rows = await db.query('Usuarios', where: 'id = ?', whereArgs: [id]);
    return rows.first;
  }

  Future<int> activeAdminCount() async {
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM Usuarios "
      "WHERE rol = 'admin' AND activo = 1 AND COALESCE(bloqueado, 0) = 0",
    );
    return rows.first['c'] as int;
  }

  Future<int> auditCountFor(int userId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM LogAuditoria WHERE usuario_id = ?',
      [userId],
    );
    return rows.first['c'] as int;
  }

  // ---------------------------------------------------------------------------
  // SEC-001 — Credenciales inválidas
  // ---------------------------------------------------------------------------

  test(
    'SEC-001: credenciales inválidas se rechazan con mensaje genérico y sin abrir sesión',
    () async {
      await insertUser(
        nombre: 'Admin Sec1',
        username: 'admin_sec1',
        password: 'AdminPass123',
        rol: 'admin',
      );
      final auth = AuthService(UsuarioRepository());

      // Campos vacíos: error de validación, no cuenta como intento fallido.
      await expectLater(
        () => auth.login('', ''),
        throwsA(
          predicate(
            (e) => e.toString().contains('Usuario y contraseña son requeridos.'),
          ),
        ),
      );
      expect(auth.failedAttempts, 0);

      // Contraseña incorrecta y usuario inexistente: mismo mensaje genérico
      // (no se revela si el usuario existe o está inactivo).
      for (final credenciales in [
        ('admin_sec1', 'Incorrecta123'),
        ('usuario_inexistente', 'Cualquiera123'),
      ]) {
        await expectLater(
          () => auth.login(credenciales.$1, credenciales.$2),
          throwsA(
            predicate(
              (e) => e
                  .toString()
                  .contains('Credenciales incorrectas o usuario inactivo.'),
            ),
          ),
        );
        expect(auth.currentUser, isNull);
      }
      expect(auth.failedAttempts, 2);
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-002 — Repetición rápida de intentos
  // ---------------------------------------------------------------------------

  test(
    'SEC-002: 5 intentos fallidos activan 30 s de espera y el login correcto se rechaza durante el bloqueo',
    () async {
      await insertUser(
        nombre: 'Admin Sec2',
        username: 'admin_sec2',
        password: 'AdminPass123',
        rol: 'admin',
      );
      var now = DateTime(2026, 10, 19, 10, 0, 0);
      final auth = AuthService(UsuarioRepository(), clock: () => now);

      for (var i = 0; i < 4; i++) {
        await expectLater(
          () => auth.login('admin_sec2', 'Incorrecta123'),
          throwsA(
            predicate(
              (e) => e.toString().contains('Credenciales incorrectas'),
            ),
          ),
        );
      }

      await expectLater(
        () => auth.login('admin_sec2', 'Incorrecta123'),
        throwsA(
          predicate(
            (e) => e.toString().contains('Demasiados intentos fallidos'),
          ),
        ),
      );
      expect(auth.failedAttempts, 5);
      expect(auth.lockedUntil, isNotNull);

      // Durante el bloqueo ni siquiera la contraseña correcta entra.
      now = now.add(const Duration(seconds: 10));
      await expectLater(
        () => auth.login('admin_sec2', 'AdminPass123'),
        throwsA(
          predicate((e) => e.toString().contains('Espera 20 segundos')),
        ),
      );

      // Al expirar el enfriamiento, el login correcto funciona y resetea.
      now = now.add(const Duration(seconds: 21));
      final user = await auth.login('admin_sec2', 'AdminPass123');
      expect(user.username, 'admin_sec2');
      expect(auth.failedAttempts, 0);
      expect(auth.lockedUntil, isNull);
    },
  );

  test(
    'SEC-002 (limitación conocida): el contador es en memoria y no sobrevive a una instancia nueva',
    () async {
      await insertUser(
        nombre: 'Admin Sec2b',
        username: 'admin_sec2b',
        password: 'AdminPass123',
        rol: 'admin',
      );
      final first = AuthService(UsuarioRepository());
      for (var i = 0; i < 4; i++) {
        await expectLater(
          () => first.login('admin_sec2b', 'Incorrecta123'),
          throwsA(
            predicate(
              (e) => e.toString().contains('Credenciales incorrectas'),
            ),
          ),
        );
      }
      await expectLater(
        () => first.login('admin_sec2b', 'Incorrecta123'),
        throwsA(
          predicate(
            (e) => e.toString().contains('Demasiados intentos fallidos'),
          ),
        ),
      );
      expect(first.lockedUntil, isNotNull);

      // Reiniciar la app (nueva instancia de AuthService) pierde el bloqueo.
      // Es el riesgo residual SEC-002 aceptado/documentado en la evidencia.
      final second = AuthService(UsuarioRepository());
      final user = await second.login('admin_sec2b', 'AdminPass123');
      expect(user.username, 'admin_sec2b');
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-005 — Cuenta desactivada o bloqueada
  // ---------------------------------------------------------------------------

  test(
    'SEC-005: cuentas inactivas o bloqueadas no acceden por login ni por loginRapido',
    () async {
      final activeId = await insertUser(
        nombre: 'Usuario Activo',
        username: 'activo_sec5',
        password: 'EmpPass123',
      );
      final inactiveId = await insertUser(
        nombre: 'Usuario Inactivo',
        username: 'inactivo_sec5',
        password: 'EmpPass123',
        activo: 0,
      );
      final blockedId = await insertUser(
        nombre: 'Usuario Bloqueado',
        username: 'bloqueado_sec5',
        password: 'EmpPass123',
        bloqueado: 1,
      );

      final auth = AuthService(UsuarioRepository());
      for (final username in ['inactivo_sec5', 'bloqueado_sec5']) {
        await expectLater(
          () => auth.login(username, 'EmpPass123'),
          throwsA(
            predicate(
              (e) => e
                  .toString()
                  .contains('Credenciales incorrectas o usuario inactivo.'),
            ),
          ),
        );
        expect(auth.currentUser, isNull);
      }

      // El acceso rápido con huella revalida activo/bloqueado contra la BD.
      for (final id in [inactiveId, blockedId]) {
        await expectLater(
          () => auth.loginRapido(id),
          throwsA(
            predicate(
              (e) => e.toString().contains('ya no tiene acceso'),
            ),
          ),
        );
      }

      final active = await auth.loginRapido(activeId);
      expect(active.username, 'activo_sec5');
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-003 / SEC-004 — Sesión local y logout
  // ---------------------------------------------------------------------------

  test(
    'SEC-003/004: logout elimina la sesión en memoria, invoca onLogout y vacía el carrito',
    () async {
      await insertUser(
        nombre: 'Admin Sec4',
        username: 'admin_sec4',
        password: 'AdminPass123',
        rol: 'admin',
      );
      final auth = AuthService(UsuarioRepository());
      await auth.login('admin_sec4', 'AdminPass123');

      final posController = PosController(_FakePosService());
      posController.carrito.add(CartItem(cantidad: 2));

      var logoutCalls = 0;
      final authController = AuthController(
        auth,
        onLogout: () {
          logoutCalls++;
          posController.limpiarCarrito();
        },
      );

      expect(authController.haySesion, isTrue);
      await authController.logout();

      expect(authController.haySesion, isFalse);
      expect(authController.currentUser, isNull);
      expect(auth.currentUser, isNull);
      expect(logoutCalls, 1);
      expect(posController.carrito, isEmpty);

      // Sin tokens remotos: una instancia nueva no hereda sesión.
      final fresh = AuthService(UsuarioRepository());
      expect(fresh.currentUser, isNull);
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-006 — Empleado en pantalla administrativa
  // ---------------------------------------------------------------------------

  testWidgets(
    'SEC-006: un empleado en la pantalla de usuarios ve "Acceso Restringido"',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      late AuthController authController;
      await tester.runAsync(() async {
        await insertUser(
          nombre: 'Empleado Sec6',
          username: 'emp_sec6',
          password: 'EmpPass123',
        );
        final auth = AuthService(UsuarioRepository());
        await auth.login('emp_sec6', 'EmpPass123');
        authController = AuthController(auth);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(
              value: authController,
            ),
            ChangeNotifierProvider<UsuarioController>(
              create: (_) => UsuarioController(_FakeUsuarioService()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const UsuariosScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Acceso Restringido'), findsOneWidget);
      expect(
        find.text('Solo el administrador puede gestionar los usuarios del sistema.'),
        findsOneWidget,
      );
      expect(find.text('Nuevo Usuario'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-007 — Manipulación de rol local
  // ---------------------------------------------------------------------------

  test(
    'SEC-007: un empleado no escala rol al editarse y la autorización admin revalida la BD',
    () async {
      final employeeId = await insertUser(
        nombre: 'Empleado Sec7',
        username: 'emp_sec7',
        password: 'EmpPass123',
      );
      final adminId = await insertUser(
        nombre: 'Admin Sec7',
        username: 'admin_sec7',
        password: 'AdminPass123',
        rol: 'admin',
      );

      final auth = AuthService(UsuarioRepository());
      await auth.login('emp_sec7', 'EmpPass123');
      final service = UsuarioService(UsuarioRepository(), auth);

      // Intento de autoescalada pasando rol admin en el formulario.
      await service.guardarUsuario(
        id: employeeId,
        nombre: 'Empleado Sec7',
        username: 'emp_sec7',
        password: null,
        rol: 'admin',
      );
      expect((await userRow(employeeId))['rol'], 'empleado');

      // Incluso si se manipula el usuario en memoria, la autorización sensible
      // revalida el rol y la contraseña contra la base de datos.
      final current = auth.currentUser!;
      auth.updateCurrentUser(
        Usuario(
          id: current.id,
          nombre: current.nombre,
          username: current.username,
          passwordHash: current.passwordHash,
          rol: 'admin',
          activo: 1,
          bloqueado: 0,
        ),
      );
      await expectLater(
        () => auth.authorizeAdminOperation('EmpPass123'),
        throwsA(
          predicate(
            (e) => e
                .toString()
                .contains('La contraseña de autorización no es válida.'),
          ),
        ),
      );

      // Un admin real sí puede autorizar (camino positivo).
      final adminAuth = AuthService(UsuarioRepository());
      await adminAuth.login('admin_sec7', 'AdminPass123');
      expect(await adminAuth.authorizeAdminOperation('AdminPass123'), adminId);
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-008 — IDOR/BOLA sobre IDs locales
  // ---------------------------------------------------------------------------

  test(
    'SEC-008: un empleado no puede modificar a otro usuario por ID y no hay cambios parciales',
    () async {
      await insertUser(
        nombre: 'Empleado Sec8',
        username: 'emp_sec8',
        password: 'EmpPass123',
      );
      final otherId = await insertUser(
        nombre: 'Otro Usuario',
        username: 'otro_sec8',
        password: 'OtraPass123',
      );
      final before = await userRow(otherId);

      final auth = AuthService(UsuarioRepository());
      await auth.login('emp_sec8', 'EmpPass123');
      final service = UsuarioService(UsuarioRepository(), auth);

      await expectLater(
        () => service.guardarUsuario(
          id: otherId,
          nombre: 'Hackeado',
          username: 'hackeado',
          password: 'NuevaPass123',
          rol: 'admin',
        ),
        throwsA(
          predicate(
            (e) => e
                .toString()
                .contains('No tienes permisos para editar otro usuario.'),
          ),
        ),
      );

      final after = await userRow(otherId);
      expect(after['nombre'], before['nombre']);
      expect(after['username'], before['username']);
      expect(after['rol'], before['rol']);
      expect(after['password_hash'], before['password_hash']);

      // ID inexistente como admin: error de negocio, sin insertar nada.
      final adminAuth = AuthService(UsuarioRepository());
      await insertUser(
        nombre: 'Admin Sec8',
        username: 'admin_sec8',
        password: 'AdminPass123',
        rol: 'admin',
      );
      await adminAuth.login('admin_sec8', 'AdminPass123');
      final adminService = UsuarioService(UsuarioRepository(), adminAuth);
      await expectLater(
        () => adminService.guardarUsuario(
          id: 999999,
          nombre: 'Fantasma',
          username: 'fantasma',
          rol: 'empleado',
        ),
        throwsA(
          predicate((e) => e.toString().contains('Usuario no encontrado.')),
        ),
      );
      final ghosts = await db.query(
        'Usuarios',
        where: 'username = ?',
        whereArgs: ['fantasma'],
      );
      expect(ghosts, isEmpty);
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-009 — Ciclo de cuentas y auditoría
  // ---------------------------------------------------------------------------

  test(
    'SEC-009: alta/edición requieren admin, el ciclo se audita y un fallo de auditoría revierte',
    () async {
      final adminId = await insertUser(
        nombre: 'Admin Sec9',
        username: 'admin_sec9',
        password: 'AdminPass123',
        rol: 'admin',
      );
      await insertUser(
        nombre: 'Empleado Sec9',
        username: 'emp_sec9',
        password: 'EmpPass123',
      );

      // Empleado: no crea ni bloquea; sin cambios ni auditoría.
      final employeeAuth = AuthService(UsuarioRepository());
      await employeeAuth.login('emp_sec9', 'EmpPass123');
      final employeeService = UsuarioService(
        UsuarioRepository(),
        employeeAuth,
      );
      final usersBefore = (await db.query('Usuarios')).length;
      await expectLater(
        () => employeeService.guardarUsuario(
          id: null,
          nombre: 'Intruso',
          username: 'intruso_sec9',
          password: 'Intruso123',
          rol: 'admin',
        ),
        throwsA(
          // El servicio corta antes de entrar a la rama de creación; el
          // mensaje es de permisos de edición, pero la operación se rechaza.
          predicate((e) => e.toString().contains('No tienes permisos')),
        ),
      );
      await expectLater(
        () => employeeService.cambiarEstadoBloqueo(adminId, true),
        throwsA(predicate((e) => e.toString().contains('Solo admin.'))),
      );
      expect((await db.query('Usuarios')).length, usersBefore);
      expect(await auditCountFor(adminId), 0);

      // Admin: crea y edita.
      final adminAuth = AuthService(UsuarioRepository());
      await adminAuth.login('admin_sec9', 'AdminPass123');
      final adminService = UsuarioService(UsuarioRepository(), adminAuth);
      await adminService.guardarUsuario(
        id: null,
        nombre: 'Nuevo Usuario',
        username: 'nuevo_sec9',
        password: 'NuevaPass123',
        rol: 'empleado',
      );
      final created = (await db.query(
        'Usuarios',
        where: 'username = ?',
        whereArgs: ['nuevo_sec9'],
      )).first;
      final createdId = created['id'] as int;
      expect(created['rol'], 'empleado');
      expect(created['activo'], 1);

      await adminService.guardarUsuario(
        id: createdId,
        nombre: 'Nuevo Renombrado',
        username: 'nuevo_sec9b',
        rol: 'empleado',
      );
      expect((await userRow(createdId))['nombre'], 'Nuevo Renombrado');

      // Ciclo de estado: cada cambio deja auditoría con el actor.
      await adminService.cambiarEstadoBloqueo(createdId, true);
      await adminService.cambiarEstadoBloqueo(createdId, false);
      await adminService.darDeBaja(createdId);
      await adminService.reactivarUsuario(createdId);

      final audits = await db.query(
        'LogAuditoria',
        where: 'usuario_id = ?',
        whereArgs: [adminId],
        orderBy: 'id ASC',
      );
      expect(
        audits.map((row) => row['accion']).toList(),
        equals([
          'USUARIO_BLOQUEAR',
          'USUARIO_DESBLOQUEAR',
          'USUARIO_BAJA',
          'USUARIO_REACTIVAR',
        ]),
      );

      // Fallo de auditoría dentro de la transacción: el estado no cambia y no
      // queda una auditoría parcial.
      await db.execute('DROP TRIGGER IF EXISTS test_abort_audit');
      await db.execute(
        "CREATE TRIGGER test_abort_audit BEFORE INSERT ON LogAuditoria "
        "BEGIN SELECT RAISE(ABORT, 'audit fail'); END",
      );
      try {
        await expectLater(
          () => adminService.darDeBaja(createdId),
          throwsA(anything),
        );
      } finally {
        await db.execute('DROP TRIGGER IF EXISTS test_abort_audit');
      }
      expect((await userRow(createdId))['activo'], 1);
      expect(await auditCountFor(adminId), audits.length);
    },
  );

  // ---------------------------------------------------------------------------
  // SEC-010 — Última cuenta admin y recuperación controlada
  // ---------------------------------------------------------------------------

  test(
    'SEC-010: la última admin no puede auto-bloquearse ni auto-darse de baja y la recuperación es controlada',
    () async {
      final adminAId = await insertUser(
        nombre: 'Admin A',
        username: 'admin_sec10',
        password: 'AdminPass123',
        rol: 'admin',
      );
      final adminBId = await insertUser(
        nombre: 'Admin B',
        username: 'admin_b_sec10',
        password: 'AdminBPass123',
        rol: 'admin',
      );

      final auth = AuthService(UsuarioRepository());
      await auth.login('admin_sec10', 'AdminPass123');
      final service = UsuarioService(UsuarioRepository(), auth);

      // Auto-bloqueo y auto-baja: denegados, sin cambios ni auditoría.
      await expectLater(
        () => service.cambiarEstadoBloqueo(adminAId, true),
        throwsA(predicate((e) => e.toString().contains('ti mismo'))),
      );
      await expectLater(
        () => service.darDeBaja(adminAId),
        throwsA(predicate((e) => e.toString().contains('ti mismo'))),
      );
      final adminARow = await userRow(adminAId);
      expect(adminARow['activo'], 1);
      expect(adminARow['bloqueado'], 0);
      expect(await auditCountFor(adminAId), 0);

      // Al menos una cuenta admin permanece habilitada tras gestionar a la otra.
      expect(await activeAdminCount(), 2);
      await service.darDeBaja(adminBId);
      expect(await activeAdminCount(), 1);
      final adminBRow = await userRow(adminBId);
      expect(adminBRow['activo'], 0);

      // Recuperación: código de rescate de alta entropía, guardado como hash.
      final recoveryCode = await auth.createRecoveryCodeForCurrentAdmin();
      expect(recoveryCode, isNotNull);
      expect(recoveryCode.split('-').length, 4);
      final afterCode = await userRow(adminAId);
      expect(
        afterCode['recovery_code'],
        HashUtils.hashRecoveryCode(recoveryCode),
      );
      expect(afterCode['recovery_code'], isNot(equals(recoveryCode)));

      // Código incorrecto: rechazo; código correcto: nueva contraseña efectiva.
      await expectLater(
        () => auth.resetAdminPassword(
          username: 'admin_sec10',
          recoveryCode: 'CODIGO-INVALIDO',
          newPassword: 'NuevaClave123',
        ),
        throwsA(
          predicate(
            (e) => e
                .toString()
                .contains('Usuario o clave de rescate incorrectos.'),
          ),
        ),
      );
      await auth.resetAdminPassword(
        username: 'admin_sec10',
        recoveryCode: recoveryCode,
        newPassword: 'NuevaClave123',
      );
      auth.logout();

      await expectLater(
        () => auth.login('admin_sec10', 'AdminPass123'),
        throwsA(
          predicate(
            (e) => e
                .toString()
                .contains('Credenciales incorrectas o usuario inactivo.'),
          ),
        ),
      );
      final relogin = await auth.login('admin_sec10', 'NuevaClave123');
      expect(relogin.username, 'admin_sec10');
    },
  );
}
