import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/merma.dart';

class MermaRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Merma>> getMermas() async {
    final db = await dbHelper.database;
    final res = await db.rawQuery('''
      SELECT m.*, i.nombre as insumo_nombre, v.nombre_variante as variante_nombre
      FROM Merma m
      LEFT JOIN Insumos i ON m.insumo_id = i.id
      LEFT JOIN VariantesProducto v ON m.variante_id = v.id
      ORDER BY m.fecha DESC
    ''');
    return res.map((m) => Merma.fromMap(m)).toList();
  }

  Future<int> insertMerma(Merma merma) async {
    final db = await dbHelper.database;
    return await db.insert('Merma', merma.toMap());
  }
}
