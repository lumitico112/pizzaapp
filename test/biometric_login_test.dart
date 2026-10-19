import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/core/storage/secure_auth_store.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/biometric_auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// FS-11 (Fase B): acceso rápido con huella — nunca se persiste la
/// contraseña, la sesión se revalida con `activo = 1 AND bloqueado = 0`, y el
/// permiso se revoca al cerrar sesión, al detectar un usuario inválido y al
/// restablecer la contraseña del usuario recordado.
class _FakeBiometricAuthService extends BiometricAuthService {
  _FakeBiometricAuthService({this.autentica = true});

  bool disponibleValor = true;
  bool autentica;
  int llamadasAutenticacion = 0;

  @override
  Future<bool> disponible() async => disponibleValor;

  @override
  Future<bool> autenticar({String reason = ''}) async {
    llamadasAutenticacion++;
    return autentica;
  }
}

void main() {
  late Database db;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> insertarUsuario({String username = 'usuario_huella'}) {
    return db.insert('Usuarios', {
      'nombre': 'Usuario Huella',
      'username': username,
      'password_hash': HashUtils.hashPassword(
        'ClaveSegura123',
        iterations: 10000,
      ),
      'rol': 'admin',
      'activo': 1,
      'bloqueado': 0,
    });
  }

  Future<void> recordarConHuella(int userId) async {
    final store = SecureAuthStore();
    await store.guardar(username: 'usuario_huella', userId: userId);
    await store.habilitarAccesoHuella();
  }

  group('SecureAuthStore: permiso de acceso con huella', () {
    test(
      'habilita, consulta y revoca el permiso conservando el nombre recordado',
      () async {
        final store = SecureAuthStore();
        expect(await store.accesoHuellaHabilitado(), isFalse);

        await store.guardar(username: 'usuario_recordado', userId: 7);
        await store.habilitarAccesoHuella();

        final persistido = await const FlutterSecureStorage().readAll();
        expect(persistido.keys.toSet(), {
          'auth_username',
          'auth_user_id',
          'auth_huella_habilitada',
        });
        expect(
          persistido.values.any((valor) => valor.contains('ClaveSegura123')),
          isFalse,
          reason: 'La contraseña nunca debe persistirse',
        );

        await store.revocarAccesoHuella();
        expect(await store.accesoHuellaHabilitado(), isFalse);
        expect(await store.leer(), isNotNull);

        await store.habilitarAccesoHuella();
        await store.limpiar();
        expect(await store.accesoHuellaHabilitado(), isFalse);
        expect(await store.leer(), isNull);
      },
    );
  });

  group('AuthController: acceso rápido con huella', () {
    test(
      'solo se ofrece con permiso habilitado, usuario recordado y biometría',
      () async {
        final fake = _FakeBiometricAuthService();
        final controller = AuthController(
          AuthService(UsuarioRepository()),
          biometricAuth: fake,
        );

        expect(await controller.puedeEntrarConHuella(), isFalse);

        final userId = await insertarUsuario();
        final store = SecureAuthStore();
        await store.guardar(username: 'usuario_huella', userId: userId);
        expect(
          await controller.puedeEntrarConHuella(),
          isFalse,
          reason: 'Sin permiso de huella habilitado no se ofrece',
        );

        await store.habilitarAccesoHuella();
        fake.disponibleValor = false;
        expect(await controller.puedeEntrarConHuella(), isFalse);

        fake.disponibleValor = true;
        expect(await controller.puedeEntrarConHuella(), isTrue);
        expect(
          controller.haySesion,
          isFalse,
          reason: 'Consultar disponibilidad no inicia sesión',
        );
      },
    );

    test('no pide huella si el permiso fue revocado', () async {
      final userId = await insertarUsuario();
      final fake = _FakeBiometricAuthService();
      final controller = AuthController(
        AuthService(UsuarioRepository()),
        biometricAuth: fake,
      );
      await SecureAuthStore().guardar(
        username: 'usuario_huella',
        userId: userId,
      );

      expect(await controller.entrarConHuella(), isFalse);
      expect(fake.llamadasAutenticacion, 0);
      expect(controller.haySesion, isFalse);
    });

    test(
      'con huella aceptada restaura la sesión del usuario revalidado',
      () async {
        final userId = await insertarUsuario();
        await recordarConHuella(userId);
        final fake = _FakeBiometricAuthService();
        final controller = AuthController(
          AuthService(UsuarioRepository()),
          biometricAuth: fake,
        );

        expect(await controller.entrarConHuella(), isTrue);
        expect(controller.haySesion, isTrue);
        expect(controller.currentUser?.id, userId);
        expect(fake.llamadasAutenticacion, 1);
        expect(controller.error, isNull);
      },
    );

    test(
      'huella rechazada o cancelada no inicia sesión y conserva el permiso',
      () async {
        final userId = await insertarUsuario();
        await recordarConHuella(userId);
        final fake = _FakeBiometricAuthService(autentica: false);
        final controller = AuthController(
          AuthService(UsuarioRepository()),
          biometricAuth: fake,
        );

        expect(await controller.entrarConHuella(), isFalse);
        expect(controller.haySesion, isFalse);
        expect(controller.error, isNull, reason: 'Cancelar no es un error');
        expect(await SecureAuthStore().accesoHuellaHabilitado(), isTrue);
      },
    );

    test(
      'usuario bloqueado: se rechaza y se revoca el acceso rápido',
      () async {
        final userId = await insertarUsuario();
        await recordarConHuella(userId);
        await db.update(
          'Usuarios',
          {'bloqueado': 1},
          where: 'id = ?',
          whereArgs: [userId],
        );
        final fake = _FakeBiometricAuthService();
        final controller = AuthController(
          AuthService(UsuarioRepository()),
          biometricAuth: fake,
        );

        expect(await controller.entrarConHuella(), isFalse);
        expect(controller.haySesion, isFalse);
        expect(controller.error, contains('contraseña'));
        expect(await SecureAuthStore().accesoHuellaHabilitado(), isFalse);
        expect(
          await SecureAuthStore().leer(),
          isNotNull,
          reason: 'El nombre recordado se conserva',
        );
      },
    );

    test('marcar o desmarcar huella tras el login ajusta el permiso', () async {
      await insertarUsuario();
      final controller = AuthController(
        AuthService(UsuarioRepository()),
        biometricAuth: _FakeBiometricAuthService(),
      );
      expect(
        await controller.login('usuario_huella', 'ClaveSegura123'),
        isTrue,
      );

      await controller.actualizarUsuarioRecordado(true, usarHuella: true);
      expect(await SecureAuthStore().accesoHuellaHabilitado(), isTrue);
      expect(await controller.leerUsuarioRecordado(), isNotNull);

      await controller.actualizarUsuarioRecordado(true, usarHuella: false);
      expect(await SecureAuthStore().accesoHuellaHabilitado(), isFalse);
      expect(await controller.leerUsuarioRecordado(), isNotNull);

      await controller.actualizarUsuarioRecordado(false);
      expect(await controller.leerUsuarioRecordado(), isNull);
      expect(await SecureAuthStore().accesoHuellaHabilitado(), isFalse);
    });

    test(
      'cerrar sesión revoca la huella y conserva el nombre recordado',
      () async {
        final userId = await insertarUsuario();
        final controller = AuthController(
          AuthService(UsuarioRepository()),
          biometricAuth: _FakeBiometricAuthService(),
        );
        await controller.login('usuario_huella', 'ClaveSegura123');
        await controller.actualizarUsuarioRecordado(true, usarHuella: true);
        expect(await SecureAuthStore().accesoHuellaHabilitado(), isTrue);

        await controller.logout();

        expect(controller.haySesion, isFalse);
        expect(await SecureAuthStore().accesoHuellaHabilitado(), isFalse);
        final recordado = await controller.leerUsuarioRecordado();
        expect(recordado, isNotNull);
        expect(recordado!.username, 'usuario_huella');
        expect(recordado.userId, userId);
      },
    );

    test(
      'restablecer la contraseña del usuario recordado revoca la huella',
      () async {
        final userId = await insertarUsuario();
        await db.update(
          'Usuarios',
          {'recovery_code': HashUtils.hashRecoveryCode('CLAVE-RESCATE-1')},
          where: 'id = ?',
          whereArgs: [userId],
        );
        await recordarConHuella(userId);
        final controller = AuthController(
          AuthService(UsuarioRepository()),
          biometricAuth: _FakeBiometricAuthService(),
        );

        final error = await controller.resetAdminPassword(
          username: 'usuario_huella',
          recoveryCode: 'CLAVE-RESCATE-1',
          newPassword: 'NuevaClave123',
        );

        expect(error, isNull);
        expect(await SecureAuthStore().accesoHuellaHabilitado(), isFalse);
        expect(await SecureAuthStore().leer(), isNotNull);
      },
    );

    test(
      'restablecer la contraseña de otro usuario no toca el permiso',
      () async {
        final userIdRecordado = await insertarUsuario();
        final userIdOtro = await insertarUsuario(username: 'otro_admin');
        await db.update(
          'Usuarios',
          {'recovery_code': HashUtils.hashRecoveryCode('CLAVE-RESCATE-2')},
          where: 'id = ?',
          whereArgs: [userIdOtro],
        );
        await recordarConHuella(userIdRecordado);
        final controller = AuthController(
          AuthService(UsuarioRepository()),
          biometricAuth: _FakeBiometricAuthService(),
        );

        final error = await controller.resetAdminPassword(
          username: 'otro_admin',
          recoveryCode: 'CLAVE-RESCATE-2',
          newPassword: 'NuevaClave456',
        );

        expect(error, isNull);
        expect(await SecureAuthStore().accesoHuellaHabilitado(), isTrue);
      },
    );
  });
}
