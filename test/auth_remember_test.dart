import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/core/storage/secure_auth_store.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// FS-10 (Fase A): "Recordar usuario" — solo `username` + `user_id` en
/// almacenamiento seguro; la contraseña NUNCA se persiste (regla S3).
void main() {
  late Database db;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> insertarUsuario() {
    return db.insert('Usuarios', {
      'nombre': 'Usuario Recordado',
      'username': 'usuario_recordado',
      'password_hash':
          HashUtils.hashPassword('ClaveSegura123', iterations: 10000),
      'rol': 'admin',
      'activo': 1,
      'bloqueado': 0,
    });
  }

  group('SecureAuthStore', () {
    test('guarda, lee y limpia el usuario recordado (solo username y user_id)',
        () async {
      final store = SecureAuthStore();

      await store.guardar(username: 'usuario_recordado', userId: 7);

      final recordado = await store.leer();
      expect(recordado, isNotNull);
      final datos = recordado!;
      expect(datos.username, 'usuario_recordado');
      expect(datos.userId, 7);

      final persistido = await const FlutterSecureStorage().readAll();
      expect(persistido.keys.toSet(), {'auth_username', 'auth_user_id'});

      await store.limpiar();
      expect(await store.leer(), isNull);
    });

    test('no devuelve nada con datos ausentes o incompletos', () async {
      final store = SecureAuthStore();
      expect(await store.leer(), isNull);

      FlutterSecureStorage.setMockInitialValues({
        'auth_username': 'solo_nombre',
      });
      expect(await store.leer(), isNull);

      FlutterSecureStorage.setMockInitialValues({
        'auth_username': 'solo_nombre',
        'auth_user_id': 'no-numerico',
      });
      expect(await store.leer(), isNull);
    });
  });

  group('AuthController (decisión de recordar usuario)', () {
    test('tras un login exitoso guarda usuario e id si se marcó recordar',
        () async {
      final userId = await insertarUsuario();
      final controller = AuthController(AuthService(UsuarioRepository()));

      expect(
        await controller.login('usuario_recordado', 'ClaveSegura123'),
        isTrue,
      );
      await controller.actualizarUsuarioRecordado(true);

      final recordado = await controller.leerUsuarioRecordado();
      expect(recordado, isNotNull);
      final datos = recordado!;
      expect(datos.username, 'usuario_recordado');
      expect(datos.userId, userId);

      final persistido = await const FlutterSecureStorage().readAll();
      expect(
        persistido.values.any((valor) => valor.contains('ClaveSegura123')),
        isFalse,
        reason: 'La contraseña nunca debe persistirse',
      );
    });

    test('borra el registro cuando el login ocurre sin marcar recordar',
        () async {
      await insertarUsuario();
      final controller = AuthController(AuthService(UsuarioRepository()));

      await controller.login('usuario_recordado', 'ClaveSegura123');
      await controller.actualizarUsuarioRecordado(true);
      expect(await controller.leerUsuarioRecordado(), isNotNull);

      await controller.actualizarUsuarioRecordado(false);
      expect(await controller.leerUsuarioRecordado(), isNull);
    });

    test('sin sesión activa no guarda nada', () async {
      final controller = AuthController(AuthService(UsuarioRepository()));

      await controller.actualizarUsuarioRecordado(true);

      expect(await controller.leerUsuarioRecordado(), isNull);
    });
  });
}
