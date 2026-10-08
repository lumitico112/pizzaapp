import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/receta.dart';

class RecetaRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertOrUpdate(RecetaItem item) async {
    final db = await dbHelper.database;
    // Upsert
    final existing = await db.query(
      'Recetas',
      where: 'variante_id = ? AND insumo_id = ?',
      whereArgs: [item.varianteId, item.insumoId],
    );

    if (existing.isNotEmpty) {
      // Update
      return await db.update(
        'Recetas',
        {
          'cantidad': item.cantidad,
          'unidad_medida': item.unidadMedida,
        },
        where: 'variante_id = ? AND insumo_id = ?',
        whereArgs: [item.varianteId, item.insumoId],
      );
    } else {
      // Insert
      return await db.insert('Recetas', item.toMap());
    }
  }

  Future<List<RecetaItem>> getRecetaByVariante(int varianteId) async {
    final db = await dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT r.*, i.nombre as insumo_nombre, i.costo_por_unidad as insumo_costo_unidad, i.unidad_medida as insumo_unidad_base
      FROM Recetas r
      JOIN Insumos i ON r.insumo_id = i.id
      WHERE r.variante_id = ?
    ''', [varianteId]);

    return List.generate(maps.length, (i) {
      return RecetaItem.fromMap(maps[i]);
    });
  }

  Future<void> deleteRecetaItem(int id) async {
    final db = await dbHelper.database;
    await db.delete('Recetas', where: 'id = ?', whereArgs: [id]);
  }
}
