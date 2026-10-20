import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/database/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase 14 (H-13): equivalencia de esquema entre una BD nueva (v27) y una BD
/// legada v22 migrada con `upgradeDatabase` hasta v27.
///
/// Estado v22 simulado (mismo truco que `phase3_sqlite_consolidation_test.dart`):
/// - sin índices `IDX_*` ni triggers (los introduce la v23);
/// - `Gastos` sin `movimiento_caja_id` (v24) ni `compra_ocasional_id` (v27);
/// - sin tabla `FaltantesPreparacion` (la crea la v25);
/// - sin `Ventas.es_historica` ni `AjustesStock.venta_id` (v26);
/// - sin tabla `ComprasOcasionales` ni `CuentasPorPagar.compra_ocasional_id`
///   (la v27);
/// - `CuentasPorPagar` con `insumo_id INTEGER NOT NULL` (forma previa al
///   rebuild de la v23, C-09).
/// Las columnas que la v23 garantiza con `_ensureColumn` y ya existen quedan
/// como no-op; la comparación total de objetos de `sqlite_master` y de las
/// columnas (nombre + notnull) de todas las tablas es la red anti-deriva.
void main() {
  late Database dbNueva;
  late Database dbMigrada;

  setUp(() async {
    dbNueva = await TestDbHarness.openFreshInMemoryDb(singleInstance: false);
    dbMigrada = await TestDbHarness.openFreshInMemoryDb(singleInstance: false);
  });

  tearDown(() async {
    await TestDbHarness.closeDb(dbMigrada);
    await TestDbHarness.closeDb(dbNueva);
  });

  test(
      'una BD v22 migrada hasta v27 expone las mismas tablas, indices, triggers y columnas que una BD nueva',
      () async {
    final objetosNueva = await _objetosEsquema(dbNueva);
    final tablasNueva = objetosNueva
        .where((o) => o.startsWith('table:'))
        .map((o) => o.substring('table:'.length))
        .toSet();
    expect(tablasNueva.length, 38, reason: 'tablas del esquema vigente');
    expect(
      objetosNueva.where((o) => o.startsWith('trigger:')).length,
      4,
      reason: 'triggers del esquema vigente',
    );
    expect(
      objetosNueva.where((o) => o.startsWith('index:IDX_')).length,
      28,
      reason: 'indices IDX_ del esquema vigente',
    );

    await _simularEsquemaV22(dbMigrada);
    await DatabaseHelper.instance.upgradeDatabase(
      dbMigrada,
      22,
      DatabaseHelper.databaseVersion,
    );
    await dbMigrada.execute('PRAGMA foreign_keys = ON');

    final objetosMigrada = await _objetosEsquema(dbMigrada);
    expect(
      objetosMigrada.difference(objetosNueva),
      isEmpty,
      reason: 'objetos que solo existen tras migrar (deriva de la migracion)',
    );
    expect(
      objetosNueva.difference(objetosMigrada),
      isEmpty,
      reason: 'objetos perdidos al migrar (deriva de DbSchema)',
    );

    // El camino B realmente migró: los artefactos degradados quedaron recreados.
    final tablasMigrada = objetosMigrada
        .where((o) => o.startsWith('table:'))
        .map((o) => o.substring('table:'.length))
        .toSet();
    expect(tablasMigrada, contains('FaltantesPreparacion'));
    expect(tablasMigrada, contains('ComprasOcasionales'));
    expect(objetosMigrada.where((o) => o.startsWith('index:IDX_')).length, 28);
    expect(objetosMigrada.where((o) => o.startsWith('trigger:')).length, 4);
    final gastosMigrada = await dbMigrada.rawQuery('PRAGMA table_info(Gastos)');
    expect(
      gastosMigrada.any((c) => c['name'] == 'movimiento_caja_id'),
      isTrue,
      reason: 'la v24 debe re-crear Gastos.movimiento_caja_id',
    );
    expect(
      gastosMigrada.any((c) => c['name'] == 'compra_ocasional_id'),
      isTrue,
      reason: 'la v27 debe agregar Gastos.compra_ocasional_id',
    );
    final cxpOcasionalMigrada =
        (await dbMigrada.rawQuery('PRAGMA table_info(CuentasPorPagar)'))
            .firstWhere((c) => c['name'] == 'compra_ocasional_id');
    expect(
      cxpOcasionalMigrada['notnull'],
      0,
      reason: 'CuentasPorPagar.compra_ocasional_id debe ser nullable',
    );
    final cxpInsumoMigrada =
        (await dbMigrada.rawQuery('PRAGMA table_info(CuentasPorPagar)'))
            .firstWhere((c) => c['name'] == 'insumo_id');
    expect(
      cxpInsumoMigrada['notnull'],
      0,
      reason: 'el rebuild v23 debe dejar CuentasPorPagar.insumo_id nullable',
    );

    final columnasNueva = await _columnasEsquema(dbNueva, tablasNueva);
    final columnasMigrada = await _columnasEsquema(dbMigrada, tablasNueva);
    for (final tabla in columnasNueva.keys) {
      expect(
        columnasMigrada[tabla],
        equals(columnasNueva[tabla]),
        reason: 'columnas (nombre + notnull) distintas en la tabla $tabla',
      );
    }
  });

  test('la conexion vigente no usa WAL y espera 5 s ante bloqueos (H-13)',
      () async {
    final busyTimeout = await dbNueva.rawQuery('PRAGMA busy_timeout');
    expect(busyTimeout.first.values.first, 5000);

    final foreignKeys = await dbNueva.rawQuery('PRAGMA foreign_keys');
    expect(foreignKeys.first.values.first, 1);

    final journalMode =
        (await dbNueva.rawQuery('PRAGMA journal_mode')).first.values.first
            as String;
    expect(journalMode.toLowerCase(), isNot('wal'));
  });
}

