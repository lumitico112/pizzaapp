import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/utils/sugerencias_algoritmo.dart';
import 'package:pizzaapp/features/inventory/domain/services/unit_converter.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';
import 'package:pizzaapp/features/inventory/domain/services/recipe_yield_calculator.dart';
import 'package:pizzaapp/models/preparacion.dart';
import 'package:pizzaapp/models/merma.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:pizzaapp/core/database/audit_log_writer.dart';

class PreparacionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> _ensureOpenCash(DatabaseExecutor executor) async {
    final sessions = await executor.query(
      'SesionesCaja',
      columns: ['id'],
      where: "estado = 'abierta'",
      limit: 1,
    );
    if (sessions.isEmpty) {
      throw Exception('Abre la caja antes de modificar la preparación.');
    }
  }

  Future<int> _getRootVariantStock(
    DatabaseExecutor executor,
    int variantId,
  ) async {
    final rootId = await StockMovementWriter.resolveRootVariantId(
      executor,
      variantId,
    );
    final rows = await executor.query(
      'VariantesProducto',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [rootId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['stock'] as num?)?.toInt() ?? 0;
  }

  // Registra la preparacion del dia
  Future<int> registrarPreparacion({
    required String fecha,
    required List<Map<String, dynamic>> items, // [{varianteId, cantidad}]
    String? nota,
    Map<int, int> sobrantesAPreparacion = const {},
    Map<int, int> sobrantesAMerma = const {},
    Map<int, int> trasladadosPorVariante = const {},
  }) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      await _ensureOpenCash(txn);

      final existing = await txn.query(
        'PreparacionDiaria',
        where: 'fecha = ?',
        whereArgs: [fecha],
      );
      final prepId = existing.isNotEmpty
          ? existing.first['id'] as int
          : await txn.insert('PreparacionDiaria', {
              'fecha': fecha,
              'nota': nota,
              'created_at': DateTime.now().toIso8601String(),
            });
      if (existing.isNotEmpty) {
        await txn.update(
          'PreparacionDiaria',
          {'nota': nota},
          where: 'id = ?',
          whereArgs: [prepId],
        );
      }

      final carriedByVariant = Map<int, int>.from(trasladadosPorVariante);
      final stagedIds = <int>{
        ...sobrantesAPreparacion.keys,
        ...sobrantesAMerma.keys,
      };
      for (final itemId in stagedIds) {
        final carry = sobrantesAPreparacion[itemId] ?? 0;
        final waste = sobrantesAMerma[itemId] ?? 0;
        if (carry < 0 || waste < 0) {
          throw Exception('La selección de sobrantes no es válida.');
        }
        if (carry == 0 && waste == 0) continue;

        final sourceRows = await txn.rawQuery(
          '''
          SELECT ip.*, p.fecha
          FROM ItemsPreparacion ip
          JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
          WHERE ip.id = ?
          LIMIT 1
          ''',
          [itemId],
        );
        if (sourceRows.isEmpty) {
          throw Exception('El sobrante seleccionado ya no está disponible.');
        }
        final source = sourceRows.first;
        final prepared = (source['cantidad_preparada'] as num).toInt();
        final alreadyWasted =
            (source['enviado_merma'] as num?)?.toInt() ?? 0;
        final alreadyCarried =
            (source['llevado_manana'] as num?)?.toInt() ?? 0;
        final remaining = prepared - alreadyWasted - alreadyCarried;
        if (carry + waste > remaining) {
          throw Exception(
            'La cantidad seleccionada supera el sobrante disponible. Actualiza la lista e inténtalo de nuevo.',
          );
        }
        final variantId = source['variante_id'] as int;
        final currentStock = await _getRootVariantStock(txn, variantId);
        if (carry + waste > currentStock) {
          throw Exception(
            'La cantidad seleccionada (${carry + waste}) supera el stock físico actual ($currentStock).',
          );
        }

        if (waste > 0) {
          await StockMovementWriter.changePreparedStock(
            executor: txn,
            variantId: variantId,
            quantity: -waste,
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
              cantidad: waste.toDouble(),
            ).toMap(),
          );
        }

        if (carry > 0) {
          // El traslado solo se marca en el origen. El campo de hoy contiene
          // el total (sobrante + unidades nuevas) y se guarda más abajo.
          // El stock físico ya existe, por eso el traslado no lo vuelve a crear.
          carriedByVariant.update(
            variantId,
            (current) => current + carry,
            ifAbsent: () => carry,
          );
        }

        final newWasted = alreadyWasted + waste;
        final newCarried = alreadyCarried + carry;
        await txn.update(
          'ItemsPreparacion',
          {
            'enviado_merma': newWasted,
            'llevado_manana': newCarried,
            'sobrante': newWasted + newCarried,
            'resuelto': 1,
          },
          where: 'id = ?',
          whereArgs: [itemId],
        );
      }

      for (final item in items) {
        final existingItem = await txn.query(
          'ItemsPreparacion',
          where: 'preparacion_id = ? AND variante_id = ?',
          whereArgs: [prepId, item['varianteId']],
          limit: 1,
        );
        if ((item['cantidad'] as num) != 0 || existingItem.isNotEmpty) {
          final derived = await txn.query(
            'VariantesProducto',
            columns: ['variante_base_id'],
            where: 'id = ?',
            whereArgs: [item['varianteId']],
            limit: 1,
          );
          if (derived.isNotEmpty &&
              derived.first['variante_base_id'] != null &&
              (item['cantidad'] as num) > 0) {
            throw Exception(
              'La variante derivada comparte el stock de su producto base; registra la preparación solo en la variante base.',
            );
          }
          final old = existingItem.isEmpty ? null : existingItem.first;
          final oldQuantity =
              (old?['cantidad_preparada'] as num?)?.toInt() ?? 0;
          final oldWaste = (old?['enviado_merma'] as num?)?.toInt() ?? 0;
          final oldEffective = (oldQuantity - oldWaste).clamp(0, oldQuantity);
          final newQuantity = (item['cantidad'] as num).toInt();
          final minimumFromStagedCarry =
              carriedByVariant[item['varianteId'] as int] ?? 0;
          if (newQuantity < minimumFromStagedCarry) {
            throw Exception(
              'La cantidad no puede quedar por debajo de los sobrantes que se pasarán a hoy.',
            );
          }
          final delta = newQuantity - oldEffective;
          final carried = carriedByVariant[item['varianteId'] as int] ?? 0;
          final newlyCarried = old == null
              ? carried
              : (carried - oldEffective).clamp(0, carried);
          final physicalDelta = delta - newlyCarried;
          if (physicalDelta > 0) {
            final perGlassBeverage = await txn.rawQuery(
              '''
              SELECT vp.nombre_variante
              FROM VariantesProducto vp
              JOIN Productos p ON p.id = vp.producto_id
              JOIN Categorias c ON c.id = p.categoria_id
              WHERE vp.id = ?
                AND LOWER(c.nombre) LIKE '%bebida%'
                AND LOWER(vp.nombre_variante) LIKE '%vaso%'
              LIMIT 1
              ''',
              [item['varianteId']],
            );
            if (perGlassBeverage.isNotEmpty) {
              throw Exception(
                'La variante por vaso se descuenta directamente desde su receta al vender; no la registres en preparación.',
              );
            }
          }
          if ((oldQuantity > 0 && newQuantity < 0) ||
              (oldQuantity < 0 && newQuantity > 0)) {
            throw Exception(
              'Corrige el valor hasta cero antes de cambiar entre faltante y preparación física.',
            );
          }
          if (old == null) {
            await txn.insert('ItemsPreparacion', {
              'preparacion_id': prepId,
              'variante_id': item['varianteId'],
              'cantidad_preparada': newQuantity,
              'notas': item['notas'],
              'resuelto': 1,
            });
          } else {
            final committed =
                ((old['enviado_merma'] as num?)?.toInt() ?? 0) +
                ((old['llevado_manana'] as num?)?.toInt() ?? 0);
            if (newQuantity < committed) {
              throw Exception(
                'No puedes reducir la preparación por debajo de lo ya transferido o registrado como merma.',
              );
            }
            await txn.update(
              'ItemsPreparacion',
              {
                'cantidad_preparada': newQuantity,
                'notas': item['notas'],
                'resuelto': 1,
              },
              where: 'id = ?',
              whereArgs: [old['id']],
            );
          }

          // Resolver cualquier registro previo que hubiera quedado sin resolver para esta variante
          await txn.update(
            'ItemsPreparacion',
            {'resuelto': 1},
            where: 'variante_id = ? AND preparacion_id != ? AND resuelto = 0',
            whereArgs: [item['varianteId'], prepId],
          );

          if (physicalDelta != 0) {
            if (physicalDelta < 0 && newQuantity < 0) {
              // Historical shortage entries are demand signals, not physical stock.
            } else {
              if (newQuantity >= 0 && oldQuantity >= 0) {
                final recipeRequirements = await txn.rawQuery(
                  '''
              SELECT r.cantidad, r.unidad_medida AS unidad_receta,
                     i.unidad_medida AS unidad_stock, i.contenido_paquete,
                     i.stock_actual
              FROM Recetas r
              JOIN Insumos i ON i.id = r.insumo_id
              WHERE r.variante_id = ?
            ''',
                  [item['varianteId']],
                );
                if (recipeRequirements.isNotEmpty) {
                  final maxPortions = RecipeYieldCalculator.maxPortions(
                    recipeRequirements,
                  );
                  if (physicalDelta > 0 && physicalDelta > maxPortions) {
                    throw Exception(
                      'La receta solo permite preparar $maxPortions unidad(es) con el stock actual.',
                    );
                  }
                }
                // 1. Aumentar stock del producto preparado
                await StockMovementWriter.changePreparedStock(
                  executor: txn,
                  variantId: item['varianteId'] as int,
                  quantity: physicalDelta,
                  movementType: physicalDelta > 0
                      ? 'preparacion'
                      : 'correccion_preparacion',
                  reason: 'Ajuste preparación diaria #$prepId',
                  referenceId: prepId,
                );

                // 2. Descontar los insumos segÃºn la Receta
                final recetaItems = await txn.query(
                  'Recetas',
                  where: 'variante_id = ?',
                  whereArgs: [item['varianteId']],
                );

                for (var ri in recetaItems) {
                  final insumoId = ri['insumo_id'] as int;
                  final cantReceta = (ri['cantidad'] as num).toDouble();
                  final unidadReceta = ri['unidad_medida'] as String;

                  final insumo = await txn.query(
                    'Insumos',
                    where: 'id = ?',
                    whereArgs: [insumoId],
                  );
                  if (insumo.isNotEmpty) {
                    final unidadInsumo =
                        insumo.first['unidad_medida'] as String;
                    final contenidoPaquete =
                        (insumo.first['contenido_paquete'] as num?)?.toInt() ??
                        1;
                    final cantADescontarBase = UnitConverter.convert(
                      cantReceta,
                      unidadReceta,
                      unidadInsumo,
                      packageContent: contenidoPaquete,
                    );

                    if (cantADescontarBase > 0) {
                      final cantTotal =
                          cantADescontarBase * physicalDelta.abs();
                      await StockMovementWriter.recordIngredient(
                        executor: txn,
                        ingredientId: insumoId,
                        quantity: physicalDelta > 0 ? -cantTotal : cantTotal,
                        movementType: physicalDelta > 0
                            ? 'consumo'
                            : 'reversion_consumo',
                        reason:
                            'Ajuste de preparación, variante ${item['varianteId']}',
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
      await AuditLogWriter.record(
        txn,
        action: 'preparacion_diaria_guardada',
        detail:
            'Preparación #$prepId; traslados ${sobrantesAPreparacion.values.fold<int>(0, (sum, value) => sum + value)}; mermas ${sobrantesAMerma.values.fold<int>(0, (sum, value) => sum + value)}.',
      );
      return prepId;
    });
  }

  // Obtiene preparacion de un dia
  Future<Map<String, dynamic>?> getPreparacionDia(String fecha) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'PreparacionDiaria',
      where: 'fecha = ?',
      whereArgs: [fecha],
    );
    if (rows.isEmpty) return null;
    final preparation = rows.first;
    return {
      ...preparation,
      'items': await getItemsPreparacion(preparation['id'] as int),
    };
  }

  // Obtiene items de una preparacion
  Future<List<Map<String, dynamic>>> getItemsPreparacion(int prepId) async {
    final db = await dbHelper.database;
    return await db.rawQuery(
      '''
      SELECT ip.*, vp.nombre_variante, vp.precio_venta, p.nombre as producto_nombre
      FROM ItemsPreparacion ip
      JOIN VariantesProducto vp ON ip.variante_id = vp.id
      JOIN Productos p ON vp.producto_id = p.id
      WHERE ip.preparacion_id = ?
    ''',
      [prepId],
    );
  }

  // Calcular sugerencias basadas en el nuevo algoritmo
  Future<List<Map<String, dynamic>>> getSugerencias({
    int? targetWeekday,
  }) async {
    final db = await dbHelper.database;

    // Obtenemos la fecha actual, o si pasan targetWeekday, construimos una fecha para ese dÃ­a
    DateTime fechaBase = DateTime.now();
    if (targetWeekday != null) {
      int difference = targetWeekday - fechaBase.weekday;
      fechaBase = fechaBase.add(Duration(days: difference));
    }

    // 1. Obtener todas las variantes activas
    final variantesActivas = await db.rawQuery('''
      SELECT vp.id as variante_id, vp.nombre_variante, p.nombre as producto_nombre
      FROM VariantesProducto vp
      JOIN Productos p ON vp.producto_id = p.id
      WHERE p.activo = 1
    ''');

    List<Map<String, dynamic>> resultado = [];

    // 2. Calcular sugerencia para cada variante
    for (var v in variantesActivas) {
      final int varianteId = v['variante_id'] as int;
      final calculo = await SugerenciasAlgoritmo.calcularSugerencia(
        db: db,
        varianteId: varianteId,
        fechaSugerencia: fechaBase,
      );

      resultado.add({
        'variante_id': varianteId,
        'producto_nombre': v['producto_nombre'],
        'variante_nombre': v['nombre_variante'],
        'promedioVentas': calculo['promedioVentas'],
        'promedioFaltantes': calculo['promedioFaltantes'],
        'promedioSobrantes': calculo['promedioSobrantes'],
        'sugerenciaFinal': calculo['sugerenciaFinal'],
      });
    }

    // Ordenar por sugerencia de mayor a menor
    resultado.sort(
      (a, b) =>
          (b['sugerenciaFinal'] as int).compareTo(a['sugerenciaFinal'] as int),
    );

    return resultado;
  }

  // Obtener historial reciente de preparaciones
  Future<List<Map<String, dynamic>>> getHistorialPreparaciones({
    int limit = 7,
  }) async {
    final db = await dbHelper.database;
    final preps = await db.query(
      'PreparacionDiaria',
      orderBy: 'fecha DESC',
      limit: limit,
    );

    List<Map<String, dynamic>> resultado = [];
    for (final prep in preps) {
      final items = await getItemsPreparacion(prep['id'] as int);
      resultado.add({...prep, 'items': items});
    }
    return resultado;
  }

  Future<void> llevarParaManana(int itemId, int cantidad) async {
    if (cantidad <= 0) throw Exception('La cantidad debe ser mayor a cero.');
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await _ensureOpenCash(txn);
      final rows = await txn.rawQuery(
        '''
        SELECT ip.*, vp.stock, p.fecha FROM ItemsPreparacion ip
        JOIN VariantesProducto vp ON vp.id = ip.variante_id
        JOIN PreparacionDiaria p ON p.id = ip.preparacion_id WHERE ip.id = ?
      ''',
        [itemId],
      );
      if (rows.isEmpty) throw Exception('El sobrante ya no existe.');
      final item = rows.first;
      final variantId = item['variante_id'] as int;
      final prepared = (item['cantidad_preparada'] as num).toInt();
      final wasted = (item['enviado_merma'] as num?)?.toInt() ?? 0;
      final carried = (item['llevado_manana'] as num?)?.toInt() ?? 0;
      if (cantidad > prepared - wasted - carried) {
        throw Exception('La cantidad supera el sobrante pendiente.');
      }
      final currentStock = await _getRootVariantStock(txn, variantId);
      if (cantidad > currentStock) {
        throw Exception(
          'La cantidad a trasladar ($cantidad) supera el stock físico disponible ($currentStock).',
        );
      }
      final newCarried = carried + cantidad;
      final newSobrante = wasted + newCarried;
      final updatedCount = await txn.update(
        'ItemsPreparacion',
        {
          'llevado_manana': newCarried,
          'sobrante': newSobrante,
          'resuelto': (newSobrante >= prepared) ? 1 : (item['resuelto'] ?? 0),
        },
        where: 'id = ? AND COALESCE(llevado_manana, 0) = ?',
        whereArgs: [itemId, carried],
      );
      if (updatedCount != 1) {
        throw Exception(
          'El sobrante fue modificado por otra operación. Actualiza e inténtalo de nuevo.',
        );
      }
      final origin =
          DateTime.tryParse(item['fecha'] as String? ?? '') ?? DateTime.now();
      final nextDate = DateTime(
        origin.year,
        origin.month,
        origin.day + 1,
      ).toIso8601String().split('T').first;
      final nextPrepRows = await txn.query(
        'PreparacionDiaria',
        where: 'fecha = ?',
        whereArgs: [nextDate],
        limit: 1,
      );
      final nextPrepId = nextPrepRows.isEmpty
          ? await txn.insert('PreparacionDiaria', {
              'fecha': nextDate,
              'nota': 'Continuidad de sobrantes del ${item['fecha']}',
              'created_at': DateTime.now().toIso8601String(),
            })
          : nextPrepRows.first['id'] as int;
      final existingTargetItems = await txn.query(
        'ItemsPreparacion',
        where: 'preparacion_id = ? AND variante_id = ?',
        whereArgs: [nextPrepId, variantId],
        limit: 1,
      );
      if (existingTargetItems.isEmpty) {
        await txn.insert('ItemsPreparacion', {
          'preparacion_id': nextPrepId,
          'variante_id': variantId,
          'cantidad_preparada': cantidad,
          'notas': 'Trasladado desde preparación del ${item['fecha']}',
        });
      } else {
        final targetItem = existingTargetItems.first;
        final currentTargetQty =
            (targetItem['cantidad_preparada'] as num?)?.toInt() ?? 0;
        await txn.update(
          'ItemsPreparacion',
          {
            'cantidad_preparada': currentTargetQty + cantidad,
            'notas':
                targetItem['notas'] ??
                'Trasladado desde preparación del ${item['fecha']}',
          },
          where: 'id = ?',
          whereArgs: [targetItem['id']],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getSobrantesPendientes() async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT ip.id, ip.preparacion_id, ip.variante_id, ip.cantidad_preparada,
             COALESCE(ip.enviado_merma, 0) AS enviado_merma,
             COALESCE(ip.llevado_manana, 0) AS llevado_manana,
             p.fecha, vp.nombre_variante, vp.stock, pr.nombre AS producto_nombre,
             (ip.cantidad_preparada - COALESCE(ip.enviado_merma, 0) - COALESCE(ip.llevado_manana, 0)) AS pendiente
      FROM ItemsPreparacion ip
      JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
      JOIN VariantesProducto vp ON vp.id = ip.variante_id
      JOIN Productos pr ON pr.id = vp.producto_id
      WHERE COALESCE(ip.resuelto, 0) = 0
        AND date(p.fecha) < date('now', 'localtime')
        AND ip.cantidad_preparada > COALESCE(ip.enviado_merma, 0) + COALESCE(ip.llevado_manana, 0)
      ORDER BY p.fecha ASC, pr.nombre, vp.nombre_variante
    ''');
    final stockByRoot = <int, int>{};
    final result = <Map<String, dynamic>>[];
    for (final source in rows) {
      final row = Map<String, dynamic>.from(source);
      final rootId = await StockMovementWriter.resolveRootVariantId(
        db,
        row['variante_id'] as int,
      );
      final budget = stockByRoot.putIfAbsent(
        rootId,
        () => (row['stock'] as num?)?.toInt() ?? 0,
      );
      final pending = (row['pendiente'] as num).toInt();
      final available = pending < budget ? pending : budget;
      if (available > 0) {
        row['pendiente'] = available;
        result.add(row);
        stockByRoot[rootId] = budget - available;
      }
    }
    return result;
  }

  Future<void> procesarSobrantesPendientes({
    required Map<int, int> sobrantesAPreparacion,
    required Map<int, int> sobrantesAMerma,
    required List<int> itemIdsResueltos,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await _ensureOpenCash(txn);

      final stagedIds = <int>{
        ...sobrantesAPreparacion.keys,
        ...sobrantesAMerma.keys,
      };

      for (final itemId in stagedIds) {
        final carry = sobrantesAPreparacion[itemId] ?? 0;
        final waste = sobrantesAMerma[itemId] ?? 0;
        if (carry < 0 || waste < 0) {
          throw Exception('La cantidad seleccionada no es válida.');
        }
        if (carry == 0 && waste == 0) continue;

        final sourceRows = await txn.rawQuery(
          '''
          SELECT ip.*, vp.stock, p.fecha, vp.nombre_variante, pr.nombre AS producto_nombre
          FROM ItemsPreparacion ip
          JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
          JOIN VariantesProducto vp ON vp.id = ip.variante_id
          JOIN Productos pr ON pr.id = vp.producto_id
          WHERE ip.id = ?
          LIMIT 1
          ''',
          [itemId],
        );
        if (sourceRows.isEmpty) {
          throw Exception('El sobrante seleccionado ya no está disponible.');
        }

        final source = sourceRows.first;
        final variantId = source['variante_id'] as int;
        final prepared = (source['cantidad_preparada'] as num).toInt();
        final alreadyWasted = (source['enviado_merma'] as num?)?.toInt() ?? 0;
        final alreadyCarried = (source['llevado_manana'] as num?)?.toInt() ?? 0;
        final remaining = prepared - alreadyWasted - alreadyCarried;
        if (carry + waste > remaining) {
          throw Exception(
            'La cantidad seleccionada (${carry + waste}) supera el sobrante disponible ($remaining).',
          );
        }
        final currentStock = await _getRootVariantStock(txn, variantId);
        if (carry + waste > currentStock) {
          throw Exception(
            'La cantidad seleccionada (${carry + waste}) supera el stock físico actual ($currentStock).',
          );
        }

        final prodName = source['producto_nombre'] ?? '';
        final varName = source['nombre_variante'] ?? '';
        final fullName = '$prodName · $varName'.trim();

        if (waste > 0) {
          await StockMovementWriter.changePreparedStock(
            executor: txn,
            variantId: variantId,
            quantity: -waste,
            movementType: 'merma',
            reason:
                'Merma sobrante del día anterior: $fullName (Ítem #$itemId)',
            referenceId: itemId,
          );

          await txn.insert(
            'Merma',
            Merma(
              fecha: DateTime.now().toIso8601String(),
              tipo: 'otro',
              descripcion: 'Sobrante del día anterior: $fullName',
              varianteId: variantId,
              cantidad: waste.toDouble(),
            ).toMap(),
          );

          await AuditLogWriter.record(
            txn,
            action: 'merma_sobrante_dia_anterior',
            detail: 'Ítem #$itemId ($fullName); $waste unid. a merma',
          );
        }

        if (carry > 0) {
          await AuditLogWriter.record(
            txn,
            action: 'traslado_sobrante_preparacion',
            detail:
                'Ítem #$itemId ($fullName); $carry unid. trasladadas a preparación de hoy',
          );
        }

        final newWasted = alreadyWasted + waste;
        final newCarried = alreadyCarried + carry;
        await txn.update(
          'ItemsPreparacion',
          {
            'enviado_merma': newWasted,
            'llevado_manana': newCarried,
            'sobrante': newWasted + newCarried,
            'resuelto': 1,
          },
          where: 'id = ?',
          whereArgs: [itemId],
        );
      }

      for (final id in itemIdsResueltos) {
        await txn.update(
          'ItemsPreparacion',
          {'resuelto': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      await txn.rawUpdate('''
        UPDATE ItemsPreparacion
        SET resuelto = 1
        WHERE COALESCE(resuelto, 0) = 0
          AND id IN (
            SELECT ip.id
            FROM ItemsPreparacion ip
            JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
            WHERE date(p.fecha) < date('now', 'localtime')
              AND ip.cantidad_preparada <= COALESCE(ip.enviado_merma, 0) + COALESCE(ip.llevado_manana, 0)
          )
      ''');
    });
  }

  /// Obtiene todos los productos preparados (variantes base activas) con stock > 0.
  /// Si [soloNoResueltos] es true (ej. al entrar al módulo de Preparación en un
  /// nuevo ciclo o día siguiente), retorna aquellos cuyo stock proviene de un
  /// día anterior o de un ciclo de caja cerrado sin haber sido resuelto aún.
  Future<List<Map<String, dynamic>>> getProductosConStockParaSobrantes({
    bool soloNoResueltos = false,
  }) async {
    final db = await dbHelper.database;
    final stockRows = await db.rawQuery('''
      SELECT vp.id AS variante_id,
             vp.nombre_variante,
             COALESCE(vp.stock, 0) AS stock,
             pr.nombre AS producto_nombre,
             pr.tipo_preparacion
      FROM VariantesProducto vp
      JOIN Productos pr ON pr.id = vp.producto_id
      WHERE COALESCE(vp.stock, 0) > 0
        AND pr.activo = 1
        AND vp.active = 1
        AND vp.variante_base_id IS NULL
      ORDER BY pr.nombre ASC, vp.nombre_variante ASC
    ''');

    if (stockRows.isEmpty) return [];

    if (!soloNoResueltos) {
      return stockRows
          .map(
            (row) => {
              'variante_id': row['variante_id'],
              'nombre_variante': row['nombre_variante'],
              'producto_nombre': row['producto_nombre'],
              'stock': (row['stock'] as num).toInt(),
              'pendiente': (row['stock'] as num).toInt(),
            },
          )
          .toList();
    }

    final today = DateTime.now().toIso8601String().split('T').first;
    final lastClosedRows = await db.query(
      'SesionesCaja',
      columns: ['id', 'fecha_cierre'],
      where: "estado = 'cerrada' AND fecha_cierre IS NOT NULL",
      orderBy: 'id DESC',
      limit: 1,
    );
    final lastCloseTime = lastClosedRows.isNotEmpty
        ? lastClosedRows.first['fecha_cierre'] as String?
        : null;

    final result = <Map<String, dynamic>>[];

    for (final row in stockRows) {
      final variantId = row['variante_id'] as int;
      final currentStock = (row['stock'] as num).toInt();

      // Si la variante ya tiene preparación guardada y resuelta para hoy, no está pendiente.
      final resolvedToday = await db.rawQuery(
        '''
        SELECT ip.id
        FROM ItemsPreparacion ip
        JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
        WHERE ip.variante_id = ? AND p.fecha = ? AND COALESCE(ip.resuelto, 0) = 1
        LIMIT 1
        ''',
        [variantId, today],
      );
      if (resolvedToday.isNotEmpty) {
        continue;
      }

      // Verificar si existen ítems no resueltos (resuelto = 0) creados en el cierre
      // de caja anterior o en días previos que aún no han sido decididos.
      final unresolvedItems = await db.rawQuery(
        '''
        SELECT ip.id, ip.cantidad_preparada,
               COALESCE(ip.enviado_merma, 0) AS enviado_merma,
               COALESCE(ip.llevado_manana, 0) AS llevado_manana,
               p.fecha, p.created_at
        FROM ItemsPreparacion ip
        JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
        WHERE ip.variante_id = ?
          AND COALESCE(ip.resuelto, 0) = 0
          AND ip.cantidad_preparada > COALESCE(ip.enviado_merma, 0) + COALESCE(ip.llevado_manana, 0)
        ORDER BY p.fecha ASC, ip.id ASC
        ''',
        [variantId],
      );

      var pendingFromPrevCycle = 0;
      for (final item in unresolvedItems) {
        final itemDate = item['fecha'] as String? ?? today;
        final createdAt = item['created_at'] as String? ?? '';
        final isPreviousDay = itemDate.compareTo(today) < 0;
        final isBeforeLastClose =
            lastCloseTime != null &&
            createdAt.isNotEmpty &&
            createdAt.compareTo(lastCloseTime) <= 0;
        if (isPreviousDay || isBeforeLastClose) {
          final rem =
              (item['cantidad_preparada'] as num).toInt() -
              (item['enviado_merma'] as num).toInt() -
              (item['llevado_manana'] as num).toInt();
          if (rem > 0) pendingFromPrevCycle += rem;
        }
      }

      if (pendingFromPrevCycle > 0) {
        final effectivePending = pendingFromPrevCycle < currentStock
            ? pendingFromPrevCycle
            : currentStock;
        if (effectivePending > 0) {
          result.add({
            'variante_id': variantId,
            'nombre_variante': row['nombre_variante'],
            'producto_nombre': row['producto_nombre'],
            'stock': currentStock,
            'pendiente': effectivePending,
          });
        }
      }
    }

    return result;
  }

  /// Procesa de forma atómica la distribución del stock preparado disponible
  /// entre "Para mañana / conservar" y "Merma" por variante.
  /// Garantiza que para cada variante: `paraManana + merma <= stockActual`.
  Future<void> procesarGestionSobrantesStock({
    required Map<int, Map<String, int>> decisiones,
    required bool esCierreDeCiclo,
    String tipoMerma = 'otro',
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T').first;
      final tomorrow = DateTime(
        now.year,
        now.month,
        now.day + 1,
      ).toIso8601String().split('T').first;

      for (final entry in decisiones.entries) {
        final rootId = await StockMovementWriter.resolveRootVariantId(
          txn,
          entry.key,
        );
        final paraManana =
            entry.value['paraManana'] ?? entry.value['manana'] ?? 0;
        final merma = entry.value['merma'] ?? 0;

        if (paraManana < 0 || merma < 0) {
          throw Exception('Las cantidades no pueden ser negativas.');
        }
        if (paraManana == 0 && merma == 0) continue;

        final varRows = await txn.rawQuery(
          '''
          SELECT vp.stock, vp.nombre_variante, pr.nombre AS producto_nombre
          FROM VariantesProducto vp
          JOIN Productos pr ON pr.id = vp.producto_id
          WHERE vp.id = ?
          LIMIT 1
          ''',
          [rootId],
        );
        if (varRows.isEmpty) {
          throw Exception('El producto seleccionado ya no existe.');
        }

        final currentStock = (varRows.first['stock'] as num?)?.toInt() ?? 0;
        final prodName = varRows.first['producto_nombre'] as String? ?? '';
        final varName = varRows.first['nombre_variante'] as String? ?? '';
        final fullName = '$prodName · $varName'.trim();

        if (paraManana + merma > currentStock) {
          throw Exception(
            'La suma de Para mañana ($paraManana) y Merma ($merma) supera o desborda el stock disponible ($currentStock) de $fullName.',
          );
        }

        // 1. Si hay merma, descontar del stock físico preparado y registrar en Merma
        if (merma > 0) {
          await StockMovementWriter.changePreparedStock(
            executor: txn,
            variantId: rootId,
            quantity: -merma,
            movementType: 'merma',
            reason: 'Gestión de sobrantes y mermas: $fullName',
          );

          await txn.insert(
            'Merma',
            Merma(
              fecha: now.toIso8601String(),
              tipo: tipoMerma,
              descripcion: 'Gestión de sobrantes: $fullName',
              varianteId: rootId,
              cantidad: merma.toDouble(),
            ).toMap(),
          );

          await AuditLogWriter.record(
            txn,
            action: 'merma_gestion_sobrantes',
            detail: '$fullName; $merma unid. enviadas a merma',
          );
        }

        // 2. Actualizar filas abiertas en ItemsPreparacion de esta variante
        final openItems = await txn.rawQuery(
          '''
          SELECT ip.id, ip.cantidad_preparada,
                 COALESCE(ip.enviado_merma, 0) AS enviado_merma,
                 COALESCE(ip.llevado_manana, 0) AS llevado_manana,
                 p.fecha
          FROM ItemsPreparacion ip
          JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
          WHERE ip.variante_id = ?
            AND COALESCE(ip.resuelto, 0) = 0
          ORDER BY p.fecha ASC, ip.id ASC
          ''',
          [rootId],
        );

        final quedaTotalmenteResuelto = (paraManana + merma) >= currentStock;
        var remMerma = merma;
        var remCarry = paraManana;

        if (openItems.isEmpty && esCierreDeCiclo) {
          final todayPrepRows = await txn.query(
            'PreparacionDiaria',
            where: 'fecha = ?',
            whereArgs: [today],
            limit: 1,
          );
          final todayPrepId = todayPrepRows.isEmpty
              ? await txn.insert('PreparacionDiaria', {
                  'fecha': today,
                  'nota': 'Cierre de ciclo ($fullName)',
                  'created_at': now.toIso8601String(),
                })
              : todayPrepRows.first['id'] as int;
          await txn.insert('ItemsPreparacion', {
            'preparacion_id': todayPrepId,
            'variante_id': rootId,
            'cantidad_preparada': currentStock,
            'enviado_merma': merma,
            'llevado_manana': paraManana,
            'sobrante': merma + paraManana,
            'resuelto': quedaTotalmenteResuelto ? 1 : 0,
            'notas': 'Gestionado al cierre de caja',
          });
        } else {
          for (final item in openItems) {
            final itemId = item['id'] as int;
            final prepQty = (item['cantidad_preparada'] as num).toInt();
            final prevWasted = (item['enviado_merma'] as num).toInt();
            final prevCarried = (item['llevado_manana'] as num).toInt();
            final itemAvail = (prepQty - prevWasted - prevCarried).clamp(
              0,
              999999,
            );

            final addMerma = remMerma <= itemAvail ? remMerma : itemAvail;
            remMerma -= addMerma;
            final leftAfterMerma = itemAvail - addMerma;
            final addCarry = remCarry <= leftAfterMerma
                ? remCarry
                : leftAfterMerma;
            remCarry -= addCarry;

            final newWasted = prevWasted + addMerma;
            final newCarried = prevCarried + addCarry;
            final newSobrante = newWasted + newCarried;
            final itemResolved =
                quedaTotalmenteResuelto || (newSobrante >= prepQty) ? 1 : 0;

            await txn.update(
              'ItemsPreparacion',
              {
                'enviado_merma': newWasted,
                'llevado_manana': newCarried,
                'sobrante': newSobrante,
                'resuelto': itemResolved,
              },
              where: 'id = ?',
              whereArgs: [itemId],
            );
          }
        }

        // 3. Registrar las unidades conservadas ("Para mañana" / ciclo actual)
        if (paraManana > 0) {
          final targetDate = esCierreDeCiclo ? tomorrow : today;
          final prepRows = await txn.query(
            'PreparacionDiaria',
            where: 'fecha = ?',
            whereArgs: [targetDate],
            limit: 1,
          );
          final targetPrepId = prepRows.isEmpty
              ? await txn.insert('PreparacionDiaria', {
                  'fecha': targetDate,
                  'nota': 'Continuidad de sobrantes ($fullName)',
                  'created_at': now.toIso8601String(),
                })
              : prepRows.first['id'] as int;

          if (prepRows.isNotEmpty && !esCierreDeCiclo) {
            await txn.update(
              'PreparacionDiaria',
              {'created_at': now.toIso8601String()},
              where: 'id = ?',
              whereArgs: [targetPrepId],
            );
          }

          final targetItems = await txn.query(
            'ItemsPreparacion',
            where: 'preparacion_id = ? AND variante_id = ?',
            whereArgs: [targetPrepId, rootId],
            limit: 1,
          );
          if (targetItems.isEmpty) {
            await txn.insert('ItemsPreparacion', {
              'preparacion_id': targetPrepId,
              'variante_id': rootId,
              'cantidad_preparada': paraManana,
              'notas': 'Sobrante conservado ($paraManana ud.)',
              'resuelto': 1,
            });
          } else if (esCierreDeCiclo) {
            final currentQty =
                (targetItems.first['cantidad_preparada'] as num?)?.toInt() ?? 0;
            await txn.update(
              'ItemsPreparacion',
              {
                'cantidad_preparada': currentQty + paraManana,
                'notas':
                    targetItems.first['notas'] ??
                    'Sobrante conservado ($paraManana ud.)',
              },
              where: 'id = ?',
              whereArgs: [targetItems.first['id']],
            );
          } else {
            await txn.update(
              'ItemsPreparacion',
              {
                'cantidad_preparada': paraManana,
                'enviado_merma': 0,
                'llevado_manana': 0,
                'sobrante': 0,
                'resuelto': 1,
                'notas': 'Sobrante conservado ($paraManana ud.)',
              },
              where: 'id = ?',
              whereArgs: [targetItems.first['id']],
            );
          }

          await AuditLogWriter.record(
            txn,
            action: 'sobrante_para_manana',
            detail:
                '$fullName; $paraManana unid. conservadas para $targetDate',
          );
        }
      }
    });
  }

  Future<int> crearTransformacion(Map<String, dynamic> data) async {
    final db = await dbHelper.database;
    return db.transaction((txn) async {
      final ingredients =
          (data.remove('insumos_adicionales') as List<dynamic>? ?? const [])
              .cast<TransformacionInsumo>();
      final id = await txn.insert('Transformaciones', data);
      for (final item in ingredients) {
        await txn.insert('TransformacionInsumos', {
          'transformacion_id': id,
          ...item.toMap(),
        });
      }
      return id;
    });
  }

  Future<List<Map<String, dynamic>>> getTransformaciones() async {
    final db = await dbHelper.database;
    final rules = await db.query('Transformaciones', where: 'activa = 1');
    final result = <Map<String, dynamic>>[];
    for (final rule in rules) {
      final ingredients = await db.rawQuery(
        '''
        SELECT ti.id, ti.insumo_id, ti.cantidad, ti.unidad_medida, i.nombre
        FROM TransformacionInsumos ti JOIN Insumos i ON i.id = ti.insumo_id
        WHERE ti.transformacion_id = ?
      ''',
        [rule['id']],
      );
      if (ingredients.isEmpty && rule['insumo_adicional_id'] != null) {
        ingredients.add({
          'insumo_id': rule['insumo_adicional_id'],
          'cantidad': rule['cantidad_insumo'] ?? 0,
          'unidad_medida': rule['unidad_insumo'] ?? 'unidades',
        });
      }
      result.add({...rule, 'insumos_adicionales': ingredients});
    }
    return result;
  }

  Future<void> registrarEntradaProductoPreparado({
    required int varianteId,
    required int cantidad,
    required String motivo,
  }) async {
    if (cantidad <= 0) {
      throw Exception('La cantidad de entrada debe ser mayor a cero.');
    }
    if (motivo.trim().isEmpty) {
      throw Exception('Indica el motivo de la entrada.');
    }
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await _ensureOpenCash(txn);

      final prodRows = await txn.rawQuery(
        '''
        SELECT p.tipo_preparacion
        FROM VariantesProducto vp
        JOIN Productos p ON p.id = vp.producto_id
        WHERE vp.id = ?
        LIMIT 1
        ''',
        [varianteId],
      );
      if (prodRows.isNotEmpty) {
        final tipoPrep =
            (prodRows.first['tipo_preparacion'] as String? ?? 'momento')
                .toLowerCase();
        if (tipoPrep == 'momento') {
          throw Exception(
            'Este producto es preparado al momento y no utiliza stock preparado.',
          );
        }
      }

      final recipeRequirements = await txn.rawQuery(
        '''
        SELECT r.insumo_id, r.cantidad, r.unidad_medida AS unidad_receta,
               i.unidad_medida AS unidad_stock, i.contenido_paquete,
               i.stock_actual
        FROM Recetas r
        JOIN Insumos i ON i.id = r.insumo_id
        WHERE r.variante_id = ?
        ''',
        [varianteId],
      );
      if (recipeRequirements.isNotEmpty) {
        final maxPortions = RecipeYieldCalculator.maxPortions(
          recipeRequirements,
        );
        if (cantidad > maxPortions) {
          throw Exception(
            'La receta solo permite preparar $maxPortions unidad(es) con el stock actual.',
          );
        }
        for (final ri in recipeRequirements) {
          final insumoId = ri['insumo_id'] as int;
          final cantReceta = (ri['cantidad'] as num).toDouble();
          final unidadReceta = ri['unidad_receta'] as String? ?? 'unidad';
          final unidadInsumo = ri['unidad_stock'] as String? ?? 'unidad';
          final contenidoPaquete =
              (ri['contenido_paquete'] as num?)?.toInt() ?? 1;
          final cantADescontarBase = UnitConverter.convert(
            cantReceta,
            unidadReceta,
            unidadInsumo,
            packageContent: contenidoPaquete,
          );
          if (cantADescontarBase > 0) {
            await StockMovementWriter.recordIngredient(
              executor: txn,
              ingredientId: insumoId,
              quantity: -(cantADescontarBase * cantidad),
              movementType: 'consumo',
              reason:
                  'Entrada preparada (${motivo.trim()}), variante $varianteId',
            );
          }
        }
      }

      await StockMovementWriter.changePreparedStock(
        executor: txn,
        variantId: varianteId,
        quantity: cantidad,
        movementType: 'entrada_adicional',
        reason: motivo.trim(),
      );
      await AuditLogWriter.record(
        txn,
        action: 'entrada_producto_preparado',
        detail:
            'Variante $varianteId; cantidad +$cantidad; motivo ${motivo.trim()}',
      );
    });
  }

  Future<void> aplicarTransformacion({
    required int reglaId,
    required int cantidadOrigen,
  }) async {
    if (cantidadOrigen <= 0) {
      throw Exception('La cantidad a transformar debe ser mayor a cero.');
    }
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await _ensureOpenCash(txn);
      final rows = await txn.query(
        'Transformaciones',
        where: 'id = ? AND activa = 1',
        whereArgs: [reglaId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw Exception('La regla de transformación no está disponible.');
      }
      final rule = rows.first;
      final sourceId = rule['variante_origen_id'] as int?;
      final targetId = rule['variante_destino_id'] as int?;
      final yieldFactor = (rule['rendimiento'] as num?)?.toDouble() ?? 1;
      if (sourceId == null ||
          targetId == null ||
          sourceId == targetId ||
          yieldFactor <= 0) {
        throw Exception('La regla de transformación no es válida.');
      }
      final sourcePool = await StockMovementWriter.resolveRootVariantId(
        txn,
        sourceId,
      );
      final targetPool = await StockMovementWriter.resolveRootVariantId(
        txn,
        targetId,
      );
      if (sourcePool == targetPool) {
        throw Exception(
          'Esta regla intenta transformar variantes que comparten el mismo stock. Usa la venta de la variante derivada, que consumirá sus ingredientes adicionales.',
        );
      }
      final output = cantidadOrigen * yieldFactor;
      if (output % 1 != 0) {
        throw Exception(
          'El rendimiento debe producir una cantidad entera de unidades.',
        );
      }
      await StockMovementWriter.changePreparedStock(
        executor: txn,
        variantId: sourceId,
        quantity: -cantidadOrigen,
        movementType: 'transformacion_salida',
        reason: 'Regla #$reglaId',
        referenceId: reglaId,
      );
      await StockMovementWriter.changePreparedStock(
        executor: txn,
        variantId: targetId,
        quantity: output.toInt(),
        movementType: 'transformacion_entrada',
        reason: 'Regla #$reglaId',
        referenceId: reglaId,
      );
      var ingredientRows = await txn.query(
        'TransformacionInsumos',
        where: 'transformacion_id = ?',
        whereArgs: [reglaId],
      );
      if (ingredientRows.isEmpty && rule['insumo_adicional_id'] != null) {
        ingredientRows = [
          {
            'insumo_id': rule['insumo_adicional_id'],
            'cantidad': rule['cantidad_insumo'],
            'unidad_medida': rule['unidad_insumo'] ?? 'unidades',
          },
        ];
      }
      for (final ingredient in ingredientRows) {
        final ingredientId = ingredient['insumo_id'] as int;
        final ingredientRowsDb = await txn.query(
          'Insumos',
          where: 'id = ?',
          whereArgs: [ingredientId],
          limit: 1,
        );
        if (ingredientRowsDb.isEmpty) {
          throw Exception('Un insumo adicional de la regla ya no existe.');
        }
        final ingredientData = ingredientRowsDb.first;
        final stockQuantity = UnitConverter.convert(
          ((ingredient['cantidad'] as num?)?.toDouble() ?? 0) * output,
          ingredient['unidad_medida'] as String,
          ingredientData['unidad_medida'] as String,
          packageContent:
              (ingredientData['contenido_paquete'] as num?)?.toInt() ?? 1,
        );
        await StockMovementWriter.recordIngredient(
          executor: txn,
          ingredientId: ingredientId,
          quantity: -stockQuantity,
          movementType: 'consumo',
          reason: 'Insumo de transformación #$reglaId',
        );
      }
      await AuditLogWriter.record(
        txn,
        action: 'producto_transformado',
        detail:
            'Regla #$reglaId; variante $sourceId -$cantidadOrigen; variante $targetId +${output.toInt()}; ingrediente(s) adicional(es) descontado(s).',
      );
    });
  }
}
