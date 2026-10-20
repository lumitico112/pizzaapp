import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/database/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'la migración v27 -> v28 admite transferencia sin perder ventas, detalles ni índices',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(db.close);

      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('''
        CREATE TABLE Usuarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE Promociones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE VariantesProducto (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT
        )
      ''');
      // Estado v27: el CHECK todavía no admite transferencia.
      await db.execute(
        DbSchema.createVentas.replaceFirst("'transferencia',", ''),
      );
      await db.execute(DbSchema.createDetalleVenta);

      final ventaId = await db.insert('Ventas', {
        'fecha': '2026-10-19',
        'hora': '12:00',
        'usuario_id': null,
        'metodo_pago': 'efectivo',
        'monto_recibido': 20.0,
        'vuelto': 10.0,
        'promocion_id': null,
        'subtotal': 10.0,
        'descuento': 0.0,
        'total': 10.0,
        'anulada': 0,
        'es_historica': 1,
        'nota': 'venta previa a v28',
      });
      final detalleId = await db.insert('DetalleVenta', {
        'venta_id': ventaId,
        'variante_id': null,
        'promocion_id': null,
        'es_cortesia': 0,
        'cantidad': 2,
        'precio_unitario': 5.0,
        'descuento': 0.0,
      });

      await expectLater(
        db.insert('Ventas', {
          'fecha': '2026-10-19',
          'hora': '12:01',
          'metodo_pago': 'transferencia',
          'subtotal': 5.0,
          'total': 5.0,
          'es_historica': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );

      await DatabaseHelper.instance.upgradeDatabase(db, 27, 28);
      await db.execute('PRAGMA foreign_keys = ON');

      final ventaMigrada = (await db.query(
        'Ventas',
        where: 'id = ?',
        whereArgs: [ventaId],
      )).single;
      expect(ventaMigrada['metodo_pago'], 'efectivo');
      expect(ventaMigrada['total'], 10.0);
      expect(ventaMigrada['es_historica'], 1);
      expect(ventaMigrada['nota'], 'venta previa a v28');

      final detalleMigrado = (await db.query(
        'DetalleVenta',
        where: 'id = ?',
        whereArgs: [detalleId],
      )).single;
      expect(detalleMigrado['venta_id'], ventaId);
      expect(detalleMigrado['cantidad'], 2);

      final ventasSql = (await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'Ventas'",
      )).single['sql'] as String;
      expect(ventasSql, contains("'transferencia'"));

      final nuevaVentaId = await db.insert('Ventas', {
        'fecha': '2026-10-19',
        'hora': '12:02',
        'metodo_pago': 'transferencia',
        'subtotal': 8.0,
        'total': 8.0,
        'es_historica': 0,
      });
      expect(nuevaVentaId, greaterThan(ventaId));
      await db.insert('DetalleVenta', {
        'venta_id': nuevaVentaId,
        'variante_id': null,
        'promocion_id': null,
        'es_cortesia': 0,
        'cantidad': 1,
        'precio_unitario': 8.0,
        'descuento': 0.0,
      });

      final indices = await db.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'index' AND tbl_name = 'Ventas' AND name LIKE 'IDX_%'",
      );
      expect(
        indices.map((row) => row['name']),
        containsAll(['IDX_Ventas_fecha_anulada', 'IDX_Ventas_usuario']),
      );
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );
}
