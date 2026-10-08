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
    return await db.insert('Gastos', gasto.toMap());
  }


  Future<List<Map<String, dynamic>>> getGastosRaw() async {
    final db = await dbHelper.database;
    final res = await db.query("Gastos", orderBy: "fecha DESC");
    return res;
  }

  Future<int> updateGasto(Gasto gasto) async {
    final db = await dbHelper.database;
    return await db.update('Gastos', gasto.toMap(), where: 'id = ?', whereArgs: [gasto.id]);
  }

  Future<int> deleteGasto(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Gastos', where: 'id = ?', whereArgs: [id]);
  }
}
