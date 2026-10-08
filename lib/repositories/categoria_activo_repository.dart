import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/categoria_activo.dart';

class CategoriaActivoRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<CategoriaActivo>> getCategorias() async {
    final db = await dbHelper.database;
    final res = await db.query('CategoriasActivo');
    return res.map((e) => CategoriaActivo.fromMap(e)).toList();
  }

  Future<int> insertCategoria(CategoriaActivo categoria) async {
    final db = await dbHelper.database;
    return await db.insert('CategoriasActivo', categoria.toMap());
  }

  Future<int> updateCategoria(CategoriaActivo categoria) async {
    final db = await dbHelper.database;
    return await db.update(
      'CategoriasActivo',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> deleteCategoria(int id) async {
    final db = await dbHelper.database;
    return await db.delete('CategoriasActivo', where: 'id = ?', whereArgs: [id]);
  }
}
