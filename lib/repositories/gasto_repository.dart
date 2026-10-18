import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/gasto.dart';

class GastoRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Gasto>> getGastos() async {
    final db = await dbHelper.database;
    final res = await db.query('Gastos', orderBy: 'fecha DESC');
    return res.map((m) => Gasto.fromMap(m)).toList();
  }

  Future<int> insertGasto(Gasto gasto) async {
    final db = await dbHelper.database;
    return db.transaction((txn) async {
      final fechaGasto = gasto.fecha.length >= 10
          ? gasto.fecha.substring(0, 10)
          : gasto.fecha;
      final now = DateTime.now();
      final hoy =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      int? sesionId = gasto.sesionCajaId;
      if (sesionId == null && fechaGasto == hoy) {
        final sesiones = await txn.query(
          'SesionesCaja',
          where: "estado = 'abierta'",
          orderBy: 'id DESC',
          limit: 1,
        );
        if (sesiones.isNotEmpty) sesionId = sesiones.first['id'] as int;
      }
      return txn.insert('Gastos', {
        ...gasto.toMap(),
        'created_at': DateTime.now().toIso8601String(),
        'sesion_caja_id': sesionId,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getGastosRaw() async {
    final db = await dbHelper.database;
    return db.rawQuery('''
      SELECT g.*, a.nombre AS activo_fijo_nombre
      FROM Gastos g
      LEFT JOIN ActivosFijos a ON a.id = g.activo_fijo_id
      ORDER BY g.fecha DESC, g.id DESC
    ''');
  }

  Future<int> updateGasto(Gasto gasto) async {
    final db = await dbHelper.database;
    final values = gasto.toMap();
    values['created_at'] = DateTime.now().toIso8601String();
    if (gasto.sesionCajaId == null) values.remove('sesion_caja_id');
    return await db.update(
      'Gastos',
      values,
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<int> deleteGasto(int id) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'Gastos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('El gasto no existe o ya fue eliminado.');
    }
    final gasto = rows.first;
    final categoria = (gasto['categoria'] as String? ?? '').trim();
    if (gasto['compra_movimiento_id'] != null || categoria == 'Compras') {
      throw Exception(
        'No se puede eliminar un gasto de compra desde Gastos. Anula o corrige la compra desde el módulo de Compras.',
      );
    }
    final linkedPayments = await db.query(
      'PagosCuentaPorPagar',
      columns: ['id'],
      where: 'gasto_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linkedPayments.isNotEmpty || categoria == 'Cuentas por Pagar') {
      throw Exception(
        'No se puede eliminar un abono de deuda desde Gastos. Anula el abono desde Cuentas por Pagar.',
      );
    }
    return await db.delete('Gastos', where: 'id = ?', whereArgs: [id]);
  }
}
