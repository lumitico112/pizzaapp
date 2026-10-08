import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/consumo_estimado.dart';

class ProductoRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Producto>> getProductos({int? categoriaId}) async {
    final db = await dbHelper.database;
    String where = 'activo = 1';
    List<dynamic> args = [];
    if (categoriaId != null && categoriaId > 0) {
      where += ' AND categoria_id = ?';
      args.add(categoriaId);
    }
    final maps = await db.query('Productos', where: where, whereArgs: args.isNotEmpty ? args : null);
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  
  Future<void> actualizarStockVariante(int varianteId, int cantidadAjuste) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE VariantesProducto SET stock = stock + ? WHERE id = ?',
      [cantidadAjuste, varianteId]
    );
  }

  Future<int> insertProducto(Producto p) async {
    final db = await dbHelper.database;
    return await db.insert('Productos', p.toMap());
  }  Future<void> guardarProductoCompleto(Producto p, List<VarianteProducto> variantes) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      int productoId;
      if (p.id == null) {
        productoId = await txn.insert('Productos', p.toMap());
      } else {
        productoId = p.id!;
        await txn.update('Productos', p.toMap(), where: 'id = ?', whereArgs: [productoId]);
        await txn.delete('VariantesProducto', where: 'producto_id = ?', whereArgs: [productoId]);
      }
      
      for (var variante in variantes) {
        final vMap = variante.toMap();
        vMap['producto_id'] = productoId;
        await txn.insert('VariantesProducto', vMap);
      }
    });
  }

  Future<int> updateProducto(Producto p) async {
    final db = await dbHelper.database;
    return await db.update('Productos', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> disableProducto(int id) async {
    final db = await dbHelper.database;
    return await db.update('Productos', {'activo': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProducto(int id) async {
    return disableProducto(id);
  }

  Future<List<VarianteProducto>> getVariantes(int productoId) async {
    return getVariantesPorProducto(productoId);
  }

  Future<List<VarianteProducto>> getVariantesPorProducto(int productoId) async {
    final db = await dbHelper.database;
    final maps = await db.query('VariantesProducto', where: 'producto_id = ?', whereArgs: [productoId]);
    return List.generate(maps.length, (i) => VarianteProducto.fromMap(maps[i]));
  }

  Future<int> insertVariante(VarianteProducto v) async {
    final db = await dbHelper.database;
    return await db.insert('VariantesProducto', v.toMap());
  }

  Future<int> updateVariante(VarianteProducto v) async {
    final db = await dbHelper.database;
    return await db.update('VariantesProducto', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
  }

  Future<int> deleteVariante(int id) async {
    final db = await dbHelper.database;
    return await db.delete('VariantesProducto', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearVariantes(int productoId) async {
    final db = await dbHelper.database;
    return await db.delete('VariantesProducto', where: 'producto_id = ?', whereArgs: [productoId]);
  }

  Future<List<Map<String, dynamic>>> getRecetaCompleta(int varianteId) async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT c.*, i.nombre as insumo_nombre, i.unidad_medida 
      FROM ConsumoEstimadoInsumo c
      JOIN Insumos i ON c.insumo_id = i.id
      WHERE c.variante_id = ?
    ''', [varianteId]);
  }

  Future<int> addInsumoToReceta(ConsumoEstimado c) async {
    final db = await dbHelper.database;
    return await db.insert('ConsumoEstimadoInsumo', c.toMap());
  }

  Future<int> removeInsumoFromReceta(int consumoId) async {
    final db = await dbHelper.database;
    return await db.delete('ConsumoEstimadoInsumo', where: 'id = ?', whereArgs: [consumoId]);
  }

  Future<List<Categoria>> getCategorias() async {
    final db = await dbHelper.database;
    final maps = await db.query('Categorias');
    return List.generate(maps.length, (i) => Categoria.fromMap(maps[i]));
  }

  Future<int> insertCategoria(Categoria c) async {
    final db = await dbHelper.database;
    return await db.insert('Categorias', c.toMap());
  }
  
  Future<int> updateCategoria(Categoria c) async {
    final db = await dbHelper.database;
    return await db.update('Categorias', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCategoria(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Categorias', where: 'id = ?', whereArgs: [id]);
  }
}


