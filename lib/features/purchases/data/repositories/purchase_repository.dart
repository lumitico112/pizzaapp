import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';
import 'package:pizzaapp/core/database/audit_log_writer.dart';
import 'package:pizzaapp/features/purchases/domain/entities/compra_ocasional.dart';
import 'package:pizzaapp/features/purchases/domain/entities/payable_balance.dart';
import 'package:pizzaapp/features/purchases/domain/repositories/payable_repository.dart';
import 'package:pizzaapp/features/purchases/domain/rules/occasional_purchase_rules.dart';

/// Purchase and payable persistence. Stock entry is part of purchase creation.
class PurchaseRepository implements PayableRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<void> registrarCompra({
    required int insumoId,
    required double cantidad,
    required double costoTotal,
    required String? motivo,
    String? facturaRuta,
    int? proveedorId,
    String? fecha,
    int? usuarioId,
    String metodoPago = 'efectivo',
  }) async {
    if (!cantidad.isFinite ||
        !costoTotal.isFinite ||
        cantidad <= 0 ||
        costoTotal <= 0) {
      throw Exception('Cantidad y costo deben ser mayores a cero.');
    }
    _validatePaymentMethod(metodoPago);
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final when = fecha ?? DateTime.now().toIso8601String();
      final expenseDate = _dateOnly(when);
      final movementId = await StockMovementWriter.recordIngredient(
        executor: txn,
        ingredientId: insumoId,
        quantity: cantidad,
        movementType: 'comprado',
        reason: motivo ?? 'Compra',
        date: when,
        unitCost: costoTotal / cantidad,
        supplierId: proveedorId,
      );
      final sessions = expenseDate == _today()
          ? await txn.query(
              'SesionesCaja',
              where: "estado = 'abierta'",
              orderBy: 'id DESC',
              limit: 1,
            )
          : <Map<String, Object?>>[];
      await txn.insert('Gastos', {
        'fecha': expenseDate,
        'created_at': when.contains('T')
            ? when
            : DateTime.now().toIso8601String(),
        'categoria': 'Compras',
        'descripcion': 'Compra: ${motivo ?? ''}',
        'monto': costoTotal,
        'insumo_id': insumoId,
        'foto_recibo_ruta': facturaRuta,
        'usuario_id': usuarioId,
        'compra_movimiento_id': movementId,
        'sesion_caja_id': sessions.isEmpty ? null : sessions.first['id'],
      });
      if (sessions.isNotEmpty && costoTotal > 0) {
        await txn.insert('MovimientosCaja', {
          'sesion_caja_id': sessions.first['id'],
          'tipo': 'compra',
          'metodo_pago': metodoPago,
          'monto': costoTotal,
          'descripcion': motivo ?? 'Compra directa',
          'fecha': when,
          'compra_movimiento_id': movementId,
        });
      }
      await AuditLogWriter.record(
        txn,
        action: 'compra_directa',
        detail: 'Insumo $insumoId; cantidad $cantidad; total $costoTotal',
        userId: usuarioId,
      );
    });
  }

  Future<void> registrarCompraPorPagar({
    required int insumoId,
    required double cantidad,
    required double costoTotal,
    required double adelanto,
    String? proveedor,
    int? proveedorId,
    String? factura,
    String? facturaRuta,
    String? fecha,
    int? usuarioId,
    String metodoPago = 'efectivo',
    int cuotas = 1,
  }) async {
    if (!cantidad.isFinite ||
        !costoTotal.isFinite ||
        !adelanto.isFinite ||
        cantidad <= 0 ||
        costoTotal <= 0 ||
        adelanto < 0 ||
        adelanto > costoTotal ||
        cuotas < 1) {
      throw Exception('Cantidad, costo o adelanto no válidos.');
    }
    if (adelanto > 0) _validatePaymentMethod(metodoPago);
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final when = fecha ?? DateTime.now().toIso8601String();
      final expenseDate = _dateOnly(when);
      final movementId = await StockMovementWriter.recordIngredient(
        executor: txn,
        ingredientId: insumoId,
        quantity: cantidad,
        movementType: 'comprado',
        reason: factura ?? 'Compra a crédito',
        date: when,
        unitCost: costoTotal / cantidad,
        supplierId: proveedorId,
      );
      final payableId = await txn.insert('CuentasPorPagar', {
        'fecha': when,
        'insumo_id': insumoId,
        'cantidad': cantidad,
        'costo_total': costoTotal,
        'monto_pagado': adelanto,
        'adelanto': adelanto,
        'proveedor': proveedor,
        'proveedor_id': proveedorId,
        'motivo': factura,
        'factura_ruta': facturaRuta,
        'pagado': adelanto >= costoTotal ? 1 : 0,
        'fecha_pago': adelanto >= costoTotal ? when : null,
        'cuotas': cuotas,
        'usuario_id': usuarioId,
        'compra_movimiento_id': movementId,
      });
      if (adelanto > 0) {
        final paymentId = await txn.insert('PagosCuentaPorPagar', {
          'cuenta_id': payableId,
          'fecha': expenseDate,
          'monto': adelanto,
          'metodo_pago': metodoPago,
          'nota': 'Adelanto de compra',
          'usuario_id': usuarioId,
        });
        await _recordPaymentFinancials(
          txn,
          paymentId: paymentId,
          payableId: payableId,
          amount: adelanto,
          paymentMethod: metodoPago,
          reason: 'Adelanto de compra: ${factura ?? 'Cuenta'}',
          date: expenseDate,
          userId: usuarioId,
        );
      }
      await AuditLogWriter.record(
        txn,
        action: 'compra_a_credito',
        detail:
            'Insumo $insumoId; cantidad $cantidad; total $costoTotal; adelanto $adelanto',
        userId: usuarioId,
      );
    });
  }

  /// Registra una compra ocasional sin crear insumos ni mover stock.
  ///
  /// - Contado: cabecera + `Gastos` y, si hay caja abierta, `MovimientosCaja`
  ///   con tipo `salida`.
  /// - Crédito: cabecera + `CuentasPorPagar`; el adelanto genera un único pago,
  ///   gasto y movimiento.
  Future<int> registrarCompraOcasional(CompraOcasional compra) async {
    OccasionalPurchaseRules.validar(
      descripcion: compra.descripcion,
      cantidad: compra.cantidad,
      costoTotal: compra.costoTotal,
      categoria: compra.categoria,
      esPorPagar: compra.esPorPagar,
      adelanto: compra.adelanto,
      cuotas: compra.cuotas,
      metodoPago: compra.metodoPago,
    );

    final descripcion = compra.descripcion.trim();
    final categoria = compra.categoria.trim();
    final unidad = _nullableText(compra.unidadMedida);
    final proveedor = _nullableText(compra.proveedor);
    final when = compra.fecha.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : compra.fecha;
    final expenseDate = _dateOnly(when);
    final descripcionCompra = OccasionalPurchaseRules.descripcionEstructurada(
      categoria: categoria,
      descripcion: descripcion,
      cantidad: compra.cantidad,
      unidadMedida: unidad,
    );

    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final compraId = await txn.insert('ComprasOcasionales', {
        'fecha': when,
        'descripcion': descripcion,
        'cantidad': compra.cantidad,
        'unidad_medida': unidad,
        'costo_total': compra.costoTotal,
        'categoria': categoria,
        'proveedor': proveedor,
        'proveedor_id': compra.proveedorId,
        'factura_ruta': compra.facturaRuta,
        'es_por_pagar': compra.esPorPagar ? 1 : 0,
        'adelanto': compra.esPorPagar ? compra.adelanto : 0.0,
        'cuotas': compra.esPorPagar ? compra.cuotas : 1,
        'metodo_pago': compra.metodoPago,
        'usuario_id': compra.usuarioId,
      });

      if (!compra.esPorPagar) {
        final sessionId = await _openSessionIdFor(txn, when);
        final gastoId = await txn.insert('Gastos', {
          'fecha': expenseDate,
          'created_at': when.contains('T')
              ? when
              : DateTime.now().toIso8601String(),
          'categoria': categoria,
          'descripcion': descripcionCompra,
          'monto': compra.costoTotal,
          'foto_recibo_ruta': compra.facturaRuta,
          'usuario_id': compra.usuarioId,
          'sesion_caja_id': sessionId,
          'compra_ocasional_id': compraId,
        });
        if (sessionId != null) {
          final movimientoId = await txn.insert('MovimientosCaja', {
            'sesion_caja_id': sessionId,
            'tipo': 'salida',
            'metodo_pago': compra.metodoPago,
            'monto': compra.costoTotal,
            'descripcion': descripcionCompra,
            'fecha': when,
          });
          await txn.update(
            'Gastos',
            {'movimiento_caja_id': movimientoId},
            where: 'id = ?',
            whereArgs: [gastoId],
          );
        }
      } else {
        final cuentaId = await txn.insert('CuentasPorPagar', {
          'fecha': when,
          'cantidad': compra.cantidad,
          'costo_total': compra.costoTotal,
          'monto_pagado': compra.adelanto,
          'adelanto': compra.adelanto,
          'proveedor': proveedor,
          'proveedor_id': compra.proveedorId,
          'motivo': descripcionCompra,
          'factura_ruta': compra.facturaRuta,
          'pagado': compra.adelanto >= compra.costoTotal ? 1 : 0,
          'fecha_pago': compra.adelanto >= compra.costoTotal ? when : null,
          'cuotas': compra.cuotas,
          'usuario_id': compra.usuarioId,
          'compra_ocasional_id': compraId,
        });
        if (compra.adelanto > 0) {
          final pagoId = await txn.insert('PagosCuentaPorPagar', {
            'cuenta_id': cuentaId,
            'fecha': expenseDate,
            'monto': compra.adelanto,
            'metodo_pago': compra.metodoPago,
            'nota': 'Adelanto de compra',
            'usuario_id': compra.usuarioId,
          });
          await _recordPaymentFinancials(
            txn,
            paymentId: pagoId,
            payableId: cuentaId,
            amount: compra.adelanto,
            paymentMethod: compra.metodoPago,
            reason: descripcion,
            date: when,
            userId: compra.usuarioId,
            compraOcasionalId: compraId,
            categoria: categoria,
          );
        }
      }

      await AuditLogWriter.record(
        txn,
        action: 'compra_ocasional_registrada',
        detail:
            'Compra ocasional #$compraId; ${compra.esPorPagar ? 'crédito' : 'contado'}; '
            'categoría $categoria; total ${compra.costoTotal}; sin stock.',
        userId: compra.usuarioId,
      );
      return compraId;
    });
  }

  /// Corrige la cabecera ocasional y sus efectos financieros sin tocar stock.
  ///
  /// No permite convertir contado <-> crédito en esta entrega. En crédito
  /// recalcula `monto_pagado = adelanto + abonos posteriores` y rechaza un
  /// total menor al ya pagado.
  Future<void> corregirCompraOcasional(CompraOcasional compra) async {
    final compraId = compra.id;
    if (compraId == null) {
      throw Exception('La compra ocasional no tiene un identificador válido.');
    }
    OccasionalPurchaseRules.validar(
      descripcion: compra.descripcion,
      cantidad: compra.cantidad,
      costoTotal: compra.costoTotal,
      categoria: compra.categoria,
      esPorPagar: compra.esPorPagar,
      adelanto: compra.adelanto,
      cuotas: compra.cuotas,
      metodoPago: compra.metodoPago,
    );

    final descripcion = compra.descripcion.trim();
    final categoria = compra.categoria.trim();
    final unidad = _nullableText(compra.unidadMedida);
    final proveedor = _nullableText(compra.proveedor);
    final fechaSolicitada = compra.fecha.trim();
    final descripcionCompra = OccasionalPurchaseRules.descripcionEstructurada(
      categoria: categoria,
      descripcion: descripcion,
      cantidad: compra.cantidad,
      unidadMedida: unidad,
    );

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final headerRows = await txn.query(
        'ComprasOcasionales',
        where: 'id = ?',
        whereArgs: [compraId],
        limit: 1,
      );
      if (headerRows.isEmpty) {
        throw Exception('La compra ocasional ya no existe.');
      }
      final header = headerRows.first;
      final eraPorPagar =
          ((header['es_por_pagar'] as num?)?.toInt() ?? 0) == 1;
      if (eraPorPagar != compra.esPorPagar) {
        throw Exception(
          'No se puede convertir una compra ocasional de contado a crédito '
          'ni viceversa desde la edición.',
        );
      }

      final targetFecha = fechaSolicitada.isEmpty
          ? (header['fecha'] as String? ?? DateTime.now().toIso8601String())
          : fechaSolicitada;
      final expenseDate = _dateOnly(targetFecha);
      final sessionId = await _openSessionIdFor(txn, targetFecha);
      var adelantoEfectivo = 0.0;

      if (!compra.esPorPagar) {
        final gastos = await txn.query(
          'Gastos',
          where: 'compra_ocasional_id = ?',
          whereArgs: [compraId],
          orderBy: 'id ASC',
        );
        if (gastos.length > 1) {
          throw Exception(
            'La compra ocasional tiene gastos duplicados y requiere revisión.',
          );
        }
        final gasto = gastos.isEmpty ? null : gastos.first;
        final oldMovementId = gasto?['movimiento_caja_id'] as int?;
        final gastoData = <String, Object?>{
          'fecha': expenseDate,
          'categoria': categoria,
          'descripcion': descripcionCompra,
          'monto': compra.costoTotal,
          'foto_recibo_ruta': compra.facturaRuta,
          'insumo_id': null,
          'activo_id': null,
          'activo_fijo_id': null,
          'compra_movimiento_id': null,
          'sesion_caja_id': sessionId,
          'compra_ocasional_id': compraId,
        };

        int gastoId;
        if (gasto == null) {
          gastoData['created_at'] = targetFecha.contains('T')
              ? targetFecha
              : DateTime.now().toIso8601String();
          gastoData['usuario_id'] = compra.usuarioId;
          gastoId = await txn.insert('Gastos', gastoData);
        } else {
          gastoId = gasto['id'] as int;
          await txn.update(
            'Gastos',
            gastoData,
            where: 'id = ?',
            whereArgs: [gastoId],
          );
        }

        if (sessionId == null) {
          if (oldMovementId != null) {
            await txn.update(
              'Gastos',
              {'movimiento_caja_id': null},
              where: 'id = ?',
              whereArgs: [gastoId],
            );
            await txn.delete(
              'MovimientosCaja',
              where: 'id = ?',
              whereArgs: [oldMovementId],
            );
          }
        } else {
          final movementData = <String, Object?>{
            'sesion_caja_id': sessionId,
            'tipo': 'salida',
            'metodo_pago': compra.metodoPago,
            'monto': compra.costoTotal,
            'descripcion': descripcionCompra,
            'fecha': targetFecha,
          };
          if (oldMovementId != null) {
            await txn.update(
              'MovimientosCaja',
              movementData,
              where: 'id = ?',
              whereArgs: [oldMovementId],
            );
          } else {
            final movimientoId = await txn.insert(
              'MovimientosCaja',
              movementData,
            );
            await txn.update(
              'Gastos',
              {'movimiento_caja_id': movimientoId},
              where: 'id = ?',
              whereArgs: [gastoId],
            );
          }
        }
      } else {
        final cuentas = await txn.query(
          'CuentasPorPagar',
          where: 'compra_ocasional_id = ?',
          whereArgs: [compraId],
          orderBy: 'id ASC',
        );
        if (cuentas.isEmpty) {
          throw Exception(
            'La cuenta por pagar de la compra ocasional ya no existe.',
          );
        }
        if (cuentas.length > 1) {
          throw Exception(
            'La compra ocasional tiene cuentas por pagar duplicadas y '
            'requiere revisión.',
          );
        }
        final cuenta = cuentas.first;
        final cuentaId = cuenta['id'] as int;
        final pagos = await txn.query(
          'PagosCuentaPorPagar',
          where: 'cuenta_id = ?',
          whereArgs: [cuentaId],
          orderBy: 'id ASC',
        );
        Map<String, Object?>? pagoAdelanto;
        var abonosPosteriores = 0.0;
        for (final pago in pagos) {
          final nota = (pago['nota'] as String? ?? '').trim();
          if (pagoAdelanto == null && nota == 'Adelanto de compra') {
            pagoAdelanto = pago;
          } else {
            abonosPosteriores +=
                (pago['monto'] as num?)?.toDouble() ?? 0.0;
          }
        }

        adelantoEfectivo = compra.adelanto;
        final nuevoMontoPagado = adelantoEfectivo + abonosPosteriores;
        if (compra.costoTotal + 0.000001 < nuevoMontoPagado) {
          throw Exception(
            'El nuevo costo total (S/ ${compra.costoTotal.toStringAsFixed(2)}) '
            'no puede ser menor al monto ya abonado '
            '(S/ ${nuevoMontoPagado.toStringAsFixed(2)}).',
          );
        }

        final pagoAdelantoId = pagoAdelanto?['id'] as int?;
        final gastoAdelantoId = pagoAdelanto?['gasto_id'] as int?;
        final movimientoAdelantoId =
            pagoAdelanto?['movimiento_caja_id'] as int?;
        final descripcionAbono =
            'Abono compra ocasional - $categoria: $descripcion';

        if (adelantoEfectivo > 0) {
          if (pagoAdelanto != null) {
            final gastoData = <String, Object?>{
              'fecha': expenseDate,
              'categoria': categoria,
              'descripcion': descripcionAbono,
              'monto': adelantoEfectivo,
              'foto_recibo_ruta': compra.facturaRuta,
              'insumo_id': null,
              'activo_id': null,
              'activo_fijo_id': null,
              'compra_movimiento_id': null,
              'sesion_caja_id': sessionId,
              'compra_ocasional_id': compraId,
            };
            int gastoId;
            if (gastoAdelantoId != null) {
              gastoId = gastoAdelantoId;
              await txn.update(
                'Gastos',
                gastoData,
                where: 'id = ?',
                whereArgs: [gastoId],
              );
            } else {
              gastoData['created_at'] = targetFecha.contains('T')
                  ? targetFecha
                  : DateTime.now().toIso8601String();
              gastoData['usuario_id'] = compra.usuarioId;
              gastoId = await txn.insert('Gastos', gastoData);
            }

            int? movimientoId = movimientoAdelantoId;
            if (sessionId == null) {
              if (movimientoId != null) {
                // El pago es el padre de la FK: se desvincula antes de borrar
                // el movimiento para no violar la integridad referencial.
                await txn.update(
                  'PagosCuentaPorPagar',
                  {'movimiento_caja_id': null},
                  where: 'id = ?',
                  whereArgs: [pagoAdelantoId],
                );
                await txn.delete(
                  'MovimientosCaja',
                  where: 'id = ?',
                  whereArgs: [movimientoId],
                );
                movimientoId = null;
              }
            } else {
              final movementData = <String, Object?>{
                'sesion_caja_id': sessionId,
                'tipo': 'salida',
                'metodo_pago': compra.metodoPago,
                'monto': adelantoEfectivo,
                'descripcion': descripcionAbono,
                'fecha': targetFecha,
              };
              if (movimientoId != null) {
                await txn.update(
                  'MovimientosCaja',
                  movementData,
                  where: 'id = ?',
                  whereArgs: [movimientoId],
                );
              } else {
                movimientoId = await txn.insert(
                  'MovimientosCaja',
                  movementData,
                );
              }
            }

            await txn.update(
              'PagosCuentaPorPagar',
              {
                'monto': adelantoEfectivo,
                'metodo_pago': compra.metodoPago,
                'fecha': targetFecha,
                'gasto_id': gastoId,
                'movimiento_caja_id': movimientoId,
                'usuario_id': compra.usuarioId,
              },
              where: 'id = ?',
              whereArgs: [pagoAdelantoId],
            );
          } else {
            final pagoId = await txn.insert('PagosCuentaPorPagar', {
              'cuenta_id': cuentaId,
              'fecha': expenseDate,
              'monto': adelantoEfectivo,
              'metodo_pago': compra.metodoPago,
              'nota': 'Adelanto de compra',
              'usuario_id': compra.usuarioId,
            });
            await _recordPaymentFinancials(
              txn,
              paymentId: pagoId,
              payableId: cuentaId,
              amount: adelantoEfectivo,
              paymentMethod: compra.metodoPago,
              reason: descripcion,
              date: targetFecha,
              userId: compra.usuarioId,
              compraOcasionalId: compraId,
              categoria: categoria,
            );
          }
        } else if (pagoAdelanto != null) {
          await txn.delete(
            'PagosCuentaPorPagar',
            where: 'id = ?',
            whereArgs: [pagoAdelantoId],
          );
          if (gastoAdelantoId != null) {
            await txn.delete(
              'Gastos',
              where: 'id = ?',
              whereArgs: [gastoAdelantoId],
            );
          }
          if (movimientoAdelantoId != null) {
            await txn.delete(
              'MovimientosCaja',
              where: 'id = ?',
              whereArgs: [movimientoAdelantoId],
            );
          }
        }

        final estaPagado =
            nuevoMontoPagado >= compra.costoTotal - 0.000001;
        await txn.update(
          'CuentasPorPagar',
          {
            'fecha': targetFecha,
            'cantidad': compra.cantidad,
            'costo_total': compra.costoTotal,
            'monto_pagado': nuevoMontoPagado,
            'adelanto': adelantoEfectivo,
            'proveedor': proveedor,
            'proveedor_id': compra.proveedorId,
            'motivo': descripcionCompra,
            'factura_ruta': compra.facturaRuta,
            'pagado': estaPagado ? 1 : 0,
            'fecha_pago': estaPagado
                ? (cuenta['fecha_pago'] ?? targetFecha)
                : null,
            'cuotas': compra.cuotas,
            'insumo_id': null,
            'activo_fijo_id': null,
            'compra_movimiento_id': null,
            'compra_ocasional_id': compraId,
          },
          where: 'id = ?',
          whereArgs: [cuentaId],
        );
      }

      await txn.update(
        'ComprasOcasionales',
        {
          'fecha': targetFecha,
          'descripcion': descripcion,
          'cantidad': compra.cantidad,
          'unidad_medida': unidad,
          'costo_total': compra.costoTotal,
          'categoria': categoria,
          'proveedor': proveedor,
          'proveedor_id': compra.proveedorId,
          'factura_ruta': compra.facturaRuta,
          'es_por_pagar': compra.esPorPagar ? 1 : 0,
          'adelanto': compra.esPorPagar ? adelantoEfectivo : 0.0,
          'cuotas': compra.esPorPagar ? compra.cuotas : 1,
          'metodo_pago': compra.metodoPago,
        },
        where: 'id = ?',
        whereArgs: [compraId],
      );

      await AuditLogWriter.record(
        txn,
        action: 'compra_ocasional_corregida',
        detail:
            'Compra ocasional #$compraId; total ${compra.costoTotal}; '
            '${compra.esPorPagar ? 'crédito' : 'contado'}; sin stock.',
        userId: compra.usuarioId,
      );
    });
  }

  /// Elimina una compra ocasional y sus hijos financieros por IDs explícitos.
  /// No revierte stock porque la compra ocasional nunca lo modificó.
  Future<void> eliminarCompraOcasional(
    int compraId, {
    int? usuarioId,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final headerRows = await txn.query(
        'ComprasOcasionales',
        where: 'id = ?',
        whereArgs: [compraId],
        limit: 1,
      );
      if (headerRows.isEmpty) {
        throw Exception('La compra ocasional no existe o ya fue eliminada.');
      }

      final cuentas = await txn.query(
        'CuentasPorPagar',
        where: 'compra_ocasional_id = ?',
        whereArgs: [compraId],
      );
      final pagos = <Map<String, Object?>>[];
      for (final cuenta in cuentas) {
        final cuentaId = cuenta['id'] as int;
        final filas = await txn.query(
          'PagosCuentaPorPagar',
          where: 'cuenta_id = ?',
          whereArgs: [cuentaId],
        );
        pagos.addAll(filas);
      }
      final gastos = await txn.query(
        'Gastos',
        where: 'compra_ocasional_id = ?',
        whereArgs: [compraId],
      );

      final movimientos = <int>{};
      for (final pago in pagos) {
        final movimientoId = pago['movimiento_caja_id'] as int?;
        if (movimientoId != null) movimientos.add(movimientoId);
      }
      for (final gasto in gastos) {
        final movimientoId = gasto['movimiento_caja_id'] as int?;
        if (movimientoId != null) movimientos.add(movimientoId);
      }

      for (final pago in pagos) {
        await txn.delete(
          'PagosCuentaPorPagar',
          where: 'id = ?',
          whereArgs: [pago['id']],
        );
      }
      for (final gasto in gastos) {
        await txn.delete(
          'Gastos',
          where: 'id = ?',
          whereArgs: [gasto['id']],
        );
      }
      for (final movimientoId in movimientos) {
        await txn.delete(
          'MovimientosCaja',
          where: 'id = ?',
          whereArgs: [movimientoId],
        );
      }
      for (final cuenta in cuentas) {
        await txn.delete(
          'CuentasPorPagar',
          where: 'id = ?',
          whereArgs: [cuenta['id']],
        );
      }
      await txn.delete(
        'ComprasOcasionales',
        where: 'id = ?',
        whereArgs: [compraId],
      );

      await AuditLogWriter.record(
        txn,
        action: 'compra_ocasional_eliminada',
        detail:
            'Compra ocasional #$compraId eliminada sin reversion de stock; '
            '${pagos.length} pago(s), ${gastos.length} gasto(s), '
            '${movimientos.length} movimiento(s).',
        userId: usuarioId,
      );
    });
  }

  /// Historial de cabeceras ocasionales con su cuenta por pagar cuando existe.
  Future<List<Map<String, dynamic>>> getComprasOcasionales() async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT co.*, c.id AS cuenta_id, c.monto_pagado AS cuenta_monto_pagado,
             c.pagado AS cuenta_pagado, c.fecha_pago AS cuenta_fecha_pago,
             c.adelanto AS cuenta_adelanto,
             COALESCE(c.proveedor, p.nombre) AS proveedor_nombre
      FROM ComprasOcasionales co
      LEFT JOIN CuentasPorPagar c ON c.compra_ocasional_id = co.id
      LEFT JOIN Proveedores p ON p.id = COALESCE(c.proveedor_id, co.proveedor_id)
      ORDER BY co.fecha DESC, co.id DESC
    ''');
  }

  /// Corrects a previously recorded purchase without silently changing stock.
  /// A quantity difference is written as a compensating inventory adjustment;
  /// monetary and payable records are updated in the same transaction.
  /// Corrects a previously recorded purchase with complete multi-field reconciliation.
  /// Handles quantity, unit cost, date, ingredient swap, vendor, debt conversion, and payment method.
  Future<void> corregirCompra({
    required int movimientoId,
    required double cantidad,
    required double costoTotal,
    int? nuevoInsumoId,
    String? fecha,
    String? motivo,
    String? proveedor,
    int? proveedorId,
    String? facturaRuta,
    bool? esPorPagar,
    double? adelanto,
    int cuotas = 1,
    String metodoPago = 'efectivo',
    int? usuarioId,
  }) async {
    if (!cantidad.isFinite ||
        cantidad <= 0 ||
        !costoTotal.isFinite ||
        costoTotal <= 0) {
      throw Exception('Cantidad y costo deben ser mayores a cero.');
    }
    _validatePaymentMethod(metodoPago);
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'AjustesStock',
        where: 'id = ? AND tipo_adquisicion = ?',
        whereArgs: [movimientoId, 'comprado'],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw Exception('La compra ya no está disponible para corregir.');
      }
      final purchase = rows.first;
      final int insumoIdOriginal = purchase['insumo_id'] as int;
      final int targetInsumoId = nuevoInsumoId ?? insumoIdOriginal;
      final String targetFecha = fecha ?? (purchase['fecha'] as String);

      final correctionRows = await txn.query(
        'CorreccionesCompra',
        where: 'compra_movimiento_id = ?',
        whereArgs: [movimientoId],
        orderBy: 'id DESC',
        limit: 1,
      );
      final latestCorrection =
          correctionRows.isEmpty ? null : correctionRows.first;
      final oldQuantity =
          (latestCorrection?['cantidad_nueva'] as num?)?.toDouble() ??
          (purchase['cantidad_ajuste'] as num).toDouble();
      final oldUnitCost =
          (latestCorrection?['costo_unitario_nuevo'] as num?)?.toDouble() ??
          (purchase['costo_unitario'] as num?)?.toDouble() ??
          0.0;
      final oldTotal = oldQuantity * oldUnitCost;
      final newUnitCost = costoTotal / cantidad;

      final linkedExpense = await _resolveLinkedOrLegacyExpense(
        txn,
        movimientoId,
        purchase,
        oldTotal,
      );
      final linkedPayable = await _resolveLinkedOrLegacyPayable(
        txn,
        movimientoId,
        purchase,
        oldTotal,
      );
      final linkedCash = await _resolveLinkedOrLegacyCash(
        txn,
        movimientoId,
        purchase,
        oldTotal,
      );

      final targetEsPorPagar = esPorPagar ?? (linkedPayable != null);
      final targetAdelanto = adelanto ?? 0.0;

      // 1. Reconcile Stock in Insumos
      if (targetInsumoId == insumoIdOriginal) {
        final delta = cantidad - oldQuantity;
        final stockRows = await txn.query(
          'Insumos',
          where: 'id = ?',
          whereArgs: [insumoIdOriginal],
          limit: 1,
        );
        if (stockRows.isNotEmpty) {
          final currentQty =
              (stockRows.first['stock_actual'] as num?)?.toDouble() ?? 0.0;
          final updatedStock =
              (currentQty + delta).clamp(0.0, double.infinity);
          final currentCost =
              (stockRows.first['costo_por_unidad'] as num?)?.toDouble() ?? 0.0;
          final newAverage = updatedStock > 0
              ? (((currentQty * currentCost) -
                          (oldQuantity * oldUnitCost) +
                          costoTotal) /
                      updatedStock)
              : newUnitCost;
          await txn.update(
            'Insumos',
            {
              'stock_actual': updatedStock,
              'costo_por_unidad': newAverage > 0 ? newAverage : newUnitCost,
            },
            where: 'id = ?',
            whereArgs: [insumoIdOriginal],
          );
        }
      } else {
        // Insumo changed! Revert old, add new
        final oldInsumoRows = await txn.query(
          'Insumos',
          where: 'id = ?',
          whereArgs: [insumoIdOriginal],
          limit: 1,
        );
        if (oldInsumoRows.isNotEmpty) {
          final currentQty =
              (oldInsumoRows.first['stock_actual'] as num?)?.toDouble() ?? 0.0;
          final updatedOldStock =
              (currentQty - oldQuantity).clamp(0.0, double.infinity);
          await txn.update(
            'Insumos',
            {'stock_actual': updatedOldStock},
            where: 'id = ?',
            whereArgs: [insumoIdOriginal],
          );
        }
        final newInsumoRows = await txn.query(
          'Insumos',
          where: 'id = ?',
          whereArgs: [targetInsumoId],
          limit: 1,
        );
        if (newInsumoRows.isNotEmpty) {
          final currentQty =
              (newInsumoRows.first['stock_actual'] as num?)?.toDouble() ?? 0.0;
          final updatedNewStock = currentQty + cantidad;
          final currentCost =
              (newInsumoRows.first['costo_por_unidad'] as num?)?.toDouble() ??
              0.0;
          final newAverage = updatedNewStock > 0
              ? ((currentQty * currentCost) + costoTotal) / updatedNewStock
              : newUnitCost;
          await txn.update(
            'Insumos',
            {
              'stock_actual': updatedNewStock,
              'costo_por_unidad': newAverage > 0 ? newAverage : newUnitCost,
            },
            where: 'id = ?',
            whereArgs: [targetInsumoId],
          );
        }
      }

      // 2. Update AjustesStock
      final Map<String, Object?> stockUpdate = {
        'insumo_id': targetInsumoId,
        'cantidad_ajuste': cantidad,
        'costo_unitario': newUnitCost,
        'fecha': targetFecha,
        'motivo': motivo ?? 'Compra',
        'proveedor_id': proveedorId,
      };
      if (usuarioId != null) {
        stockUpdate['usuario_id'] = usuarioId;
      }
      await txn.update(
        'AjustesStock',
        stockUpdate,
        where: 'id = ?',
        whereArgs: [movimientoId],
      );

      // 3. Record in CorreccionesCompra
      await txn.insert('CorreccionesCompra', {
        'compra_movimiento_id': movimientoId,
        'cantidad_anterior': oldQuantity,
        'costo_unitario_anterior': oldUnitCost,
        'cantidad_nueva': cantidad,
        'costo_unitario_nuevo': newUnitCost,
        'motivo': motivo?.trim().isNotEmpty == true ? motivo!.trim() : null,
        'fecha': DateTime.now().toIso8601String(),
        'usuario_id': usuarioId,
      });

      // 4. Financial Reconciliation
      final cleanDate = _dateOnly(targetFecha);
      final activeSessions = cleanDate == _today()
          ? await txn.query(
              'SesionesCaja',
              where: "estado = 'abierta'",
              orderBy: 'id DESC',
              limit: 1,
            )
          : <Map<String, Object?>>[];
      final int? activeSessionId =
          activeSessions.isNotEmpty ? activeSessions.first['id'] as int : null;

      if (!targetEsPorPagar) {
        // CASE: Pagado al contado
        if (linkedPayable != null) {
          final payments = await txn.query(
            'PagosCuentaPorPagar',
            where: 'cuenta_id = ?',
            whereArgs: [linkedPayable],
          );
          await txn.delete(
            'PagosCuentaPorPagar',
            where: 'cuenta_id = ?',
            whereArgs: [linkedPayable],
          );
          for (final p in payments) {
            if (p['movimiento_caja_id'] != null) {
              await txn.delete(
                'MovimientosCaja',
                where: 'id = ?',
                whereArgs: [p['movimiento_caja_id']],
              );
            }
            if (p['gasto_id'] != null) {
              await txn.delete(
                'Gastos',
                where: 'id = ?',
                whereArgs: [p['gasto_id']],
              );
            }
          }
          await txn.delete(
            'CuentasPorPagar',
            where: 'id = ?',
            whereArgs: [linkedPayable],
          );
        }

        // Update or insert Gasto
        if (linkedExpense != null) {
          await txn.update(
            'Gastos',
            {
              'fecha': cleanDate,
              'monto': costoTotal,
              'descripcion': 'Compra: ${motivo ?? ''}',
              'insumo_id': targetInsumoId,
              'foto_recibo_ruta': facturaRuta,
              'categoria': 'Compras',
              'compra_movimiento_id': movimientoId,
            },
            where: 'id = ?',
            whereArgs: [linkedExpense],
          );
        } else {
          await txn.insert('Gastos', {
            'fecha': cleanDate,
            'created_at': targetFecha.contains('T')
                ? targetFecha
                : DateTime.now().toIso8601String(),
            'categoria': 'Compras',
            'descripcion': 'Compra: ${motivo ?? ''}',
            'monto': costoTotal,
            'insumo_id': targetInsumoId,
            'foto_recibo_ruta': facturaRuta,
            'usuario_id': usuarioId,
            'compra_movimiento_id': movimientoId,
            'sesion_caja_id': activeSessionId,
          });
        }

        // Update or insert MovimientosCaja
        if (linkedCash != null) {
          await txn.update(
            'MovimientosCaja',
            {
              'monto': costoTotal,
              'metodo_pago': metodoPago,
              'descripcion': motivo ?? 'Compra directa',
              'fecha': targetFecha,
              'compra_movimiento_id': movimientoId,
            },
            where: 'id = ?',
            whereArgs: [linkedCash],
          );
        } else if (activeSessionId != null && costoTotal > 0) {
          await txn.insert('MovimientosCaja', {
            'sesion_caja_id': activeSessionId,
            'tipo': 'compra',
            'metodo_pago': metodoPago,
            'monto': costoTotal,
            'descripcion': motivo ?? 'Compra directa',
            'fecha': targetFecha,
            'compra_movimiento_id': movimientoId,
          });
        }
      } else {
        // CASE: Cuenta por pagar (RN-01 / C-01)
        if (linkedPayable != null) {
          final payableRows = await txn.query(
            'CuentasPorPagar',
            where: 'id = ?',
            whereArgs: [linkedPayable],
            limit: 1,
          );
          final payableRow =
              payableRows.isNotEmpty ? payableRows.first : <String, Object?>{};
          final existingAdelanto =
              (payableRow['adelanto'] as num?)?.toDouble() ?? 0.0;
          final effectiveAdelanto = adelanto ?? existingAdelanto;
          if (effectiveAdelanto < 0) {
            throw Exception('El adelanto no puede ser negativo.');
          }

          final payments = await txn.query(
            'PagosCuentaPorPagar',
            where: 'cuenta_id = ?',
            whereArgs: [linkedPayable],
            orderBy: 'id ASC',
          );
          Map<String, Object?>? advancePaymentRow;
          double abonosPosteriores = 0.0;
          for (final p in payments) {
            final nota = (p['nota'] as String? ?? '').trim();
            if (advancePaymentRow == null && nota == 'Adelanto de compra') {
              advancePaymentRow = p;
            } else {
              abonosPosteriores += (p['monto'] as num?)?.toDouble() ?? 0.0;
            }
          }

          final nuevoMontoPagado = effectiveAdelanto + abonosPosteriores;
          if (costoTotal + 0.000001 < nuevoMontoPagado) {
            throw Exception(
              'El nuevo costo total (S/ ${costoTotal.toStringAsFixed(2)}) no puede ser menor al monto ya abonado (S/ ${nuevoMontoPagado.toStringAsFixed(2)}).',
            );
          }

          final advMovCajaId = advancePaymentRow?['movimiento_caja_id'] as int?;
          final advGastoId = advancePaymentRow?['gasto_id'] as int?;
          if (linkedCash != null && linkedCash != advMovCajaId) {
            await txn.delete(
              'MovimientosCaja',
              where: 'id = ?',
              whereArgs: [linkedCash],
            );
          }
          if (linkedExpense != null && linkedExpense != advGastoId) {
            await txn.delete(
              'Gastos',
              where: 'id = ?',
              whereArgs: [linkedExpense],
            );
          }

          final paymentReason = motivo?.trim().isNotEmpty == true
              ? motivo!.trim()
              : 'Adelanto de compra';
          if (effectiveAdelanto > 0) {
            if (advancePaymentRow != null) {
              final advPaymentId = advancePaymentRow['id'] as int;
              int? updatedGastoId = advGastoId;
              int? updatedMovCajaId = advMovCajaId;
              if (updatedGastoId != null) {
                await txn.update(
                  'Gastos',
                  {
                    'fecha': cleanDate,
                    'monto': effectiveAdelanto,
                    'descripcion': 'Pago CxP $linkedPayable: $paymentReason',
                    'insumo_id': targetInsumoId,
                    'foto_recibo_ruta': facturaRuta,
                    'categoria': 'Cuentas por Pagar',
                  },
                  where: 'id = ?',
                  whereArgs: [updatedGastoId],
                );
              } else {
                updatedGastoId = await txn.insert('Gastos', {
                  'fecha': cleanDate,
                  'created_at': targetFecha.contains('T')
                      ? targetFecha
                      : DateTime.now().toIso8601String(),
                  'categoria': 'Cuentas por Pagar',
                  'descripcion': 'Pago CxP $linkedPayable: $paymentReason',
                  'monto': effectiveAdelanto,
                  'insumo_id': targetInsumoId,
                  'foto_recibo_ruta': facturaRuta,
                  'usuario_id': usuarioId,
                  'sesion_caja_id': activeSessionId,
                });
              }

              if (updatedMovCajaId != null) {
                await txn.update(
                  'MovimientosCaja',
                  {
                    'monto': effectiveAdelanto,
                    'metodo_pago': metodoPago,
                    'descripcion': 'Pago CxP: $paymentReason',
                    'fecha': targetFecha,
                  },
                  where: 'id = ?',
                  whereArgs: [updatedMovCajaId],
                );
              } else if (activeSessionId != null) {
                updatedMovCajaId = await txn.insert('MovimientosCaja', {
                  'sesion_caja_id': activeSessionId,
                  'tipo': 'salida',
                  'metodo_pago': metodoPago,
                  'monto': effectiveAdelanto,
                  'descripcion': 'Pago CxP: $paymentReason',
                  'fecha': targetFecha,
                });
              }

              await txn.update(
                'PagosCuentaPorPagar',
                {
                  'monto': effectiveAdelanto,
                  'metodo_pago': metodoPago,
                  'fecha': targetFecha,
                  'gasto_id': updatedGastoId,
                  'movimiento_caja_id': updatedMovCajaId,
                  'usuario_id': usuarioId,
                },
                where: 'id = ?',
                whereArgs: [advPaymentId],
              );
            } else {
              final paymentId = await txn.insert('PagosCuentaPorPagar', {
                'cuenta_id': linkedPayable,
                'monto': effectiveAdelanto,
                'metodo_pago': metodoPago,
                'fecha': targetFecha,
                'nota': 'Adelanto de compra',
                'usuario_id': usuarioId,
              });
              await _recordPaymentFinancials(
                txn,
                paymentId: paymentId,
                payableId: linkedPayable,
                amount: effectiveAdelanto,
                paymentMethod: metodoPago,
                reason: paymentReason,
                date: targetFecha,
                userId: usuarioId,
              );
            }
          } else if (advancePaymentRow != null) {
            await txn.delete(
              'PagosCuentaPorPagar',
              where: 'id = ?',
              whereArgs: [advancePaymentRow['id']],
            );
            if (advMovCajaId != null) {
              await txn.delete(
                'MovimientosCaja',
                where: 'id = ?',
                whereArgs: [advMovCajaId],
              );
            }
            if (advGastoId != null) {
              await txn.delete(
                'Gastos',
                where: 'id = ?',
                whereArgs: [advGastoId],
              );
            }
          }

          final isPaid = nuevoMontoPagado >= costoTotal - 0.000001;
          await txn.update(
            'CuentasPorPagar',
            {
              'fecha': targetFecha,
              'insumo_id': targetInsumoId,
              'cantidad': cantidad,
              'costo_total': costoTotal,
              'monto_pagado': nuevoMontoPagado,
              'adelanto': effectiveAdelanto,
              'proveedor': proveedor,
              'proveedor_id': proveedorId,
              'motivo': motivo,
              'factura_ruta': facturaRuta,
              'pagado': isPaid ? 1 : 0,
              'fecha_pago': isPaid
                  ? (payableRow['fecha_pago'] ?? targetFecha)
                  : null,
              'cuotas': cuotas,
              'compra_movimiento_id': movimientoId,
            },
            where: 'id = ?',
            whereArgs: [linkedPayable],
          );
        } else {
          if (targetAdelanto < 0 || targetAdelanto > costoTotal + 0.000001) {
            throw Exception(
              'El adelanto no puede ser negativo ni superar el costo total.',
            );
          }
          if (linkedCash != null) {
            await txn.delete(
              'MovimientosCaja',
              where: 'id = ?',
              whereArgs: [linkedCash],
            );
          }
          if (linkedExpense != null) {
            await txn.delete(
              'Gastos',
              where: 'id = ?',
              whereArgs: [linkedExpense],
            );
          }

          final isPaid = targetAdelanto >= costoTotal - 0.000001;
          final newPayableId = await txn.insert('CuentasPorPagar', {
            'fecha': targetFecha,
            'insumo_id': targetInsumoId,
            'cantidad': cantidad,
            'costo_total': costoTotal,
            'monto_pagado': targetAdelanto,
            'adelanto': targetAdelanto,
            'proveedor': proveedor,
            'proveedor_id': proveedorId,
            'motivo': motivo,
            'factura_ruta': facturaRuta,
            'pagado': isPaid ? 1 : 0,
            'fecha_pago': isPaid ? targetFecha : null,
            'cuotas': cuotas,
            'usuario_id': usuarioId,
            'compra_movimiento_id': movimientoId,
          });
          if (targetAdelanto > 0) {
            final paymentId = await txn.insert('PagosCuentaPorPagar', {
              'cuenta_id': newPayableId,
              'monto': targetAdelanto,
              'metodo_pago': metodoPago,
              'fecha': targetFecha,
              'nota': 'Adelanto de compra',
              'usuario_id': usuarioId,
            });
            await _recordPaymentFinancials(
              txn,
              paymentId: paymentId,
              payableId: newPayableId,
              amount: targetAdelanto,
              paymentMethod: metodoPago,
              reason: motivo?.trim().isNotEmpty == true
                  ? motivo!.trim()
                  : 'Adelanto de compra',
              date: targetFecha,
              userId: usuarioId,
            );
          }
        }
      }

      await AuditLogWriter.record(
        txn,
        action: 'compra_corregida',
        userId: usuarioId,
        detail:
            'Compra #$movimientoId; cantidad $oldQuantity → $cantidad; total ${oldTotal.toStringAsFixed(2)} → ${costoTotal.toStringAsFixed(2)}.',
      );
    });
  }

  /// Safely eliminates a purchase, cascading reversions to stock, cash, expenses and payables.
  Future<void> eliminarCompra(int movimientoId, {int? usuarioId}) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'AjustesStock',
        where: 'id = ? AND tipo_adquisicion = ?',
        whereArgs: [movimientoId, 'comprado'],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw Exception('La compra no existe o ya fue eliminada.');
      }
      final purchase = rows.first;
      final insumoId = purchase['insumo_id'] as int;

      final corrRows = await txn.query(
        'CorreccionesCompra',
        where: 'compra_movimiento_id = ?',
        whereArgs: [movimientoId],
        orderBy: 'id DESC',
        limit: 1,
      );
      final double cantidadAEliminar = corrRows.isNotEmpty
          ? (corrRows.first['cantidad_nueva'] as num).toDouble()
          : (purchase['cantidad_ajuste'] as num).toDouble();

      // 1. Revert stock in Insumos safely
      final insumoRows = await txn.query(
        'Insumos',
        where: 'id = ?',
        whereArgs: [insumoId],
        limit: 1,
      );
      if (insumoRows.isNotEmpty) {
        final stockActual =
            (insumoRows.first['stock_actual'] as num?)?.toDouble() ?? 0.0;
        final nuevoStock =
            (stockActual - cantidadAEliminar).clamp(0.0, double.infinity);
        await txn.update(
          'Insumos',
          {'stock_actual': nuevoStock},
          where: 'id = ?',
          whereArgs: [insumoId],
        );
      }

      // 2. Remove linked CuentasPorPagar and its payments first (child -> parent FK order)
      final payables = await txn.query(
        'CuentasPorPagar',
        where: 'compra_movimiento_id = ?',
        whereArgs: [movimientoId],
      );
      for (final p in payables) {
        final pId = p['id'] as int;
        final pagos = await txn.query(
          'PagosCuentaPorPagar',
          where: 'cuenta_id = ?',
          whereArgs: [pId],
        );
        await txn.delete(
          'PagosCuentaPorPagar',
          where: 'cuenta_id = ?',
          whereArgs: [pId],
        );
        for (final pago in pagos) {
          final movCajaId = pago['movimiento_caja_id'] as int?;
          if (movCajaId != null) {
            await txn.delete(
              'MovimientosCaja',
              where: 'id = ?',
              whereArgs: [movCajaId],
            );
          }
          final gastoId = pago['gasto_id'] as int?;
          if (gastoId != null) {
            await txn.delete('Gastos', where: 'id = ?', whereArgs: [gastoId]);
          }
        }
        await txn.delete(
          'CuentasPorPagar',
          where: 'id = ?',
          whereArgs: [pId],
        );
      }

      // 3. Remove linked MovimientosCaja
      await txn.delete(
        'MovimientosCaja',
        where: 'compra_movimiento_id = ?',
        whereArgs: [movimientoId],
      );

      // 4. Remove linked Gastos
      await txn.delete(
        'Gastos',
        where: 'compra_movimiento_id = ?',
        whereArgs: [movimientoId],
      );

      // 5. Remove CorreccionesCompra
      await txn.delete(
        'CorreccionesCompra',
        where: 'compra_movimiento_id = ?',
        whereArgs: [movimientoId],
      );

      // 6. Delete from AjustesStock
      await txn.delete(
        'AjustesStock',
        where: 'id = ?',
        whereArgs: [movimientoId],
      );

      // 7. Audit log
      await AuditLogWriter.record(
        txn,
        action: 'compra_eliminada',
        detail:
            'Compra #$movimientoId eliminada y stock revertido ($cantidadAEliminar).',
        userId: usuarioId,
      );
    });
  }

  /// Safely eliminates a standalone gasto (RN-02 / C-02).
  /// Blocks direct deletion of purchase expenses or payable installments.
  Future<void> eliminarGasto(int gastoId, {int? usuarioId}) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'Gastos',
        where: 'id = ?',
        whereArgs: [gastoId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw Exception('El gasto no existe o ya fue eliminado.');
      }
      final gasto = rows.first;
      final compraMovId = gasto['compra_movimiento_id'] as int?;
      final compraOcasionalId = gasto['compra_ocasional_id'] as int?;
      final categoria = (gasto['categoria'] as String? ?? '').trim();
      if (compraOcasionalId != null) {
        throw Exception(
          'No se puede eliminar un gasto de compra ocasional desde Gastos. '
          'Corrígela o elimínala desde Compras ocasionales.',
        );
      }
      if (compraMovId != null || categoria == 'Compras') {
        throw Exception(
          'No se puede eliminar un gasto de compra desde Gastos. Anula o corrige la compra desde el módulo de Compras.',
        );
      }
      final linkedPayments = await txn.query(
        'PagosCuentaPorPagar',
        columns: ['id'],
        where: 'gasto_id = ?',
        whereArgs: [gastoId],
        limit: 1,
      );
      if (linkedPayments.isNotEmpty || categoria == 'Cuentas por Pagar') {
        throw Exception(
          'No se puede eliminar un abono de deuda desde Gastos. Anula el abono desde Cuentas por Pagar.',
        );
      }

      final movCajaId = gasto['movimiento_caja_id'] as int?;
      final sesionId = gasto['sesion_caja_id'] as int?;
      final monto = (gasto['monto'] as num?)?.toDouble() ?? 0.0;
      final fecha = _dateOnly(gasto['fecha'] as String? ?? '');

      // Gastos is a child of MovimientosCaja (FK): delete it before the
      // linked movement so the parent row can be removed safely.
      await txn.delete('Gastos', where: 'id = ?', whereArgs: [gastoId]);

      final String cajaDetail;
      if (movCajaId != null) {
        // Explicit link (H-05): delete the exact movement, unless a debt
        // payment already references it.
        final paymentRefs = await txn.query(
          'PagosCuentaPorPagar',
          columns: ['id'],
          where: 'movimiento_caja_id = ?',
          whereArgs: [movCajaId],
          limit: 1,
        );
        if (paymentRefs.isNotEmpty) {
          cajaDetail =
              'MovimientoCaja #$movCajaId conservado: referenciado por un pago de deuda.';
        } else {
          final deleted = await txn.delete(
            'MovimientosCaja',
            where: 'id = ?',
            whereArgs: [movCajaId],
          );
          cajaDetail = deleted > 0
              ? 'MovimientoCaja #$movCajaId eliminado por vínculo explícito.'
              : 'MovimientoCaja #$movCajaId ya no existía.';
        }
      } else if (sesionId != null) {
        // Legacy gasto without link: fallback only with EXACTLY one candidate;
        // an ambiguous movement is never deleted.
        final candidates = await txn.rawQuery(
          '''
          SELECT mc.id
          FROM MovimientosCaja mc
          WHERE mc.sesion_caja_id = ?
            AND mc.tipo = 'salida'
            AND mc.compra_movimiento_id IS NULL
            AND mc.venta_id IS NULL
            AND ABS(mc.monto - ?) < 0.01
            AND mc.fecha LIKE ?
            AND NOT EXISTS (
              SELECT 1 FROM PagosCuentaPorPagar p WHERE p.movimiento_caja_id = mc.id
            )
            AND NOT EXISTS (
              SELECT 1 FROM Gastos g WHERE g.movimiento_caja_id = mc.id
            )
          ORDER BY mc.id DESC
          LIMIT 2
          ''',
          [sesionId, monto, '$fecha%'],
        );
        if (candidates.length == 1) {
          final candidateId = candidates.first['id'];
          final deleted = await txn.delete(
            'MovimientosCaja',
            where: 'id = ?',
            whereArgs: [candidateId],
          );
          cajaDetail = deleted > 0
              ? 'MovimientoCaja #$candidateId eliminado por coincidencia única (legado).'
              : 'MovimientoCaja #$candidateId ya no existía.';
        } else if (candidates.isEmpty) {
          cajaDetail = 'Sin movimiento de caja coincidente (gasto legado).';
        } else {
          cajaDetail =
              'Movimiento de caja conservado: ${candidates.length} candidatos ambiguos (gasto legado).';
        }
      } else {
        cajaDetail = 'Gasto sin vínculo a caja.';
      }

      await AuditLogWriter.record(
        txn,
        action: 'gasto_eliminado',
        detail: 'Gasto #$gastoId de S/ $monto eliminado. $cajaDetail',
        userId: usuarioId,
      );
    });
  }

  /// Reverses a payable installment atomically by exact IDs (RN-02 / C-02).
  Future<void> anularPagoCuentaPorPagar(int pagoId, {int? usuarioId}) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final pagoRows = await txn.query(
        'PagosCuentaPorPagar',
        where: 'id = ?',
        whereArgs: [pagoId],
        limit: 1,
      );
      if (pagoRows.isEmpty) {
        throw Exception('El abono no existe o ya fue anulado.');
      }
      final pago = pagoRows.first;
      final cuentaId = pago['cuenta_id'] as int;
      final monto = (pago['monto'] as num?)?.toDouble() ?? 0.0;
      final gastoId = pago['gasto_id'] as int?;
      final movCajaId = pago['movimiento_caja_id'] as int?;
      final nota = (pago['nota'] as String? ?? '').trim();

      // Delete child PagosCuentaPorPagar first before parent MovimientosCaja / Gastos
      await txn.delete(
        'PagosCuentaPorPagar',
        where: 'id = ?',
        whereArgs: [pagoId],
      );
      if (movCajaId != null) {
        await txn.delete(
          'MovimientosCaja',
          where: 'id = ?',
          whereArgs: [movCajaId],
        );
      }
      if (gastoId != null) {
        await txn.delete(
          'Gastos',
          where: 'id = ?',
          whereArgs: [gastoId],
        );
      }

      final cuentaRows = await txn.query(
        'CuentasPorPagar',
        where: 'id = ?',
        whereArgs: [cuentaId],
        limit: 1,
      );
      if (cuentaRows.isNotEmpty) {
        final cuenta = cuentaRows.first;
        final costoTotal = (cuenta['costo_total'] as num?)?.toDouble() ?? 0.0;
        final remainingPayments = await txn.query(
          'PagosCuentaPorPagar',
          where: 'cuenta_id = ?',
          whereArgs: [cuentaId],
          orderBy: 'fecha DESC, id DESC',
        );
        final nuevoMontoPagado = remainingPayments.fold<double>(
          0.0,
          (sum, row) => sum + ((row['monto'] as num?)?.toDouble() ?? 0.0),
        );
        final currentAdelanto =
            (cuenta['adelanto'] as num?)?.toDouble() ?? 0.0;
        final nuevoAdelanto =
            nota == 'Adelanto de compra' ? 0.0 : currentAdelanto;
        final isPaid =
            costoTotal > 0 && nuevoMontoPagado >= costoTotal - 0.000001;
        await txn.update(
          'CuentasPorPagar',
          {
            'monto_pagado': nuevoMontoPagado,
            'adelanto': nuevoAdelanto,
            'pagado': isPaid ? 1 : 0,
            'fecha_pago': isPaid && remainingPayments.isNotEmpty
                ? remainingPayments.first['fecha']
                : null,
          },
          where: 'id = ?',
          whereArgs: [cuentaId],
        );
      }

      await AuditLogWriter.record(
        txn,
        action: 'abono_cxp_anulado',
        detail:
            'Abono #$pagoId de S/ ${monto.toStringAsFixed(2)} anulado en cuenta #$cuentaId.',
        userId: usuarioId,
      );
    });
  }

  Future<int?> _resolveLinkedOrLegacyExpense(
    DatabaseExecutor txn,
    int movementId,
    Map<String, Object?> purchase,
    double oldTotal,
  ) async {
    final linked = await txn.query(
      'Gastos',
      columns: ['id'],
      where: 'compra_movimiento_id = ?',
      whereArgs: [movementId],
      limit: 1,
    );
    if (linked.isNotEmpty) return linked.first['id'] as int;
    final date = _dateOnly(purchase['fecha'] as String);
    final rows = await txn.rawQuery(
      '''
      SELECT id FROM Gastos WHERE insumo_id = ? AND fecha = ?
        AND ABS(monto - ?) < 0.011 AND compra_movimiento_id IS NULL
    ''',
      [purchase['insumo_id'], date, oldTotal],
    );
    return rows.length == 1 ? rows.first['id'] as int : null;
  }

  Future<int?> _resolveLinkedOrLegacyPayable(
    DatabaseExecutor txn,
    int movementId,
    Map<String, Object?> purchase,
    double oldTotal,
  ) async {
    final linked = await txn.query(
      'CuentasPorPagar',
      columns: ['id'],
      where: 'compra_movimiento_id = ?',
      whereArgs: [movementId],
      limit: 1,
    );
    if (linked.isNotEmpty) return linked.first['id'] as int;
    final rows = await txn.rawQuery(
      '''
      SELECT id FROM CuentasPorPagar WHERE insumo_id = ? AND fecha = ?
        AND ABS(costo_total - ?) < 0.011 AND compra_movimiento_id IS NULL
    ''',
      [purchase['insumo_id'], purchase['fecha'], oldTotal],
    );
    return rows.length == 1 ? rows.first['id'] as int : null;
  }

  Future<int?> _resolveLinkedOrLegacyCash(
    DatabaseExecutor txn,
    int movementId,
    Map<String, Object?> purchase,
    double oldTotal,
  ) async {
    final linked = await txn.query(
      'MovimientosCaja',
      columns: ['id'],
      where: 'compra_movimiento_id = ?',
      whereArgs: [movementId],
      limit: 1,
    );
    if (linked.isNotEmpty) return linked.first['id'] as int;
    final rows = await txn.rawQuery(
      '''
      SELECT id FROM MovimientosCaja WHERE tipo = 'compra'
        AND fecha = ? AND ABS(monto - ?) < 0.011
        AND compra_movimiento_id IS NULL
    ''',
      [purchase['fecha'], oldTotal],
    );
    return rows.length == 1 ? rows.first['id'] as int : null;
  }

  Future<Map<String, dynamic>> aplicarPago(
    int cuentaId,
    double monto, {
    required String metodoPago,
    String? nota,
    int? usuarioId,
  }) async {
    if (!monto.isFinite || monto <= 0) {
      throw Exception('El abono debe ser mayor a cero.');
    }
    _validatePaymentMethod(metodoPago);
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'CuentasPorPagar',
        where: 'id = ?',
        whereArgs: [cuentaId],
      );
      if (rows.isEmpty) throw Exception('Cuenta no encontrada.');
      final account = rows.first;
      final total = (account['costo_total'] as num).toDouble();
      final paid = (account['monto_pagado'] as num?)?.toDouble() ?? 0;
      final balance = total - paid;
      if (monto > balance + 0.000001) {
        throw Exception('El abono supera el saldo pendiente.');
      }
      final compraOcasionalId =
          (account['compra_ocasional_id'] as num?)?.toInt();
      String? categoriaOcasional;
      if (compraOcasionalId != null) {
        final cabecera = await txn.query(
          'ComprasOcasionales',
          columns: ['categoria'],
          where: 'id = ?',
          whereArgs: [compraOcasionalId],
          limit: 1,
        );
        if (cabecera.isEmpty) {
          throw Exception('La compra ocasional asociada ya no existe.');
        }
        categoriaOcasional = cabecera.first['categoria'] as String?;
      }
      final updatedPaid = paid + monto;
      await txn.update(
        'CuentasPorPagar',
        {
          'monto_pagado': updatedPaid,
          'pagado': updatedPaid >= total ? 1 : 0,
          'fecha_pago': updatedPaid >= total
              ? DateTime.now().toIso8601String()
              : account['fecha_pago'],
        },
        where: 'id = ?',
        whereArgs: [cuentaId],
      );
      int paymentId;
      try {
        paymentId = await txn.insert('PagosCuentaPorPagar', {
          'cuenta_id': cuentaId,
          'fecha': DateTime.now().toIso8601String(),
          'monto': monto,
          'metodo_pago': metodoPago,
          'nota': nota,
          'usuario_id': usuarioId,
        });
      } catch (_) {
        paymentId = await txn.insert('PagosCuentaPorPagar', {
          'cuenta_id': cuentaId,
          'fecha': DateTime.now().toIso8601String(),
          'monto': monto,
          'metodo_pago': 'yape',
          'nota': nota != null ? '$nota (Yape/Plin)' : '(Yape/Plin)',
          'usuario_id': usuarioId,
        });
      }
      final reason = account['motivo']?.toString() ?? 'Cuenta';
      await _recordPaymentFinancials(
        txn,
        paymentId: paymentId,
        payableId: cuentaId,
        amount: monto,
        paymentMethod: metodoPago,
        reason: nota?.trim().isNotEmpty == true
            ? '$reason: ${nota!.trim()}'
            : reason,
        date: DateTime.now().toIso8601String(),
        userId: usuarioId,
        compraOcasionalId: compraOcasionalId,
        categoria: categoriaOcasional,
      );
      await AuditLogWriter.record(
        txn,
        action: 'pago_cuenta_por_pagar',
        detail:
            'Cuenta $cuentaId; abono $monto; saldo ${(total - updatedPaid).clamp(0, double.infinity)}',
        userId: usuarioId,
      );
      return {
        'monto': monto,
        'motivo': reason,
        'compra_ocasional_id': compraOcasionalId,
      };
    });
  }

  @override
  Future<PayableBalance?> getBalance(int accountId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'CuentasPorPagar',
      columns: ['id', 'costo_total', 'monto_pagado', 'cuotas'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return PayableBalance(
      accountId: accountId,
      total: (row['costo_total'] as num).toDouble(),
      paid: (row['monto_pagado'] as num?)?.toDouble() ?? 0,
      installments: (row['cuotas'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  Future<void> registerPayment(PayablePayment payment) async {
    await aplicarPago(
      payment.accountId,
      payment.amount,
      metodoPago: payment.paymentMethod,
      nota: payment.note,
      usuarioId: payment.userId,
    );
  }

  Future<void> _recordPaymentFinancials(
    Transaction txn, {
    required int paymentId,
    required int payableId,
    required double amount,
    required String paymentMethod,
    required String reason,
    required String date,
    int? userId,
    int? compraOcasionalId,
    String? categoria,
  }) async {
    final sessions = _dateOnly(date) == _today()
        ? await txn.query(
            'SesionesCaja',
            where: "estado = 'abierta'",
            orderBy: 'id DESC',
            limit: 1,
          )
        : <Map<String, Object?>>[];
    final esOcasional = compraOcasionalId != null;
    final categoriaGasto = esOcasional ? (categoria ?? 'Otros') : 'Cuentas por Pagar';
    final descripcion = esOcasional
        ? 'Abono compra ocasional - $categoriaGasto: $reason'
        : 'Pago CxP $payableId: $reason';
    final gastoData = <String, Object?>{
      'fecha': date.split('T').first,
      'created_at': date.contains('T')
          ? date
          : DateTime.now().toIso8601String(),
      'categoria': categoriaGasto,
      'descripcion': descripcion,
      'monto': amount,
      'usuario_id': userId,
      'sesion_caja_id': sessions.isEmpty ? null : sessions.first['id'],
    };
    if (compraOcasionalId != null) {
      gastoData['compra_ocasional_id'] = compraOcasionalId;
    }
    final expenseId = await txn.insert('Gastos', gastoData);
    int? movementId;
    if (sessions.isNotEmpty) {
      movementId = await txn.insert('MovimientosCaja', {
        'sesion_caja_id': sessions.first['id'],
        'tipo': 'salida',
        'metodo_pago': paymentMethod,
        'monto': amount,
        'descripcion': descripcion,
        'fecha': date,
      });
    }
    await txn.update(
      'PagosCuentaPorPagar',
      {
        'gasto_id': expenseId,
        'movimiento_caja_id': movementId,
        'usuario_id': userId,
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(int payableId) async {
    final db = await _dbHelper.database;
    return db.query(
      'PagosCuentaPorPagar',
      where: 'cuenta_id = ?',
      whereArgs: [payableId],
      orderBy: 'fecha DESC, id DESC',
    );
  }

  void _validatePaymentMethod(String method) {
    final m = method.toLowerCase().trim();
    if (!{'efectivo', 'yape', 'plin', 'yape/plin'}.contains(m)) {
      throw Exception('El método de pago no es válido.');
    }
  }

  Future<int?> _openSessionIdFor(
    DatabaseExecutor txn,
    String date,
  ) async {
    final expenseDate = _dateOnly(date);
    if (expenseDate != _today()) return null;
    final sessions = await txn.query(
      'SesionesCaja',
      where: "estado = 'abierta'",
      orderBy: 'id DESC',
      limit: 1,
    );
    return sessions.isEmpty ? null : sessions.first['id'] as int;
  }

  String? _nullableText(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  String _dateOnly(String value) => value.split('T').first.split(' ').first;

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> getCuentasPorPagar() async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT c.*, COALESCE(i.nombre, a.nombre, c.motivo, 'Activo/Insumo') AS insumo_nombre,
             i.unidad_medida, COALESCE(c.proveedor, p.nombre) AS proveedor_nombre
      FROM CuentasPorPagar c
      LEFT JOIN Insumos i ON c.insumo_id = i.id AND c.insumo_id > 0
      LEFT JOIN ActivosFijos a ON a.id = c.activo_fijo_id
      LEFT JOIN Proveedores p ON p.id = c.proveedor_id
      ORDER BY c.pagado ASC, c.fecha DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getHistorialCompras() async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT a.id, a.id AS movimiento_id, a.fecha, a.insumo_id,
             COALESCE(cc.cantidad_nueva, a.cantidad_ajuste) AS cantidad_ajuste,
             a.tipo_adquisicion,
             COALESCE(cc.costo_unitario_nuevo, a.costo_unitario) AS costo_unitario,
             COALESCE(cc.motivo, a.motivo) AS motivo, a.usuario_id,
             COALESCE(i.nombre, a.motivo, 'Activo Fijo') AS insumo_nombre,
             COALESCE(i.unidad_medida, 'Und') AS unidad_medida,
             g.id AS gasto_id, c.id AS cuenta_id,
             COALESCE(c.proveedor, pc.nombre, pa.nombre) AS proveedor,
             COALESCE(c.proveedor_id, a.proveedor_id) AS proveedor_id,
             COALESCE(g.foto_recibo_ruta, c.factura_ruta) AS factura_ruta,
             CASE WHEN c.id IS NULL THEN 0 ELSE 1 END AS es_por_pagar,
             c.adelanto AS adelanto, c.cuotas AS cuotas,
             COALESCE(
               (SELECT mc.metodo_pago FROM MovimientosCaja mc WHERE mc.compra_movimiento_id = a.id LIMIT 1),
               'efectivo'
             ) AS metodo_pago
      FROM AjustesStock a
      LEFT JOIN CorreccionesCompra cc ON cc.id = (
        SELECT c2.id FROM CorreccionesCompra c2
        WHERE c2.compra_movimiento_id = a.id ORDER BY c2.id DESC LIMIT 1
      )
      LEFT JOIN Insumos i ON a.insumo_id = i.id
      LEFT JOIN Gastos g ON g.compra_movimiento_id = a.id
      LEFT JOIN CuentasPorPagar c ON c.compra_movimiento_id = a.id
      LEFT JOIN Proveedores pc ON pc.id = c.proveedor_id
      LEFT JOIN Proveedores pa ON pa.id = a.proveedor_id
      WHERE a.tipo_adquisicion = 'comprado'
      ORDER BY a.fecha DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getGastosHoy() async {
    final db = await _dbHelper.database;
    final today = _today();
    return db.rawQuery(
      '''
      SELECT g.id, g.categoria, g.descripcion, g.monto, g.created_at,
             i.nombre AS insumo_nombre, i.unidad_medida,
             a.cantidad_ajuste AS cantidad_compra
      FROM Gastos g
      LEFT JOIN Insumos i ON i.id = g.insumo_id
      LEFT JOIN AjustesStock a ON a.id = g.compra_movimiento_id
      WHERE substr(g.fecha, 1, 10) = ?
      ORDER BY g.created_at DESC, g.id DESC
      ''',
      [today],
    );
  }
}
