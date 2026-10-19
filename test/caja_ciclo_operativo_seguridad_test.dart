import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/caja_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// FS-3 (SEC-029, SEC-030, SEC-031): caja y ciclo operativo.
/// - SEC-029: reapertura excepcional sin autorización -> denegada y sin cambios.
/// - SEC-030: cierre enviado dos veces -> un solo cierre/ciclo.
/// - SEC-031: reapertura autorizada -> fecha/hora, actor, motivo y referencia
///   al ciclo anterior en `LogAuditoria`.
void main() {
  late Database db;
  late CajaRepository cajaRepo;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
    cajaRepo = CajaRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> crearUsuario({
    required String rol,
    required String username,
    String password = 'ClaveSegura1',
  }) async {
    return db.insert('Usuarios', {
      'nombre': rol == 'admin' ? 'Administradora FS3' : 'Empleado FS3',
      'username': username,
      'password_hash': HashUtils.hashPassword(password, iterations: 1000),
      'rol': rol,
      'activo': 1,
      'bloqueado': 0,
    });
  }

  Future<AuthService> autenticar(
    String username, [
    String password = 'ClaveSegura1',
  ]) async {
    final auth = AuthService(UsuarioRepository());
    await auth.login(username, password);
    return auth;
  }

  Future<int> abrirSesionDePrueba({
    required int usuarioId,
    double efectivo = 100.0,
    double digital = 50.0,
    String fechaApertura = '2026-10-18T09:00:00.000',
  }) async {
    return cajaRepo.abrirSesion(
      SesionCaja(
        fechaApertura: fechaApertura,
        montoApertura: efectivo,
        transferenciasApertura: digital,
        usuarioAperturaId: usuarioId,
      ),
      efectivo > 0
          ? MovimientoCaja(
              sesionCajaId: 0,
              tipo: 'apertura',
              metodoPago: 'efectivo',
              monto: efectivo,
              descripcion: 'Apertura de caja',
              fecha: fechaApertura,
            )
          : null,
      userId: usuarioId,
    );
  }

  Future<Map<String, Object?>?> sesionPorId(int id) async {
    final rows = await db.query(
      'SesionesCaja',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> auditoriaDe(String accion) {
    return db.query(
      'LogAuditoria',
      where: 'accion = ?',
      whereArgs: [accion],
      orderBy: 'id ASC',
    );
  }

  Future<int> contarFilas(String tabla) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $tabla');
    return rows.first['c'] as int;
  }

  group('SEC-029: reapertura excepcional sin autorizacion', () {
    test('T1: sin servicio de autorizacion se deniega y no hay cambios', () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      final sesionId = await abrirSesionDePrueba(usuarioId: adminId);
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: 'Cierre previo',
        usuarioId: adminId,
      );

      final service = CajaService(cajaRepo);
      await expectLater(
        () => service.reabrirCaja(sesionId, 'Conteo mal registrado', 'x'),
        throwsA(
          predicate(
            (e) => e.toString().contains('No está disponible la autorización'),
          ),
        ),
      );

      final sesion = await sesionPorId(sesionId);
      expect(sesion!['estado'], 'cerrada');
      expect(sesion['fecha_cierre'], isNotNull);
      expect(await auditoriaDe('caja_reabierta_excepcionalmente'), isEmpty);
    });

    test('T2: un empleado autenticado no puede reabrir la caja', () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      await crearUsuario(rol: 'empleado', username: 'empleado_fs3');
      final sesionId = await abrirSesionDePrueba(usuarioId: adminId);
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: '',
        usuarioId: adminId,
      );

      final authEmpleado = await autenticar('empleado_fs3');
      final service = CajaService(cajaRepo, authEmpleado);
      await expectLater(
        () => service.reabrirCaja(sesionId, 'Intento de empleado', 'ClaveSegura1'),
        throwsA(
          predicate(
            (e) => e
                .toString()
                .contains('requiere autorización de la administradora'),
          ),
        ),
      );

      final sesion = await sesionPorId(sesionId);
      expect(sesion!['estado'], 'cerrada');
      expect(await auditoriaDe('caja_reabierta_excepcionalmente'), isEmpty);
    });

    test('T3: la administradora con contrasena incorrecta no reabre', () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      final sesionId = await abrirSesionDePrueba(usuarioId: adminId);
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: '',
        usuarioId: adminId,
      );

      final authAdmin = await autenticar('admin_fs3');
      final service = CajaService(cajaRepo, authAdmin);
      await expectLater(
        () => service.reabrirCaja(sesionId, 'Motivo valido', 'incorrecta'),
        throwsA(
          predicate(
            (e) => e.toString().contains('La contraseña de autorización no es válida'),
          ),
        ),
      );

      final sesion = await sesionPorId(sesionId);
      expect(sesion!['estado'], 'cerrada');
      expect(await auditoriaDe('caja_reabierta_excepcionalmente'), isEmpty);
    });

    test('T4: sin motivo la reapertura se deniega antes de autorizar', () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      final sesionId = await abrirSesionDePrueba(usuarioId: adminId);
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: '',
        usuarioId: adminId,
      );

      final authAdmin = await autenticar('admin_fs3');
      final service = CajaService(cajaRepo, authAdmin);
      await expectLater(
        () => service.reabrirCaja(sesionId, '   ', 'ClaveSegura1'),
        throwsA(predicate((e) => e.toString().contains('Indica el motivo'))),
      );

      final sesion = await sesionPorId(sesionId);
      expect(sesion!['estado'], 'cerrada');
      expect(await auditoriaDe('caja_reabierta_excepcionalmente'), isEmpty);
    });
  });

  group('SEC-030: cierre enviado dos veces', () {
    test('T5: el doble cierre secuencial produce un solo cierre', () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      final sesionId = await abrirSesionDePrueba(usuarioId: adminId);
      final authAdmin = await autenticar('admin_fs3');
      final service = CajaService(cajaRepo, authAdmin);

      final primerCierre = await service.cerrarCaja(100.0, 50.0, 'Cierre unico');
      expect(primerCierre.estado, 'cerrada');
      expect(primerCierre.fechaCierre, isNotNull);

      await expectLater(
        () => service.cerrarCaja(100.0, 50.0, 'Cierre duplicado'),
        throwsA(predicate((e) => e.toString().contains('No hay ninguna sesi'))),
      );

      final cierres = await auditoriaDe('caja_cerrada');
      expect(cierres, hasLength(1));
      expect(await contarFilas('SesionesCaja'), 1);

      final sesion = await sesionPorId(sesionId);
      expect(sesion!['estado'], 'cerrada');
      expect(sesion['fecha_cierre'], primerCierre.fechaCierre);
      expect(sesion['nota'], 'Cierre unico');
    });

    test('T6: dos cierres concurrentes dejan exactamente un cierre', () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      final sesionId = await abrirSesionDePrueba(usuarioId: adminId);

      Future<bool> intentarCerrar() async {
        try {
          await cajaRepo.cerrarSesion(
            sesionId: sesionId,
            efectivoContado: 100.0,
            transferenciasContadas: 50.0,
            nota: 'Cierre concurrente',
            usuarioId: adminId,
          );
          return true;
        } catch (_) {
          return false;
        }
      }

      final resultados = await Future.wait([intentarCerrar(), intentarCerrar()]);
      expect(resultados.where((ok) => ok).length, 1);
      expect(await auditoriaDe('caja_cerrada'), hasLength(1));

      final sesion = await sesionPorId(sesionId);
      expect(sesion!['estado'], 'cerrada');
      expect(await contarFilas('SesionesCaja'), 1);
    });
  });

  group('SEC-031: reapertura autorizada y auditoria', () {
    test('T7: la reapertura autorizada registra actor, motivo y ciclo previo',
        () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      final sesionId = await abrirSesionDePrueba(usuarioId: adminId);
      final cierre = await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 90.0,
        transferenciasContadas: 50.0,
        nota: 'Cierre con faltante',
        usuarioId: adminId,
      );

      final authAdmin = await autenticar('admin_fs3');
      final service = CajaService(cajaRepo, authAdmin);
      final antes = DateTime.now();
      await service.reabrirCaja(
        sesionId,
        'Conteo mal registrado',
        'ClaveSegura1',
      );
      final despues = DateTime.now();

      final sesion = await sesionPorId(sesionId);
      expect(sesion!['estado'], 'abierta');
      expect(sesion['fecha_cierre'], isNull);
      expect(sesion['efectivo_contado'], 0);
      expect(sesion['transferencias_contadas'], 0);
      expect(sesion['diferencia'], 0);
      expect(sesion['nota'], isNull);
      expect(sesion['usuario_cierre_id'], isNull);

      final logs = await auditoriaDe('caja_reabierta_excepcionalmente');
      expect(logs, hasLength(1));
      expect(logs.single['usuario_id'], adminId);

      final detalle = logs.single['detalle'] as String;
      expect(detalle, contains('Sesión $sesionId'));
      expect(detalle, contains('ciclo iniciado 2026-10-18T09:00:00.000'));
      expect(detalle, contains('motivo: Conteo mal registrado'));
      expect(detalle, contains('cierre previo ${cierre.fechaCierre}'));
      expect(
        detalle,
        contains('diferencia previa ${cierre.diferencia.toStringAsFixed(2)}'),
      );

      final autorizacion = RegExp(
        r'autorización ([0-9T:\-\.]+);',
      ).firstMatch(detalle);
      expect(autorizacion, isNotNull);
      final marca = DateTime.parse(autorizacion!.group(1)!);
      expect(marca.isBefore(antes), isFalse);
      expect(marca.isAfter(despues), isFalse);

      final movimientos = await db.query(
        'MovimientosCaja',
        where: 'sesion_caja_id = ?',
        whereArgs: [sesionId],
      );
      expect(movimientos, hasLength(1));
      expect(movimientos.single['tipo'], 'apertura');
    });

    test('T8: con otra caja abierta la reapertura se deniega sin cambios',
        () async {
      final adminId = await crearUsuario(rol: 'admin', username: 'admin_fs3');
      final sesionCerrada = await abrirSesionDePrueba(usuarioId: adminId);
      await cajaRepo.cerrarSesion(
        sesionId: sesionCerrada,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: '',
        usuarioId: adminId,
      );
      final sesionActiva = await abrirSesionDePrueba(
        usuarioId: adminId,
        fechaApertura: '2026-10-19T09:00:00.000',
      );

      final authAdmin = await autenticar('admin_fs3');
      final service = CajaService(cajaRepo, authAdmin);
      await expectLater(
        () => service.reabrirCaja(sesionCerrada, 'Reapertura tardia', 'ClaveSegura1'),
        throwsA(predicate((e) => e.toString().contains('Ya existe una caja abierta'))),
      );

      final objetivo = await sesionPorId(sesionCerrada);
      expect(objetivo!['estado'], 'cerrada');
      final activa = await sesionPorId(sesionActiva);
      expect(activa!['estado'], 'abierta');
      expect(await auditoriaDe('caja_reabierta_excepcionalmente'), isEmpty);
    });
  });
}
