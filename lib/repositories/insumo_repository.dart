import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';
import 'package:pizzaapp/models/categoria_insumo.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/services/image_service.dart';

/// Legacy shared data source for the ingredient catalog and stock adjustments.
/// Purchase and payable persistence now live in the purchases feature.
class InsumoRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertInsumo(Insumo insumo) async {
    final db = await dbHelper.database;
    return db.insert('Insumos', insumo.toMap());
  }

  Future<List<Insumo>> getInsumos() async {
    final db = await dbHelper.database;
    final rows = await db.query('Insumos', where: 'activo = 1');
    return rows.map(Insumo.fromMap).toList();
  }

  Future<int> updateInsumo(Insumo insumo) async {
    final db = await dbHelper.database;
    String? previousFoto;
    if (insumo.id != null) {
      final existing = await db.query(
        'Insumos',
        columns: ['foto_ruta'],
        where: 'id = ?',
        whereArgs: [insumo.id],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        previousFoto = existing.first['foto_ruta'] as String?;
      }
    }
    final count = await db.update(
      'Insumos',
      insumo.toMap(),
      where: 'id = ?',
      whereArgs: [insumo.id],
    );
    if (previousFoto != null &&
        previousFoto.trim().isNotEmpty &&
        previousFoto != insumo.fotoRuta) {
      await ImageService.deleteLocalFile(previousFoto);
    }
    return count;
  }

  Future<int> deleteInsumo(int id) async {
    final db = await dbHelper.database;
    final existing = await db.query(
      'Insumos',
      columns: ['foto_ruta'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final previousFoto = existing.isNotEmpty
        ? existing.first['foto_ruta'] as String?
        : null;
    final count = await db.update(
      'Insumos',
      {'activo': 0, 'foto_ruta': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await ImageService.deleteLocalFile(previousFoto);
    return count;
  }

  Future<List<CategoriaInsumo>> getCategoriasInsumo() async {
    final db = await dbHelper.database;
    final rows = await db.query('CategoriasInsumo');
    return rows.map(CategoriaInsumo.fromMap).toList();
  }

  Future<int> insertCategoriaInsumo(CategoriaInsumo cat) async {
    final db = await dbHelper.database;
    return db.insert('CategoriasInsumo', cat.toMap());
  }

  Future<int> deleteCategoriaInsumo(int id) async {
    final db = await dbHelper.database;
    return db.delete('CategoriasInsumo', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> ajustarStock({
    required int insumoId,
    required double cantidadAjuste,
    String? tipoAdquisicion,
    String? motivo,
    double costoUnitario = 0,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) => StockMovementWriter.recordIngredient(
          executor: txn,
          ingredientId: insumoId,
          quantity: cantidadAjuste,
          movementType: tipoAdquisicion ?? 'ajuste',
          reason: motivo ?? 'Ajuste manual',
          unitCost: costoUnitario,
        ));
  }
}
