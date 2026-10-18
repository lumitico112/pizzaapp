import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/receta.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

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
        {'cantidad': item.cantidad, 'unidad_medida': item.unidadMedida},
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

    List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT r.*, i.nombre as insumo_nombre, i.costo_por_unidad as insumo_costo_unidad, i.unidad_medida as insumo_unidad_base, i.contenido_paquete as insumo_contenido_paquete
      FROM Recetas r
      JOIN Insumos i ON r.insumo_id = i.id
      WHERE r.variante_id = ?
    ''',
      [varianteId],
    );

    if (maps.isEmpty) {
      final recovered = await _recoverOrphanedVariantRecipe(db, varianteId);
      if (recovered) {
        maps = await db.rawQuery(
          '''
          SELECT r.*, i.nombre as insumo_nombre, i.costo_por_unidad as insumo_costo_unidad, i.unidad_medida as insumo_unidad_base, i.contenido_paquete as insumo_contenido_paquete
          FROM Recetas r
          JOIN Insumos i ON r.insumo_id = i.id
          WHERE r.variante_id = ?
        ''',
          [varianteId],
        );
      }
    }

    return List.generate(maps.length, (i) {
      return RecetaItem.fromMap(maps[i]);
    });
  }

  /// Si una variante activa quedó sin filas en `Recetas` porque fue recreada al editar
  /// el producto, recupera la receta desde la variante anterior desactivada (`active = 0`)
  /// del mismo producto.
  Future<bool> _recoverOrphanedVariantRecipe(
    DatabaseExecutor db,
    int varianteId,
  ) async {
    final currentRows = await db.rawQuery(
      '''
      SELECT vp.id, vp.producto_id, vp.nombre_variante, p.nombre AS producto_nombre
      FROM VariantesProducto vp
      JOIN Productos p ON p.id = vp.producto_id
      WHERE vp.id = ?
      LIMIT 1
      ''',
      [varianteId],
    );
    if (currentRows.isEmpty) return false;
    final productoId = currentRows.first['producto_id'] as int;
    final nombreVariante =
        (currentRows.first['nombre_variante'] as String? ?? '').trim();
    final nombreProducto =
        (currentRows.first['producto_nombre'] as String? ?? '').trim();

    final donorRows = await db.rawQuery(
      '''
      SELECT vp.id
      FROM VariantesProducto vp
      JOIN Productos p ON p.id = vp.producto_id
      WHERE vp.id <> ?
        AND (
          vp.producto_id = ?
          OR LOWER(TRIM(p.nombre)) = LOWER(?)
        )
        AND EXISTS (SELECT 1 FROM Recetas r WHERE r.variante_id = vp.id)
      ORDER BY
        CASE WHEN vp.producto_id = ? AND vp.active = 0 THEN 0
             WHEN vp.producto_id = ? THEN 1
             ELSE 2 END,
        CASE WHEN LOWER(TRIM(vp.nombre_variante)) = LOWER(?) THEN 0 ELSE 1 END,
        vp.id DESC
      LIMIT 1
      ''',
      [
        varianteId,
        productoId,
        nombreProducto,
        productoId,
        productoId,
        nombreVariante,
      ],
    );
    if (donorRows.isEmpty) return false;

    final donorId = donorRows.first['id'] as int;
    final inserted = await db.rawInsert(
      '''
      INSERT OR IGNORE INTO Recetas (variante_id, insumo_id, cantidad, unidad_medida)
      SELECT ?, insumo_id, cantidad, unidad_medida
      FROM Recetas
      WHERE variante_id = ?
      ''',
      [varianteId, donorId],
    );
    return inserted > 0;
  }

  Future<void> deleteRecetaItem(int id) async {
    final db = await dbHelper.database;
    await db.delete('Recetas', where: 'id = ?', whereArgs: [id]);
  }
}
