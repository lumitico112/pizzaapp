import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase 2 (H-05): vínculo explícito Gasto <-> MovimientosCaja
/// (`Gastos.movimiento_caja_id`) para eliminar salidas manuales de caja por
/// ID exacto, sin heurística difusa de monto/fecha.
void main() {
  late Database db;
  late int sesionId;
  final purchaseRepo = PurchaseRepository();

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
    sesionId = await db.insert('SesionesCaja', {
      'fecha_apertura': DateTime.now().toIso8601String(),
      'monto_apertura': 100.0,
      'transferencias_apertura': 0.0,
      'estado': 'abierta',
    });
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> registrarSalidaManual({
    double monto = 25.0,
    String descripcion = 'Compra de gas',
    DateTime? fecha,
  }) async {
    await CajaRepository().registrarMovimientoManual(
      MovimientoCaja(
        sesionCajaId: sesionId,
        tipo: 'salida',
        metodoPago: 'efectivo',
        monto: monto,
        descripcion: descripcion,
        fecha: (fecha ?? DateTime.now()).toIso8601String(),
      ),
      userId: null,
    );
    final row = await db.rawQuery('SELECT MAX(id) AS id FROM Gastos');
    return row.first['id'] as int;
  }

  Future<int> insertarMovimientoSalida({
    required double monto,
    required String fecha,
  }) {
    return db.insert('MovimientosCaja', {
      'sesion_caja_id': sesionId,
      'tipo': 'salida',
      'metodo_pago': 'efectivo',
      'monto': monto,
      'descripcion': 'Salida legada',
      'fecha': fecha,
    });
  }

  Future<int> insertarGastoLegado({
    required double monto,
    required String fecha,
  }) {
    return db.insert('Gastos', {
      'fecha': fecha.split('T').first,
      'created_at': fecha,
      'categoria': 'Salida Manual de Caja',
      'descripcion': 'Salida legada',
      'monto': monto,
      'sesion_caja_id': sesionId,
    });
  }

  Future<List<Map<String, Object?>>> queryGasto(int id) =>
      db.query('Gastos', where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, Object?>>> queryMovimiento(int id) =>
      db.query('MovimientosCaja', where: 'id = ?', whereArgs: [id]);

  Future<Map<String, Object?>> ultimaAuditoria(String accion) async {
    final rows = await db.query(
      'LogAuditoria',
      where: 'accion = ?',
      whereArgs: [accion],
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.single;
  }

  test('T1: la salida manual queda vinculada y al eliminar el gasto se borra el movimiento exacto', () async {
    final gastoId = await registrarSalidaManual(monto: 25.0);

    final gasto = (await queryGasto(gastoId)).single;
    final movId = gasto['movimiento_caja_id'] as int?;
    expect(movId, isNotNull);
    expect(await queryMovimiento(movId!), hasLength(1));

    await purchaseRepo.eliminarGasto(gastoId);

    expect(await queryGasto(gastoId), isEmpty);
    expect(await queryMovimiento(movId), isEmpty);

    final audit = await ultimaAuditoria('gasto_eliminado');
    expect(audit['detalle'], contains('vínculo explícito'));
  });

  test('T2: con dos salidas idénticas solo se borra el movimiento del gasto eliminado', () async {
    final gasto1 = await registrarSalidaManual(monto: 25.0);
    final gasto2 = await registrarSalidaManual(monto: 25.0);

    final mov1 = (await queryGasto(gasto1)).single['movimiento_caja_id'] as int;
    final mov2 = (await queryGasto(gasto2)).single['movimiento_caja_id'] as int;
    expect(mov1, isNot(mov2));

    await purchaseRepo.eliminarGasto(gasto2);

    expect(await queryGasto(gasto2), isEmpty);
    expect(await queryMovimiento(mov2), isEmpty);
    expect(await queryGasto(gasto1), hasLength(1));
    expect(await queryMovimiento(mov1), hasLength(1));
  });

  test('T3: gasto legado sin vínculo con un único candidato usa el fallback y lo elimina', () async {
    final fecha = DateTime.now().toIso8601String();
    final movId = await insertarMovimientoSalida(monto: 30.0, fecha: fecha);
    final gastoId = await insertarGastoLegado(monto: 30.0, fecha: fecha);

    await purchaseRepo.eliminarGasto(gastoId);

    expect(await queryGasto(gastoId), isEmpty);
    expect(await queryMovimiento(movId), isEmpty);

    final audit = await ultimaAuditoria('gasto_eliminado');
    expect(audit['detalle'], contains('coincidencia única'));
  });

  test('T4: sin vínculo, con 0 o 2+ candidatos se elimina el gasto y se conservan los movimientos', () async {
    // Caso 0 candidatos.
    final fechaA = DateTime.now().toIso8601String();
    final gastoA = await insertarGastoLegado(monto: 40.0, fecha: fechaA);
    await purchaseRepo.eliminarGasto(gastoA);
    expect(await queryGasto(gastoA), isEmpty);

    // Caso 2 candidatos ambiguos.
    final fechaB = DateTime.now().toIso8601String();
    final movB1 = await insertarMovimientoSalida(monto: 50.0, fecha: fechaB);
    final movB2 = await insertarMovimientoSalida(monto: 50.0, fecha: fechaB);
    final gastoB = await insertarGastoLegado(monto: 50.0, fecha: fechaB);

    await purchaseRepo.eliminarGasto(gastoB);

    expect(await queryGasto(gastoB), isEmpty);
    expect(await queryMovimiento(movB1), hasLength(1));
    expect(await queryMovimiento(movB2), hasLength(1));

    final audit = await ultimaAuditoria('gasto_eliminado');
    expect(audit['detalle'], contains('ambiguos'));
  });

  test('T5: migración v23 -> v24 agrega Gastos.movimiento_caja_id y foreign_key_check queda limpio', () async {
    // Simular un estado v23: Gastos sin la columna nueva, FK apagadas.
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute('DROP TABLE IF EXISTS Gastos');
    await db.execute('''
      CREATE TABLE Gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        categoria TEXT NOT NULL,
        descripcion TEXT,
        monto REAL NOT NULL,
        foto_recibo_ruta TEXT,
        insumo_id INTEGER REFERENCES Insumos(id),
        activo_id INTEGER REFERENCES Activos(id),
        activo_fijo_id INTEGER REFERENCES ActivosFijos(id),
        compra_movimiento_id INTEGER REFERENCES AjustesStock(id),
        usuario_id INTEGER REFERENCES Usuarios(id),
        sesion_caja_id INTEGER REFERENCES SesionesCaja(id)
      )
    ''');
    final legadoId = await db.insert('Gastos', {
      'fecha': '2026-10-17',
      'categoria': 'Servicios',
      'monto': 40.0,
    });

    await DatabaseHelper.instance.upgradeDatabase(db, 23, 24);
    await db.execute('PRAGMA foreign_keys = ON');

    final columnas = await db.rawQuery('PRAGMA table_info(Gastos)');
    expect(columnas.map((c) => c['name']), contains('movimiento_caja_id'));

    final legado = (await queryGasto(legadoId)).single;
    expect(legado['movimiento_caja_id'], isNull);

    final violaciones = await db.rawQuery('PRAGMA foreign_key_check');
    expect(violaciones, isEmpty);

    // FK en tiempo real: un movimiento inexistente es rechazado.
    await expectLater(
      () => db.insert('Gastos', {
        'fecha': '2026-10-17',
        'categoria': 'Servicios',
        'monto': 10.0,
        'movimiento_caja_id': 999999,
      }),
      throwsA(anything),
    );
  });
}
