import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/activo_fijo.dart';

class ActivoFijoRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insert(ActivoFijo activo) async {
    final db = await dbHelper.database;
    return await db.insert('ActivosFijos', activo.toMap());
  }

  Future<int> update(ActivoFijo activo) async {
    final db = await dbHelper.database;
    return await db.update('ActivosFijos', activo.toMap(), where: 'id = ?', whereArgs: [activo.id]);
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    // Borrado logico o fisico. Haremos fisico por simplicidad para la clienta.
    return await db.update('ActivosFijos', {'activo': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivoFijo>> getAll() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('ActivosFijos', orderBy: 'id DESC');
    return maps.map((e) => ActivoFijo.fromMap(e)).toList();
  }
}