/// Nombres (prefijados por tipo) de tablas, índices y triggers visibles en
/// `sqlite_master`, excluyendo objetos internos `sqlite_*` (autoíndices).
Future<Set<String>> _objetosEsquema(Database db) async {
  final rows = await db.rawQuery(
    "SELECT type, name FROM sqlite_master "
    "WHERE type IN ('table', 'index', 'trigger') AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((row) => '${row['type']}:${row['name']}').toSet();
}

/// Columnas por tabla como `nombre:notnull` (vía `PRAGMA table_info`).
Future<Map<String, Set<String>>> _columnasEsquema(
  Database db,
  Set<String> tablas,
) async {
  final resultado = <String, Set<String>>{};
  for (final tabla in tablas) {
    final info = await db.rawQuery('PRAGMA table_info($tabla)');
    resultado[tabla] = info
        .map((columna) => '${columna['name']}:${columna['notnull']}')
        .toSet();
  }
  return resultado;
}

/// Degrada una BD recién creada v27 a un estado compatible con v22 para que
/// `upgradeDatabase` recorra las migraciones 23, 24, 25, 26 y 27 (mismo truco
/// que el test de la fase 3). No se comparan datos: solo estructura.
Future<void> _simularEsquemaV22(Database db) async {
  await db.execute('PRAGMA foreign_keys = OFF');

  // v23: una BD v22 real no tenía los índices IDX_* ni los triggers de validación.
  final triggers = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'trigger'",
  );
  for (final trigger in triggers) {
    await db.execute('DROP TRIGGER IF EXISTS ${trigger['name']}');
  }
  final indexes = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'IDX_%'",
  );
  for (final index in indexes) {
    await db.execute('DROP INDEX IF EXISTS ${index['name']}');
  }

  // v27: sin tabla de compras ocasionales. Sus hijos se reconstruyen abajo
  // sin las columnas que la referencian.
  await db.execute('DROP TABLE IF EXISTS ComprasOcasionales');

  // v25: sin FaltantesPreparacion (la crea la migración; el índice va con la tabla).
  await db.execute('DROP TABLE IF EXISTS FaltantesPreparacion');

  // v26: Ventas sin es_historica y AjustesStock sin venta_id. Se reconstruyen
  // desde el esquema canónico quitando solo las columnas nuevas.
  await db.execute('DROP TABLE IF EXISTS AjustesStock');
  await db.execute('DROP TABLE IF EXISTS Ventas');
  await db.execute(
    DbSchema.createVentas.replaceFirst(
      RegExp(
        r',\s*es_historica\s+INTEGER\s+NOT\s+NULL\s+DEFAULT\s+0',
      ),
      '',
    ),
  );
  await db.execute(
    DbSchema.createAjustesStock.replaceFirst(
      RegExp(r',\s*venta_id\s+INTEGER\s+REFERENCES\s+Ventas\(id\)'),
      '',
    ),
  );

  // v24 + v27: Gastos sin movimiento_caja_id ni compra_ocasional_id.
  final gastosV23 = DbSchema.createGastos
      .replaceFirst(
        RegExp(
          r',\s*movimiento_caja_id\s+INTEGER\s+REFERENCES\s+MovimientosCaja\(id\)',
        ),
        '',
      )
      .replaceFirst(
        RegExp(
          r',\s*compra_ocasional_id\s+INTEGER\s+REFERENCES\s+ComprasOcasionales\(id\)',
        ),
        '',
      );
  await db.execute('DROP TABLE IF EXISTS Gastos');
  await db.execute(gastosV23);

  // v22: CuentasPorPagar con insumo_id NOT NULL (dispara el rebuild de la v23).
  await db.execute('DROP TABLE IF EXISTS PagosCuentaPorPagar');
  await db.execute('DROP TABLE IF EXISTS CuentasPorPagar');
  await db.execute('''
    CREATE TABLE CuentasPorPagar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      insumo_id INTEGER NOT NULL,
      cantidad REAL NOT NULL,
      costo_total REAL NOT NULL,
      proveedor TEXT,
      proveedor_id INTEGER REFERENCES Proveedores(id),
      factura_ruta TEXT,
      motivo TEXT,
      pagado INTEGER DEFAULT 0,
      monto_pagado REAL NOT NULL DEFAULT 0,
      fecha_pago TEXT,
      usuario_id INTEGER,
      cuotas INTEGER DEFAULT 1,
      adelanto REAL DEFAULT 0,
      activo_fijo_id INTEGER REFERENCES ActivosFijos(id),
      fecha_vencimiento TEXT,
      compra_movimiento_id INTEGER REFERENCES AjustesStock(id)
    )
  ''');
  await db.execute(DbSchema.createPagosCuentaPorPagar);
}
