import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/onboarding_service.dart';
import 'package:pizzaapp/services/usuario_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  group('Fase 4 — Seguridad, PBKDF2, Rate Limiting y Recursos (C-06, C-17..C-30)', () {
    test(
      'C-06 / C-17: HashUtils genera PBKDF2 con sal aleatoria y UsuarioRepository migra SHA-256 legacy al autenticar',
      () async {
        final h1 = HashUtils.hashPassword('ClaveSegura123', iterations: 10000);
        final h2 = HashUtils.hashPassword('ClaveSegura123', iterations: 10000);
        expect(h1, startsWith('pbkdf2\$10000\$'));
        expect(h1, isNot(equals(h2)));
        expect(HashUtils.verifyPassword('ClaveSegura123', h1), isTrue);
        expect(HashUtils.verifyPassword('ClaveIncorrecta', h1), isFalse);
        expect(HashUtils.isLegacyHash(h1), isFalse);

        // Insertar usuario con hash SHA-256 legacy sin sal (64 hex chars)
        final legacySha256 = sha256
            .convert(utf8.encode('MiClaveLegacy99'))
            .toString();
        expect(HashUtils.isLegacyHash(legacySha256), isTrue);

        final userId = await db.insert('Usuarios', {
          'nombre': 'Cajero Legacy',
          'username': 'cajero_legacy',
          'password_hash': legacySha256,
          'rol': 'empleado',
          'activo': 1,
          'bloqueado': 0,
        });

        final repo = UsuarioRepository();
        final authenticated = await repo.authenticate(
          'cajero_legacy',
          'MiClaveLegacy99',
        );
        expect(authenticated, isNotNull);
        expect(authenticated!.passwordHash, startsWith('pbkdf2\$'));

        final rowAfter = (await db.query(
          'Usuarios',
          where: 'id = ?',
          whereArgs: [userId],
        )).first;
        final storedHash = rowAfter['password_hash'] as String;
        expect(storedHash, startsWith('pbkdf2\$310000\$'));
        expect(HashUtils.verifyPassword('MiClaveLegacy99', storedHash), isTrue);
      },
    );

    test(
      'C-18: AuthService aplica enfriamiento de 30s tras 5 intentos fallidos consecutivos y se recupera al expirar',
      () async {
        await db.insert('Usuarios', {
          'nombre': 'Admin Kimi',
          'username': 'admin_rate',
          'password_hash': HashUtils.hashPassword('AdminPass123', iterations: 10000),
          'rol': 'admin',
          'activo': 1,
          'bloqueado': 0,
        });

        var currentTime = DateTime(2026, 10, 16, 14, 0, 0);
        final authService = AuthService(
          UsuarioRepository(),
          clock: () => currentTime,
        );

        // 4 intentos fallidos: mensaje normal de credenciales incorrectas
        for (var i = 0; i < 4; i++) {
          await expectLater(
            () => authService.login('admin_rate', 'WrongPass'),
            throwsA(
              predicate(
                (e) => e.toString().contains('Credenciales incorrectas'),
              ),
            ),
          );
        }

        // 5to intento fallido: activa enfriamiento de 30 segundos
        await expectLater(
          () => authService.login('admin_rate', 'WrongPass'),
          throwsA(
            predicate(
              (e) => e.toString().contains('Demasiados intentos fallidos'),
            ),
          ),
        );

        // Durante el enfriamiento (a los 10s), incluso la clave correcta es rechazada
        currentTime = currentTime.add(const Duration(seconds: 10));
        await expectLater(
          () => authService.login('admin_rate', 'AdminPass123'),
          throwsA(
            predicate(
              (e) => e.toString().contains('Espera 20 segundos'),
            ),
          ),
        );

        // Pasados los 30s, el login con clave correcta funciona y limpia el contador
        currentTime = currentTime.add(const Duration(seconds: 25));
        final loggedIn = await authService.login('admin_rate', 'AdminPass123');
        expect(loggedIn.username, 'admin_rate');
        expect(authService.failedAttempts, 0);
        expect(authService.lockedUntil, isNull);
      },
    );

    test(
      'RN-11 / C-28 y C-18: UsuarioService audita bloqueo/baja/reactivación e impide auto-bloqueo; AuthController limpia sesión en logout',
      () async {
        final adminId = await db.insert('Usuarios', {
          'nombre': 'Admin Principal',
          'username': 'admin_main',
          'password_hash': HashUtils.hashPassword('AdminPass123', iterations: 10000),
          'rol': 'admin',
          'activo': 1,
          'bloqueado': 0,
        });
        final empId = await db.insert('Usuarios', {
          'nombre': 'Empleado Prueba',
          'username': 'emp_test',
          'password_hash': HashUtils.hashPassword('EmpPass123', iterations: 10000),
          'rol': 'empleado',
          'activo': 1,
          'bloqueado': 0,
        });

        final usuarioRepo = UsuarioRepository();
        final authService = AuthService(usuarioRepo);
        await authService.login('admin_main', 'AdminPass123');
        final usuarioService = UsuarioService(usuarioRepo, authService);

        // Impide auto-bloqueo y auto-baja
        await expectLater(
          () => usuarioService.cambiarEstadoBloqueo(adminId, true),
          throwsA(predicate((e) => e.toString().contains('ti mismo'))),
        );
        await expectLater(
          () => usuarioService.darDeBaja(adminId),
          throwsA(predicate((e) => e.toString().contains('ti mismo'))),
        );

        // Bloquear, desbloquear, dar de baja y reactivar empleado
        await usuarioService.cambiarEstadoBloqueo(empId, true);
        await usuarioService.cambiarEstadoBloqueo(empId, false);
        await usuarioService.darDeBaja(empId);
        expect((await usuarioService.obtenerUsuarios()).length, 1);
        expect(
          (await usuarioService.obtenerUsuarios(incluirInactivos: true)).length,
          2,
        );

        await usuarioService.reactivarUsuario(empId);
        expect((await usuarioService.obtenerUsuarios()).length, 2);

        final auditRows = await db.query(
          'LogAuditoria',
          where: 'usuario_id = ?',
          whereArgs: [adminId],
          orderBy: 'id ASC',
        );
        expect(
          auditRows.map((r) => r['accion']).toList(),
          equals([
            'USUARIO_BLOQUEAR',
            'USUARIO_DESBLOQUEAR',
            'USUARIO_BAJA',
            'USUARIO_REACTIVAR',
          ]),
        );

        // Higiene de sesión en AuthController.logout()
        var cartCleared = false;
        final authCtrl = AuthController(
          authService,
          onLogout: () => cartCleared = true,
        );
        authCtrl.logout();
        expect(cartCleared, isTrue);
        expect(authCtrl.currentUser, isNull);
      },
    );

    test(
      'C-30: OnboardingService.setupInitialSystem hace rollback de Configuracion si falla la creación del admin',
      () async {
        final configRepo = ConfiguracionRepository();
        final authService = AuthService(UsuarioRepository());
        final onboarding = OnboardingService(configRepo, authService);

        // Contraseña demasiado corta (< 6 caracteres) provoca fallo en createAdmin
        await expectLater(
          () => onboarding.setupInitialSystem(
            nombreNegocio: 'Pizzería Atómica',
            moneda: 'S/',
            adminNombre: 'Dueña',
            adminUsername: 'admin_atom',
            adminPassword: '123',
            adminEmail: 'admin@kimi.pe',
          ),
          throwsException,
        );

        // Verificar que nombre_negocio NO quedó guardado en Configuracion tras el fallo
        expect(await configRepo.getConfig('nombre_negocio'), isNull);
      },
    );

    test(
      'C-20: InsumoRepository y ProductoRepository eliminan los archivos de imagen en disco al reemplazar o desactivar registros',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('kimi_img_test_');
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final insumoImg1 = File('${tempDir.path}/insumo_1.jpg')
          ..writeAsBytesSync([1, 2, 3]);
        final insumoImg2 = File('${tempDir.path}/insumo_2.jpg')
          ..writeAsBytesSync([4, 5, 6]);
        final prodImg = File('${tempDir.path}/prod_1.jpg')
          ..writeAsBytesSync([7, 8, 9]);
        final varImg = File('${tempDir.path}/var_1.jpg')
          ..writeAsBytesSync([10, 11, 12]);

        final insumoRepo = InsumoRepository();
        final insumoId = await insumoRepo.insertInsumo(
          Insumo(
            nombre: 'Queso Gouda',
            tipoInsumo: 'Lácteos',
            unidadMedida: 'Kg',
            fotoRuta: insumoImg1.path,
          ),
        );

        // Al reemplazar la foto del insumo, el archivo anterior se borra del disco
        await insumoRepo.updateInsumo(
          Insumo(
            id: insumoId,
            nombre: 'Queso Gouda',
            tipoInsumo: 'Lácteos',
            unidadMedida: 'Kg',
            fotoRuta: insumoImg2.path,
          ),
        );
        expect(insumoImg1.existsSync(), isFalse);
        expect(insumoImg2.existsSync(), isTrue);

        // Al eliminar (desactivar) el insumo, su foto se borra del disco
        await insumoRepo.deleteInsumo(insumoId);
        expect(insumoImg2.existsSync(), isFalse);

        // Producto y Variante con imagen
        final prodRepo = ProductoRepository();
        await prodRepo.guardarProductoCompleto(
          Producto(
            nombre: 'Pizza Especial',
            tipoPreparacion: 'momento',
            fotoRuta: prodImg.path,
          ),
          [
            VarianteProducto(
              productoId: 0,
              nombreVariante: 'Familiar',
              precioVenta: 42.0,
              imagen: varImg.path,
            ),
          ],
        );

        final productos = await prodRepo.getProductos();
        final createdProd = productos.firstWhere(
          (p) => p.nombre == 'Pizza Especial',
        );
        expect(prodImg.existsSync(), isTrue);
        expect(varImg.existsSync(), isTrue);

        // Al desactivar el producto, tanto foto_ruta como imagen de variante se eliminan del disco
        await prodRepo.disableProducto(createdProd.id!);
        expect(prodImg.existsSync(), isFalse);
        expect(varImg.existsSync(), isFalse);
      },
    );
  });
}
