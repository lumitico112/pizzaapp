import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('la migración v26 -> v27 crea ComprasOcasionales y vincula gastos y CxP sin perder datos', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(db.close);

    // Estado mínimo v26: las columnas y la tabla de la v27 todavía no existen.
    await db.execute('''
      CREATE TABLE Usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Proveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        monto REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE CuentasPorPagar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        costo_total REAL NOT NULL
      )
    ''');
    final gastoId = await db.insert('Gastos', {
      'fecha': '2026-10-19',
      'monto': 12.5,
    });
    final cuentaId = await db.insert('CuentasPorPagar', {
      'fecha': '2026-10-19',
      'costo_total': 80.0,
    });

    await DatabaseHelper.instance.upgradeDatabase(db, 26, 27);

    final columnasGastos = await db.rawQuery('PRAGMA table_info(Gastos)');
    final compraOcasionalGasto = columnasGastos.firstWhere(
      (c) => c['name'] == 'compra_ocasional_id',
    );
    expect(compraOcasionalGasto['notnull'], 0);

    final columnasCxp = await db.rawQuery('PRAGMA table_info(CuentasPorPagar)');
    final compraOcasionalCxp = columnasCxp.firstWhere(
      (c) => c['name'] == 'compra_ocasional_id',
    );
    expect(compraOcasionalCxp['notnull'], 0);

    final columnasCabecera = await db.rawQuery(
      'PRAGMA table_info(ComprasOcasionales)',
    );
    final nombresCabecera = columnasCabecera.map((c) => c['name']).toSet();
    expect(
      nombresCabecera,
      containsAll({
        'id',
        'fecha',
        'descripcion',
        'cantidad',
        'unidad_medida',
        'costo_total',
        'categoria',
        'proveedor',
        'proveedor_id',
        'factura_ruta',
        'es_por_pagar',
        'adelanto',
        'cuotas',
        'metodo_pago',
        'usuario_id',
        'created_at',
      }),
    );

    final indices = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'IDX_%'",
    );
    final nombresIndices = indices.map((row) => row['name']).toSet();
    expect(
      nombresIndices,
      containsAll({
        'IDX_ComprasOcasionales_fecha',
        'IDX_Gastos_compra_ocasional',
        'IDX_CuentasPorPagar_compra_ocasional',
      }),
    );

    final gasto = (await db.query(
      'Gastos',
      where: 'id = ?',
      whereArgs: [gastoId],
    )).single;
    final cuenta = (await db.query(
      'CuentasPorPagar',
      where: 'id = ?',
      whereArgs: [cuentaId],
    )).single;
    expect((gasto['monto'] as num).toDouble(), 12.5);
    expect(gasto['compra_ocasional_id'], isNull);
    expect((cuenta['costo_total'] as num).toDouble(), 80.0);
    expect(cuenta['compra_ocasional_id'], isNull);

    // La FK nueva queda activa: un vínculo inexistente se rechaza.
    await db.execute('PRAGMA foreign_keys = ON');
    await expectLater(
      () => db.update(
        'Gastos',
        {'compra_ocasional_id': 999999},
        where: 'id = ?',
        whereArgs: [gastoId],
      ),
      throwsA(anything),
    );
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });
}
