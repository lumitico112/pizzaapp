import 'package:sqflite_sqlcipher/sqflite.dart';

/// The single persistence path for ingredient and prepared-product stock.
/// Callers pass their current transaction so related records stay atomic.
class StockMovementWriter {
  const StockMovementWriter._();

  static Future<int> recordIngredient({
    required DatabaseExecutor executor,
    required int ingredientId,
    required double quantity,
    required String movementType,
    required String reason,
    String? date,
    double unitCost = 0,
    int? supplierId,
  }) async {
    final rows = await executor.query(
      'Insumos',
      where: 'id = ?',
      whereArgs: [ingredientId],
    );
    if (rows.isEmpty) throw Exception('El insumo ya no existe.');

    final current = InsumoStock.fromMap(rows.first);
    final updatedStock = current.quantity + quantity;
    if (updatedStock < -0.000001) {
      final nombreInsumo =
          rows.first['nombre'] as String? ?? 'Insumo #$ingredientId';
      throw Exception('Stock insuficiente para "$nombreInsumo".');
    }

    var updatedUnitCost = current.unitCost;
    if (movementType == 'comprado' && quantity > 0 && unitCost >= 0) {
      final previousQuantity = current.quantity > 0 ? current.quantity : 0;
      final resultingQuantity = previousQuantity + quantity;
      if (resultingQuantity > 0) {
        updatedUnitCost =
            ((previousQuantity * current.unitCost) + (quantity * unitCost)) /
            resultingQuantity;
      }
    }

    final movementId = await executor.insert('AjustesStock', {
      'fecha': date ?? DateTime.now().toIso8601String(),
      'insumo_id': ingredientId,
      'cantidad_ajuste': quantity,
      'tipo_adquisicion': movementType,
      'costo_unitario': unitCost,
      'motivo': reason,
      'proveedor_id': supplierId,
    });
    await executor.update(
      'Insumos',
      {'stock_actual': updatedStock, 'costo_por_unidad': updatedUnitCost},
      where: 'id = ?',
      whereArgs: [ingredientId],
    );
    return movementId;
  }

  static Future<void> changePreparedStock({
    required DatabaseExecutor executor,
    required int variantId,
    required int quantity,
    String movementType = 'ajuste',
    String? reason,
    String? date,
    int? referenceId,
    int? userId,
  }) async {
    if (quantity == 0) return;
    final rootId = await resolveRootVariantId(executor, variantId);
    final rows = await executor.query(
      'VariantesProducto',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [rootId],
    );
    if (rows.isEmpty) throw Exception('El producto preparado ya no existe.');
    final current = (rows.first['stock'] as num?)?.toInt() ?? 0;
    if (current + quantity < 0) {
      throw Exception(
        'Stock preparado insuficiente para registrar el movimiento.',
      );
    }
    final nextStock = current + quantity;
    final family = await executor.rawQuery(
      '''
      SELECT id FROM VariantesProducto
      WHERE id = ? OR (active = 1 AND variante_base_id = ?)
    ''',
      [rootId, rootId],
    );
    for (final row in family) {
      await executor.update(
        'VariantesProducto',
        {'stock': nextStock},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    await executor.insert('MovimientosStockPreparado', {
      'fecha': date ?? DateTime.now().toIso8601String(),
      'variante_id': rootId,
      'cantidad': quantity,
      'tipo': movementType,
      'referencia_id': referenceId,
      'motivo': reason,
      'usuario_id': userId,
    });
  }

  static Future<int> resolveRootVariantId(
    DatabaseExecutor executor,
    int variantId,
  ) async {
    var current = variantId;
    final visited = <int>{};
    while (true) {
      if (!visited.add(current)) {
        throw Exception(
          'La relación de productos derivados contiene un ciclo.',
        );
      }
      final rows = await executor.query(
        'VariantesProducto',
        columns: ['variante_base_id'],
        where: 'id = ?',
        whereArgs: [current],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw Exception('El producto preparado ya no existe.');
      }
      final base = rows.first['variante_base_id'] as int?;
      if (base == null) {
        return current;
      }
      current = base;
    }
  }
}

class InsumoStock {
  final double quantity;
  final double unitCost;

  const InsumoStock(this.quantity, this.unitCost);

  factory InsumoStock.fromMap(Map<String, Object?> map) => InsumoStock(
    (map['stock_actual'] as num?)?.toDouble() ?? 0,
    (map['costo_por_unidad'] as num?)?.toDouble() ?? 0,
  );
}
