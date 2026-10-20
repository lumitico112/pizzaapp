import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('la migración v25 -> v26 agrega es_historica, venta_id y marca el histórico legado', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(db.close);

    // Estado mínimo v25: las columnas v26 todavía no existen.
    await db.execute('''
        CREATE TABLE Ventas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nota TEXT
        )
      ''');
    await db.execute('''
        CREATE TABLE AjustesStock (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          motivo TEXT
        )
      ''');
    final historicaId = await db.insert('Ventas', {
      'nota': '[REGISTRO HISTÓRICO] Venta anterior',
    });
    final normalId = await db.insert('Ventas', {'nota': 'Venta normal'});

    await DatabaseHelper.instance.upgradeDatabase(db, 25, 26);

    final columnasVentas = await db.rawQuery('PRAGMA table_info(Ventas)');
    final esHistorica = columnasVentas.firstWhere(
      (c) => c['name'] == 'es_historica',
    );
    expect(esHistorica['notnull'], 1);
    expect(esHistorica['dflt_value'], '0');

    final columnasAjustes = await db.rawQuery(
      'PRAGMA table_info(AjustesStock)',
    );
    expect(columnasAjustes.map((c) => c['name']), contains('venta_id'));

    final historica = (await db.query(
      'Ventas',
      where: 'id = ?',
      whereArgs: [historicaId],
    )).single;
    final normal = (await db.query(
      'Ventas',
      where: 'id = ?',
      whereArgs: [normalId],
    )).single;
    expect(historica['es_historica'], 1);
    expect(normal['es_historica'], 0);

    final indices = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?",
      ['IDX_AjustesStock_venta_id'],
    );
    expect(indices, hasLength(1));
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });
}
