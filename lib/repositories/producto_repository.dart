import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/consumo_estimado.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';
import 'package:pizzaapp/services/image_service.dart';

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
    final maps = await db.query(
      'Productos',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<void> actualizarStockVariante(
    int varianteId,
    int cantidadAjuste,
  ) async {
    final db = await dbHelper.database;
    await db.transaction(
      (txn) => StockMovementWriter.changePreparedStock(
        executor: txn,
        variantId: varianteId,
        quantity: cantidadAjuste,
        movementType: 'ajuste',
        reason: 'Ajuste de stock preparado',
      ),
    );
  }

  Future<int> insertProducto(Producto p) async {
    final db = await dbHelper.database;
    return await db.insert('Productos', p.toMap());
  }

  Future<void> guardarProductoCompleto(
    Producto p,
    List<VarianteProducto> variantes,
  ) async {
    final db = await dbHelper.database;
    final filesToDelete = <String?>[];
    await db.transaction((txn) async {
      if (p.derivaDeProductoId != null && p.derivaDeProductoId == p.id) {
        throw Exception('Un producto no puede derivar de sí mismo.');
      }
      if (p.id != null && p.derivaDeProductoId == null) {
        final previous = await txn.query(
          'Productos',
          columns: ['deriva_de_producto_id'],
          where: 'id = ?',
          whereArgs: [p.id],
          limit: 1,
        );
        if (previous.isNotEmpty &&
            previous.first['deriva_de_producto_id'] != null) {
          final nonzero = await txn.rawQuery(
            'SELECT id FROM VariantesProducto WHERE producto_id = ? AND active = 1 AND COALESCE(stock, 0) <> 0 LIMIT 1',
            [p.id],
          );
          if (nonzero.isNotEmpty) {
            throw Exception(
              'No se puede separar una variante derivada mientras tenga unidades en el stock compartido. Agota o ajusta ese saldo antes.',
            );
          }
        }
      }
      int productoId;
      if (p.id == null) {
        productoId = await txn.insert('Productos', p.toMap());
        for (final variante in variantes) {
          final map = variante.toMap()..remove('id');
          final baseId = map.remove('variante_base_id');
          map['producto_id'] = productoId;
          map['stock'] = 0;
          map['active'] = 1;
          final newId = await txn.insert('VariantesProducto', map);
          if (baseId != null) {
            await txn.update(
              'VariantesProducto',
              {'variante_base_id': baseId},
              where: 'id = ?',
              whereArgs: [newId],
            );
          }
        }
      } else {
        productoId = p.id!;
        final previousProdRows = await txn.query(
          'Productos',
          columns: ['foto_ruta'],
          where: 'id = ?',
          whereArgs: [productoId],
          limit: 1,
        );
        final previousProdFoto = previousProdRows.isNotEmpty
            ? previousProdRows.first['foto_ruta'] as String?
            : null;
        if (previousProdFoto != null &&
            previousProdFoto.trim().isNotEmpty &&
            previousProdFoto != p.fotoRuta) {
          filesToDelete.add(previousProdFoto);
        }

        await txn.update(
          'Productos',
          p.toMap(),
          where: 'id = ?',
          whereArgs: [productoId],
        );
        final existingRows = await txn.query(
          'VariantesProducto',
          columns: ['id', 'nombre_variante', 'imagen'],
          where: 'producto_id = ? AND active = 1',
          whereArgs: [productoId],
        );
        final existingIds = existingRows.map((row) => row['id'] as int).toSet();
        final existingImages = <int, String?>{
          for (final row in existingRows)
            row['id'] as int: row['imagen'] as String?,
        };
        final existingByName = <String, int>{
          for (final row in existingRows)
            (row['nombre_variante'] as String? ?? '').trim().toLowerCase():
                row['id'] as int,
        };
        final matchedIds = <int>{};
        final insertedIds = <int>[];
        for (final variante in variantes) {
          final map = variante.toMap()
            ..remove('id')
            ..remove('stock');
          map['producto_id'] = productoId;
          map['active'] = 1;

          int? targetId =
              (variante.id != null && existingIds.contains(variante.id))
              ? variante.id
              : null;
          if (targetId == null) {
            final byName = existingByName[
                variante.nombreVariante.trim().toLowerCase()];
            if (byName != null && !matchedIds.contains(byName)) {
              targetId = byName;
            }
          }

          if (targetId != null) {
            matchedIds.add(targetId);
            final oldVarImg = existingImages[targetId];
            if (oldVarImg != null &&
                oldVarImg.trim().isNotEmpty &&
                oldVarImg != variante.imagen) {
              filesToDelete.add(oldVarImg);
            }
            await txn.update(
              'VariantesProducto',
              map,
              where: 'id = ? AND producto_id = ?',
              whereArgs: [targetId, productoId],
            );
          } else {
            map['stock'] = 0;
            final newId = await txn.insert('VariantesProducto', map);
            insertedIds.add(newId);
          }
        }
        final removedIds = existingIds.difference(matchedIds).toList();
        if (removedIds.isNotEmpty) {
          // Si se reemplazó una variante por otra nueva, preservar su receta
          if (removedIds.length == 1 && insertedIds.length == 1) {
            final oldVarId = removedIds.first;
            final newVarId = insertedIds.first;
            await txn.rawUpdate(
              'UPDATE OR IGNORE Recetas SET variante_id = ? WHERE variante_id = ?',
              [newVarId, oldVarId],
            );
            await txn.rawUpdate(
              'UPDATE ConsumoEstimadoInsumo SET variante_id = ? WHERE variante_id = ?',
              [newVarId, oldVarId],
            );
          }
          for (final removedId in removedIds) {
            filesToDelete.add(existingImages[removedId]);
          }
          final placeholders = List.filled(removedIds.length, '?').join(',');
          await txn.rawUpdate(
            'UPDATE VariantesProducto SET active = 0, imagen = NULL WHERE id IN ($placeholders)',
            removedIds,
          );
          await txn.rawUpdate(
            'UPDATE Transformaciones SET activa = 0 WHERE variante_origen_id IN ($placeholders) OR variante_destino_id IN ($placeholders)',
            [...removedIds, ...removedIds],
          );
        }
      }
      if (p.derivaDeProductoId != null) {
        final source = await txn.query(
          'Productos',
          columns: ['id'],
          where: 'id = ? AND activo = 1',
          whereArgs: [p.derivaDeProductoId],
          limit: 1,
        );
        if (source.isEmpty || p.derivaDeProductoId == productoId) {
          throw Exception('Selecciona un producto base válido.');
        }

        final childRows = await txn.rawQuery(
          '''
          SELECT
            child.id AS child_id,
            child.variante_base_id AS base_id,
            child.stock AS child_stock,
            base.producto_id AS base_producto_id,
            base.active AS base_active,
            base.stock AS base_stock
          FROM VariantesProducto child
          LEFT JOIN VariantesProducto base ON base.id = child.variante_base_id
          WHERE child.producto_id = ? AND child.active = 1
        ''',
          [productoId],
        );

        if (childRows.isEmpty) {
          throw Exception(
            'El producto derivado requiere variantes vinculadas al producto base.',
          );
        }

        for (final row in childRows) {
          final baseId = row['base_id'] as int?;
          if (baseId == null) {
            throw Exception(
              'Asigna una variante base a cada variante derivada.',
            );
          }
          final baseProductoId = row['base_producto_id'] as int?;
          if (baseProductoId != p.derivaDeProductoId) {
            throw Exception(
              'La variante seleccionada no pertenece al producto base elegido.',
            );
          }
          final baseActive = row['base_active'] as int?;
          if (baseActive != 1) {
            throw Exception(
              'Una variante base seleccionada ya no está disponible.',
            );
          }
          final targetStock = (row['child_stock'] as num?)?.toInt() ?? 0;
          final baseStock = (row['base_stock'] as num?)?.toInt() ?? 0;
          if (targetStock != 0 && targetStock != baseStock) {
            throw Exception(
              'La variante derivada tiene stock propio. Ajusta ese saldo a cero antes de vincularla para no perder ni duplicar inventario.',
            );
          }
        }

        await txn.rawUpdate(
          '''
          UPDATE VariantesProducto
          SET stock = (SELECT base.stock FROM VariantesProducto base WHERE base.id = VariantesProducto.variante_base_id)
          WHERE producto_id = ? AND active = 1
        ''',
          [productoId],
        );
      }
    });
    if (filesToDelete.isNotEmpty) {
      await ImageService.deleteLocalFiles(filesToDelete);
    }
  }

  Future<int> updateProducto(Producto p) async {
    final db = await dbHelper.database;
    String? previousFoto;
    if (p.id != null) {
      final rows = await db.query(
        'Productos',
        columns: ['foto_ruta'],
        where: 'id = ?',
        whereArgs: [p.id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        previousFoto = rows.first['foto_ruta'] as String?;
      }
    }
    final count = await db.update(
      'Productos',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    if (previousFoto != null &&
        previousFoto.trim().isNotEmpty &&
        previousFoto != p.fotoRuta) {
      await ImageService.deleteLocalFile(previousFoto);
    }
    return count;
  }

  Future<int> disableProducto(int id) async {
    final db = await dbHelper.database;
    final prodRows = await db.query(
      'Productos',
      columns: ['foto_ruta'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final varRows = await db.query(
      'VariantesProducto',
      columns: ['imagen'],
      where: 'producto_id = ?',
      whereArgs: [id],
    );
    final filesToDelete = <String?>[
      if (prodRows.isNotEmpty) prodRows.first['foto_ruta'] as String?,
      for (final row in varRows) row['imagen'] as String?,
    ];
    final count = await db.update(
      'Productos',
      {'activo': 0, 'foto_ruta': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.update(
      'VariantesProducto',
      {'imagen': null},
      where: 'producto_id = ?',
      whereArgs: [id],
    );
    await ImageService.deleteLocalFiles(filesToDelete);
    return count;
  }

  Future<int> deleteProducto(int id) async {
    return disableProducto(id);
  }

  Future<List<VarianteProducto>> getVariantes(int productoId) async {
    return getVariantesPorProducto(productoId);
  }

  Future<List<VarianteProducto>> getVariantesPorProducto(int productoId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'VariantesProducto',
      where: 'producto_id = ? AND active = 1',
      whereArgs: [productoId],
    );
    return List.generate(maps.length, (i) => VarianteProducto.fromMap(maps[i]));
  }

  Future<int> insertVariante(VarianteProducto v) async {
    final db = await dbHelper.database;
    return await db.insert('VariantesProducto', v.toMap());
  }

  Future<int> updateVariante(VarianteProducto v) async {
    final db = await dbHelper.database;
    return await db.update(
      'VariantesProducto',
      v.toMap(),
      where: 'id = ?',
      whereArgs: [v.id],
    );
  }

  Future<int> deleteVariante(int id) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'VariantesProducto',
      columns: ['imagen'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final oldImg = rows.isNotEmpty ? rows.first['imagen'] as String? : null;
    final count = await db.update(
      'VariantesProducto',
      {'active': 0, 'imagen': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await ImageService.deleteLocalFile(oldImg);
    return count;
  }

  Future<int> clearVariantes(int productoId) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'VariantesProducto',
      columns: ['imagen'],
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
    final filesToDelete = rows.map((r) => r['imagen'] as String?).toList();
    final count = await db.update(
      'VariantesProducto',
      {'active': 0, 'imagen': null},
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
    await ImageService.deleteLocalFiles(filesToDelete);
    return count;
  }

  Future<List<Map<String, dynamic>>> getRecetaCompleta(int varianteId) async {
    final db = await dbHelper.database;
    return await db.rawQuery(
      '''
      SELECT c.*, i.nombre as insumo_nombre, i.unidad_medida 
      FROM ConsumoEstimadoInsumo c
      JOIN Insumos i ON c.insumo_id = i.id
      WHERE c.variante_id = ?
    ''',
      [varianteId],
    );
  }

  Future<int> addInsumoToReceta(ConsumoEstimado c) async {
    final db = await dbHelper.database;
    return await db.insert('ConsumoEstimadoInsumo', c.toMap());
  }

  Future<int> removeInsumoFromReceta(int consumoId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ConsumoEstimadoInsumo',
      where: 'id = ?',
      whereArgs: [consumoId],
    );
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
    return await db.update(
      'Categorias',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<int> deleteCategoria(int id) async {
    final db = await dbHelper.database;
    return await db.delete('Categorias', where: 'id = ?', whereArgs: [id]);
  }
}
