import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/merma.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';

class MermaRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Merma>> getMermas() async {
    final db = await dbHelper.database;
    final res = await db.rawQuery('''
      SELECT m.*,
             i.nombre as insumo_nombre,
             CASE
               WHEN v.id IS NOT NULL AND p.nombre IS NOT NULL
                 THEN p.nombre || ' · ' || v.nombre_variante
               WHEN v.id IS NOT NULL
                 THEN v.nombre_variante
               ELSE NULL
             END as variante_nombre
      FROM Merma m
      LEFT JOIN Insumos i ON m.insumo_id = i.id
      LEFT JOIN VariantesProducto v ON m.variante_id = v.id
      LEFT JOIN Productos p ON v.producto_id = p.id
      ORDER BY m.fecha DESC
    ''');
    return res.map((m) => Merma.fromMap(m)).toList();
  }

  Future<int> insertMerma(Merma merma) async {
    final db = await dbHelper.database;
    return db.transaction((txn) async {
      if (merma.insumoId != null) {
        final ingredient = await txn.query(
          'Insumos',
          columns: ['costo_por_unidad'],
          where: 'id = ?',
          whereArgs: [merma.insumoId],
          limit: 1,
        );
        final unitCost = ingredient.isEmpty
            ? 0.0
            : (ingredient.first['costo_por_unidad'] as num?)?.toDouble() ?? 0;
        await StockMovementWriter.recordIngredient(
          executor: txn,
          ingredientId: merma.insumoId!,
          quantity: -merma.cantidad,
          movementType: 'merma',
          reason: 'Merma ${merma.tipo}: ${merma.descripcion ?? ''}',
          date: merma.fecha,
          unitCost: unitCost,
        );
      } else if (merma.varianteId != null) {
        if (merma.cantidad % 1 != 0) {
          throw Exception('La merma de productos preparados debe ser entera.');
        }
        await StockMovementWriter.changePreparedStock(
          executor: txn,
          variantId: merma.varianteId!,
          quantity: -merma.cantidad.toInt(),
          movementType: 'merma',
          reason: 'Merma ${merma.tipo}: ${merma.descripcion ?? ''}',
        );
      }
      return txn.insert('Merma', merma.toMap());
    });
  }

  Future<List<Map<String, dynamic>>> getMermasValoradasHoy() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return db.rawQuery(
      '''
      SELECT a.id, a.fecha, a.motivo AS descripcion, i.nombre AS insumo_nombre,
             ABS(a.cantidad_ajuste) * a.costo_unitario AS monto
      FROM AjustesStock a
      JOIN Insumos i ON i.id = a.insumo_id
      WHERE a.tipo_adquisicion = 'merma'
        AND a.costo_unitario > 0
        AND substr(a.fecha, 1, 10) = ?
      ORDER BY a.fecha DESC, a.id DESC
      ''',
      [today],
    );
  }

  Future<void> registrarMermaPreparacion({
    required int itemId,
    required int cantidad,
  }) async {
    if (cantidad <= 0) throw Exception('La cantidad debe ser mayor a 0.');
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final activeSessions = await txn.query(
        'SesionesCaja',
        columns: ['id'],
        where: "estado = 'abierta'",
        limit: 1,
      );
      if (activeSessions.isEmpty) {
        throw Exception(
          'Abre la caja antes de registrar la merma de preparación.',
        );
      }
      final rows = await txn.query(
        'ItemsPreparacion',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      if (rows.isEmpty) throw Exception('El producto preparado ya no existe.');
      final item = rows.first;
      final alreadyWasted = (item['enviado_merma'] as num?)?.toInt() ?? 0;
      final prepared = (item['cantidad_preparada'] as num?)?.toInt() ?? 0;
      final carried = (item['llevado_manana'] as num?)?.toInt() ?? 0;
      if (alreadyWasted + carried + cantidad > prepared) {
        throw Exception('La merma supera las unidades preparadas disponibles.');
      }
      final variantId = item['variante_id'] as int;
      await StockMovementWriter.changePreparedStock(
        executor: txn,
        variantId: variantId,
        quantity: -cantidad,
        movementType: 'merma',
        reason: 'Merma desde preparación #$itemId',
        referenceId: itemId,
      );
      await txn.insert(
        'Merma',
        Merma(
          fecha: DateTime.now().toIso8601String(),
          tipo: 'otro',
          descripcion: 'Merma desde preparación',
          varianteId: variantId,
          cantidad: cantidad.toDouble(),
        ).toMap(),
      );
      await txn.update(
        'ItemsPreparacion',
        {'enviado_merma': alreadyWasted + cantidad},
        where: 'id = ?',
        whereArgs: [itemId],
      );
    });
  }
}
