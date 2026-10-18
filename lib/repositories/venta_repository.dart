import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:intl/intl.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';
import 'package:pizzaapp/features/inventory/domain/services/unit_converter.dart';
import 'package:pizzaapp/core/database/audit_log_writer.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class VentaRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> registrarVentaCompleta(
    Venta venta,
    List<DetalleVenta> detalles, {
    bool historica = false,
  }) async {
    final db = await dbHelper.database;
    int ventaId = 0;

    try {
      await db.transaction((txn) async {
        Map<String, Object?>? sesion;
        if (!historica) {
          final sesiones = await txn.query(
            'SesionesCaja',
            where: "estado = 'abierta'",
            orderBy: 'id DESC',
            limit: 1,
          );
          if (sesiones.isNotEmpty) {
            sesion = sesiones.first;
          } else if (venta.total > 0) {
            throw Exception('Abre una caja antes de registrar ventas.');
          }
        }
        // 1. Insertar Cabecera de Venta
        final ventaData = Map<String, dynamic>.from(venta.toMap());
        final metodoLower = (ventaData['metodo_pago'] as String? ?? 'efectivo').toLowerCase().trim();
        if (metodoLower == 'mixto') {
          throw Exception('El método de pago mixto se encuentra temporalmente deshabilitado.');
        }
        if (!const ['efectivo', 'yape', 'plin', 'tarjeta', 'transferencia', 'yape/plin'].contains(metodoLower)) {
          ventaData['metodo_pago'] = 'efectivo';
        }
        ventaId = await txn.insert('Ventas', ventaData);

        if (!historica && sesion != null) {
          final esCortesiaPura = venta.total <= 0;
          await txn.insert('MovimientosCaja', {
            'sesion_caja_id': sesion['id'],
            'venta_id': ventaId,
            'tipo': esCortesiaPura ? 'cortesia' : 'venta',
            'metodo_pago': esCortesiaPura ? 'efectivo' : ventaData['metodo_pago'],
            'monto': venta.total,
            'descripcion':
                esCortesiaPura ? 'Cortesía #$ventaId' : 'Venta #$ventaId',
            'fecha': DateTime.now().toIso8601String(),
          });
        }

        // 2. Insertar los Detalles y descontar Stock
        for (var det in detalles) {
          // Enlazar al ID de venta recién creado
          final nuevoDetalle = DetalleVenta(
            ventaId: ventaId,
            varianteId: det.varianteId,
            promocionId: det.promocionId,
            esCortesia: det.esCortesia,
            cantidad: det.cantidad,
            precioUnitario: det.precioUnitario,
            descuento: det.descuento,
          );

          await txn.insert('DetalleVenta', nuevoDetalle.toMap());

          // Una venta registrada a posteriori completa el histórico para
          // reportes/sugerencias y no debe descontar el inventario actual.
          if (historica) continue;

          if (det.varianteId != null) {
            await _descontarInventarioProducto(
              txn,
              varianteId: det.varianteId!,
              cantidad: det.cantidad,
              ventaId: ventaId,
              esCortesia: det.esCortesia,
            );
          } else if (det.promocionId != null) {
            // Descontar todas las variantes dentro de esta promoción
            final promoVariantes = await txn.query(
              'PromocionItems',
              where: 'promocion_id = ?',
              whereArgs: [det.promocionId],
            );
            for (var pv in promoVariantes) {
              final cantIncluida = (pv['cantidad'] as num).toInt();
              final totalADescontar = cantIncluida * det.cantidad;
              final varId = pv['variante_id'] as int?;
              final insumoId = pv['insumo_id'] as int?;
              if (varId != null) {
                await _descontarInventarioProducto(
                  txn,
                  varianteId: varId,
                  cantidad: totalADescontar,
                  ventaId: ventaId,
                  esCortesia: false,
                );
              } else if (insumoId != null) {
                await StockMovementWriter.recordIngredient(
                  executor: txn,
                  ingredientId: insumoId,
                  quantity: -totalADescontar.toDouble(),
                  movementType: 'consumo',
                  reason: 'Componente de promoción #${det.promocionId} en venta #$ventaId',
                );
              }
            }
          }
        }
      });
    } on StockPreparadoInsuficiente catch (e) {
      // H-03: la señal de demanda no satisfecha debe sobrevivir al rollback de
      // la transacción de venta; se registra fuera de ella y se relanza.
      await db.insert('FaltantesPreparacion', {
        'variante_id': e.varianteId,
        'fecha': venta.fecha,
        'cantidad': e.cantidadFaltante,
        'motivo': 'Demanda no satisfecha en venta (stock preparado insuficiente)',
        'created_at': DateTime.now().toIso8601String(),
      });
      rethrow;
    }

    return ventaId;
  }

  /// Aplica la regla de inventario correspondiente a una cortesía:
  /// `anticipado` sale de unidades preparadas; `momento` consume receta; y
  /// `ambos` usa primero lo preparado y produce según receta el faltante.
  Future<void> _descontarInventarioProducto(
    DatabaseExecutor txn, {
    required int varianteId,
    required int cantidad,
    required int ventaId,
    required bool esCortesia,
  }) async {
    final variants = await txn.rawQuery(
      '''
      SELECT p.tipo_preparacion, vp.stock, vp.variante_base_id,
             vp.nombre_variante, c.nombre AS categoria_nombre
      FROM VariantesProducto vp
      JOIN Productos p ON p.id = vp.producto_id
      LEFT JOIN Categorias c ON c.id = p.categoria_id
      WHERE vp.id = ?
      ''',
      [varianteId],
    );
    if (variants.isEmpty) {
      throw Exception('El producto ya no está disponible.');
    }

    final product = variants.first;
    final preparationType =
        (product['tipo_preparacion'] as String? ?? 'momento').toLowerCase();
    final currentStock = (product['stock'] as num?)?.toInt() ?? 0;
    final baseVariantId = product['variante_base_id'] as int?;
    final reason = esCortesia
        ? 'Cortesía en venta #$ventaId, variante $varianteId'
        : 'Venta #$ventaId, variante $varianteId';

    if (preparationType == 'anticipado') {
      await StockMovementWriter.changePreparedStock(
        executor: txn,
        variantId: varianteId,
        quantity: -cantidad,
        movementType: esCortesia ? 'cortesia' : 'venta',
        reason: reason,
        referenceId: ventaId,
      );
      if (baseVariantId != null) {
        await _consumirReceta(
          txn,
          varianteId: varianteId,
          cantidadProducto: cantidad,
          reason: '$reason (complemento de variante)',
        );
      }
      return;
    }

    if (preparationType == 'momento') {
      // 'momento' (Preparado al momento) NO requiere stock preparado:
      // descuenta directamente los insumos de su receta al vender.
      var consumedRecipe = await _consumirReceta(
        txn,
        varianteId: varianteId,
        cantidadProducto: cantidad,
        reason: reason,
      );
      if (baseVariantId != null) {
        final baseConsumed = await _consumirReceta(
          txn,
          varianteId: baseVariantId,
          cantidadProducto: cantidad,
          reason: '$reason (receta heredada)',
        );
        consumedRecipe = consumedRecipe || baseConsumed;
      }
      if (consumedRecipe) return;

      throw Exception(
        'El producto no tiene una receta configurada para descontar los insumos al momento.',
      );
    }

    if (preparationType == 'ambos') {
      // Las unidades preparadas se venden primero desde el stock preparado.
      // Solo el faltante consume la receta al momento.
      final preparedQuantity = currentStock.clamp(0, cantidad).toInt();
      if (preparedQuantity > 0) {
        await StockMovementWriter.changePreparedStock(
          executor: txn,
          variantId: varianteId,
          quantity: -preparedQuantity,
          movementType: esCortesia ? 'cortesia' : 'venta',
          reason: reason,
          referenceId: ventaId,
        );
        if (baseVariantId != null) {
          await _consumirReceta(
            txn,
            varianteId: varianteId,
            cantidadProducto: preparedQuantity,
            reason: '$reason (complemento de variante)',
          );
        }
      }
      final madeToOrderQuantity = cantidad - preparedQuantity;
      if (madeToOrderQuantity == 0) return;

      var consumedRecipe = await _consumirReceta(
        txn,
        varianteId: varianteId,
        cantidadProducto: madeToOrderQuantity,
        reason: reason,
      );
      if (baseVariantId != null) {
        final baseConsumed = await _consumirReceta(
          txn,
          varianteId: baseVariantId,
          cantidadProducto: madeToOrderQuantity,
          reason: '$reason (receta heredada)',
        );
        consumedRecipe = consumedRecipe || baseConsumed;
      }
      if (consumedRecipe) return;

      throw StockPreparadoInsuficiente(
        varianteId: varianteId,
        cantidadFaltante: madeToOrderQuantity,
        mensaje:
            'El stock preparado no alcanza y el producto no tiene receta para preparar las unidades faltantes.',
      );
    }

    throw Exception('El tipo de preparación del producto no es válido.');
  }

  Future<bool> _consumirReceta(
    DatabaseExecutor txn, {
    required int varianteId,
    required int cantidadProducto,
    required String reason,
  }) async {
    var recipeRows = await txn.rawQuery(
      '''
      SELECT r.insumo_id, r.cantidad, r.unidad_medida AS unidad_receta,
             i.unidad_medida AS unidad_stock, i.contenido_paquete
      FROM Recetas r
      JOIN Insumos i ON i.id = r.insumo_id
      WHERE r.variante_id = ?
      ''',
      [varianteId],
    );
    if (recipeRows.isEmpty) {
      final recovered = await _recoverOrphanedVariantRecipe(txn, varianteId);
      if (recovered) {
        recipeRows = await txn.rawQuery(
          '''
          SELECT r.insumo_id, r.cantidad, r.unidad_medida AS unidad_receta,
                 i.unidad_medida AS unidad_stock, i.contenido_paquete
          FROM Recetas r
          JOIN Insumos i ON i.id = r.insumo_id
          WHERE r.variante_id = ?
          ''',
          [varianteId],
        );
      }
    }
    if (recipeRows.isEmpty) return false;

    for (final row in recipeRows) {
      final quantityPerProduct = (row['cantidad'] as num).toDouble();
      if (quantityPerProduct <= 0) {
        throw Exception('La receta tiene una cantidad inválida.');
      }
      final quantityInStockUnit = UnitConverter.convert(
        quantityPerProduct,
        row['unidad_receta'] as String? ?? 'unidad',
        row['unidad_stock'] as String? ?? 'unidad',
        packageContent: (row['contenido_paquete'] as num?)?.toInt() ?? 1,
      );
      await StockMovementWriter.recordIngredient(
        executor: txn,
        ingredientId: row['insumo_id'] as int,
        quantity: -quantityInStockUnit * cantidadProducto,
        movementType: 'consumo',
        reason: reason,
      );
    }
    return true;
  }

  Future<bool> _recoverOrphanedVariantRecipe(
    DatabaseExecutor txn,
    int varianteId,
  ) async {
    final currentRows = await txn.rawQuery(
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

    final donorRows = await txn.rawQuery(
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
    final inserted = await txn.rawInsert(
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

  Future<Map<String, dynamic>> getResumenHoy() async {
    final db = await dbHelper.database;
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final res = await db.rawQuery(
      '''
      SELECT
        SUM(total) as ventas_totales,
        COUNT(*) as cantidad_ventas
      FROM Ventas 
      WHERE substr(fecha, 1, 10) = ? AND anulada = 0
    ''',
      [hoy],
    );

    final gastos = await db.rawQuery(
      '''
      SELECT SUM(monto) as gastos_totales, COUNT(*) as cantidad_gastos
      FROM Gastos 
      WHERE substr(fecha, 1, 10) = ?
    ''',
      [hoy],
    );

    final double ventas =
        (res.first['ventas_totales'] as num?)?.toDouble() ?? 0.0;
    final double g =
        (gastos.first['gastos_totales'] as num?)?.toDouble() ?? 0.0;

    return {
      'ventas': ventas,
      'gastos': g,
      'ganancia': ventas - g,
      'cantidad_ventas': (res.first['cantidad_ventas'] as num?)?.toInt() ?? 0,
      'cantidad_gastos':
          (gastos.first['cantidad_gastos'] as num?)?.toInt() ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getMovimientosFinancierosHoy() async {
    final db = await dbHelper.database;
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return db.rawQuery(
      '''
      SELECT id, total AS monto, metodo_pago,
             fecha || 'T' || hora AS fecha
      FROM Ventas
      WHERE substr(fecha, 1, 10) = ? AND anulada = 0
      ORDER BY fecha DESC, hora DESC, id DESC
      ''',
      [hoy],
    );
  }

  Future<List<Map<String, dynamic>>> getDetallesVentasHoy() async {
    final db = await dbHelper.database;
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return db.rawQuery(
      '''
      SELECT
        v.id AS venta_id,
        dv.variante_id,
        dv.promocion_id,
        dv.cantidad,
        dv.precio_unitario,
        dv.descuento,
        dv.es_cortesia,
        p.id AS producto_id,
        p.nombre AS producto_nombre,
        vp.nombre_variante,
        pr.nombre AS promocion_nombre
      FROM DetalleVenta dv
      JOIN Ventas v ON v.id = dv.venta_id
      LEFT JOIN VariantesProducto vp ON vp.id = dv.variante_id
      LEFT JOIN Productos p ON p.id = vp.producto_id
      LEFT JOIN Promociones pr ON pr.id = dv.promocion_id
      WHERE substr(v.fecha, 1, 10) = ? AND v.anulada = 0
      ORDER BY v.id DESC, dv.id ASC
      ''',
      [hoy],
    );
  }

  Future<List<Map<String, dynamic>>> getHistorialVentas({
    int limit = 50,
  }) async {
    final db = await dbHelper.database;
    return await db.rawQuery(
      '''
      SELECT v.*,
        (SELECT COUNT(*) FROM DetalleVenta dv WHERE dv.venta_id = v.id) as items_count
      FROM Ventas v
      ORDER BY v.fecha DESC, v.hora DESC, v.id DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<void> anularVenta({
    required int ventaId,
    required String motivo,
    int? usuarioId,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final ventas = await txn.query(
        'Ventas',
        where: 'id = ?',
        whereArgs: [ventaId],
        limit: 1,
      );
      if (ventas.isEmpty) {
        throw Exception('La venta #$ventaId no existe.');
      }
      final v = ventas.first;
      if ((v['anulada'] as int? ?? 0) == 1) {
        throw Exception('La venta #$ventaId ya se encuentra anulada.');
      }

      // 1. Validar que la sesión de caja no esté cerrada
      final movCaja = await txn.query(
        'MovimientosCaja',
        where: 'venta_id = ?',
        whereArgs: [ventaId],
      );
      if (movCaja.isNotEmpty) {
        final sesionId = movCaja.first['sesion_caja_id'] as int;
        final sesionRows = await txn.query(
          'SesionesCaja',
          where: 'id = ?',
          whereArgs: [sesionId],
          limit: 1,
        );
        if (sesionRows.isNotEmpty && sesionRows.first['estado'] == 'cerrada') {
          throw Exception(
            'No se puede anular una venta de una sesión de caja que ya fue cerrada.',
          );
        }
      }

      // 2. Revertir Stock Preparado
      final stockPrepMovs = await txn.query(
        'MovimientosStockPreparado',
        where: 'referencia_id = ? AND tipo IN (\'venta\', \'cortesia\')',
        whereArgs: [ventaId],
      );
      for (final m in stockPrepMovs) {
        final varId = m['variante_id'] as int;
        final cant = (m['cantidad'] as num).toInt();
        final revertQty = cant < 0 ? -cant : cant;
        if (revertQty > 0) {
          await StockMovementWriter.changePreparedStock(
            executor: txn,
            variantId: varId,
            quantity: revertQty,
            movementType: 'reversion_venta',
            reason: 'Reversión por anulación de venta #$ventaId ($motivo)',
            referenceId: ventaId,
            userId: usuarioId,
          );
        }
      }

      // 3. Revertir Insumos de Receta consumidos
      final insumosConsumidos = await txn.rawQuery(
        '''
        SELECT insumo_id, SUM(cantidad_ajuste) AS total_consumido
        FROM AjustesStock
        WHERE motivo LIKE ? AND tipo_adquisicion = 'consumo'
        GROUP BY insumo_id
        ''',
        ['%#$ventaId%'],
      );
      for (final row in insumosConsumidos) {
        final insumoId = row['insumo_id'] as int;
        final consumido = (row['total_consumido'] as num).toDouble();
        final revertCant = consumido < 0 ? -consumido : consumido;
        if (revertCant > 0) {
          await StockMovementWriter.recordIngredient(
            executor: txn,
            ingredientId: insumoId,
            quantity: revertCant,
            movementType: 'reversion_consumo',
            reason:
                'Reversión insumos por anulación de venta #$ventaId ($motivo)',
          );
        }
      }

      // Fallback defensivo: si no hubo movimientos registrados pero la venta tiene detalles y no es histórica
      final esHistorica =
          (v['nota'] as String? ?? '').contains('[REGISTRO HISTÓRICO]');
      if (!esHistorica &&
          stockPrepMovs.isEmpty &&
          insumosConsumidos.isEmpty) {
        final detalles = await txn.query(
          'DetalleVenta',
          where: 'venta_id = ?',
          whereArgs: [ventaId],
        );
        for (final det in detalles) {
          final varId = det['variante_id'] as int?;
          final cant = (det['cantidad'] as num).toInt();
          if (varId != null) {
            final varRows = await txn.rawQuery(
              '''
              SELECT p.tipo_preparacion, vp.variante_base_id
              FROM VariantesProducto vp
              JOIN Productos p ON p.id = vp.producto_id
              WHERE vp.id = ?
              ''',
              [varId],
            );
            if (varRows.isNotEmpty) {
              final prepType =
                  (varRows.first['tipo_preparacion'] as String? ?? 'momento')
                      .toLowerCase();
              if (prepType == 'anticipado') {
                await StockMovementWriter.changePreparedStock(
                  executor: txn,
                  variantId: varId,
                  quantity: cant,
                  movementType: 'reversion_venta',
                  reason: 'Reversión por anulación de venta #$ventaId ($motivo)',
                  referenceId: ventaId,
                  userId: usuarioId,
                );
              }
            }
          }
        }
      }

      // 4. Actualizar MovimientosCaja para excluir del arqueo
      await txn.update(
        'MovimientosCaja',
        {
          'tipo': 'venta_anulada',
          'descripcion': 'Venta #$ventaId [ANULADA: $motivo]',
        },
        where: 'venta_id = ?',
        whereArgs: [ventaId],
      );

      // 5. Marcar Venta como anulada y registrar motivo
      final notaActual = (v['nota'] as String? ?? '').trim();
      final notaAnulada = notaActual.isEmpty
          ? '[ANULADA: $motivo]'
          : '$notaActual [ANULADA: $motivo]';
      await txn.update(
        'Ventas',
        {
          'anulada': 1,
          'nota': notaAnulada,
        },
        where: 'id = ?',
        whereArgs: [ventaId],
      );

      // 6. Registro de auditoría
      await AuditLogWriter.record(
        txn,
        action: 'venta_anulada',
        userId: usuarioId,
        detail:
            'Venta #$ventaId anulada; monto S/. ${((v['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}; motivo: $motivo',
      );
    });
  }

  Future<void> actualizarMetodoPagoVenta({
    required int ventaId,
    required String nuevoMetodo,
    int? usuarioId,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final ventas = await txn.query(
        'Ventas',
        where: 'id = ?',
        whereArgs: [ventaId],
        limit: 1,
      );
      if (ventas.isEmpty) throw Exception('La venta #$ventaId no existe.');
      final v = ventas.first;
      if ((v['anulada'] as int? ?? 0) == 1) {
        throw Exception(
          'No se puede cambiar el método de pago de una venta anulada.',
        );
      }
      final antiguoMetodo = v['metodo_pago'] as String? ?? 'efectivo';
      var mPago = nuevoMetodo.toLowerCase().trim();
      if (mPago == 'yape/plin') mPago = 'yape';
      if (!const ['efectivo', 'yape', 'plin', 'tarjeta', 'transferencia']
          .contains(mPago)) {
        throw Exception('Método de pago no válido: $nuevoMetodo');
      }

      // Validar si la sesión de caja está cerrada
      final movCaja = await txn.query(
        'MovimientosCaja',
        where: 'venta_id = ?',
        whereArgs: [ventaId],
      );
      if (movCaja.isNotEmpty) {
        final sesionId = movCaja.first['sesion_caja_id'] as int;
        final sesionRows = await txn.query(
          'SesionesCaja',
          where: 'id = ?',
          whereArgs: [sesionId],
          limit: 1,
        );
        if (sesionRows.isNotEmpty && sesionRows.first['estado'] == 'cerrada') {
          throw Exception(
            'No se puede editar el método de pago de una sesión de caja ya cerrada.',
          );
        }
      }

      await txn.update(
        'Ventas',
        {'metodo_pago': mPago},
        where: 'id = ?',
        whereArgs: [ventaId],
      );

      await txn.update(
        'MovimientosCaja',
        {'metodo_pago': mPago},
        where: 'venta_id = ? AND tipo IN (\'venta\', \'cortesia\')',
        whereArgs: [ventaId],
      );

      await AuditLogWriter.record(
        txn,
        action: 'cambio_metodo_pago_venta',
        userId: usuarioId,
        detail:
            'Venta #$ventaId; método cambiado de $antiguoMetodo a $mPago',
      );
    });
  }

  Future<Map<String, dynamic>?> getVentaConDetalles(int ventaId) async {
    final db = await dbHelper.database;
    final ventas = await db.query(
      'Ventas',
      where: 'id = ?',
      whereArgs: [ventaId],
    );
    if (ventas.isEmpty) return null;
    final detalles = await db.rawQuery(
      '''
      SELECT dv.*, vp.nombre_variante, p.nombre as producto_nombre, pr.nombre as promo_nombre
      FROM DetalleVenta dv
      LEFT JOIN VariantesProducto vp ON dv.variante_id = vp.id
      LEFT JOIN Productos p ON vp.producto_id = p.id
      LEFT JOIN Promociones pr ON dv.promocion_id = pr.id
      WHERE dv.venta_id = ?
    ''',
      [ventaId],
    );
    return {'venta': ventas.first, 'detalles': detalles};
  }
}
