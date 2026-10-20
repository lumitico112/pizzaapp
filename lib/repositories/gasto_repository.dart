import 'package:pizzaapp/core/database/database_helper.dart';

class GastoRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getGastosRaw() async {
    final db = await dbHelper.database;
    return db.rawQuery('''
      SELECT g.*, a.nombre AS activo_fijo_nombre
      FROM Gastos g
      LEFT JOIN ActivosFijos a ON a.id = g.activo_fijo_id
      WHERE g.compra_ocasional_id IS NULL
      ORDER BY g.fecha DESC, g.id DESC
    ''');
  }
}
