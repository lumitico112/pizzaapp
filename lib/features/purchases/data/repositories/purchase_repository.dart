import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';
import 'package:pizzaapp/core/database/audit_log_writer.dart';
import 'package:pizzaapp/features/purchases/domain/entities/payable_balance.dart';
import 'package:pizzaapp/features/purchases/domain/repositories/payable_repository.dart';

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
      final categoria = (gasto['categoria'] as String? ?? '').trim();
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

      final sesionId = gasto['sesion_caja_id'] as int?;
      final monto = (gasto['monto'] as num?)?.toDouble() ?? 0.0;
      final fecha = _dateOnly(gasto['fecha'] as String? ?? '');
      if (sesionId != null) {
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
          ORDER BY mc.id DESC
          LIMIT 1
          ''',
          [sesionId, monto, '$fecha%'],
        );
        if (candidates.isNotEmpty) {
          await txn.delete(
            'MovimientosCaja',
            where: 'id = ?',
            whereArgs: [candidates.first['id']],
          );
        }
      }
      await txn.delete('Gastos', where: 'id = ?', whereArgs: [gastoId]);
      await AuditLogWriter.record(
        txn,
        action: 'gasto_eliminado',
        detail: 'Gasto #$gastoId de S/ $monto eliminado.',
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
      );
      await AuditLogWriter.record(
        txn,
        action: 'pago_cuenta_por_pagar',
        detail:
            'Cuenta $cuentaId; abono $monto; saldo ${(total - updatedPaid).clamp(0, double.infinity)}',
        userId: usuarioId,
      );
      return {'monto': monto, 'motivo': reason};
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
  }) async {
    final sessions = _dateOnly(date) == _today()
        ? await txn.query(
            'SesionesCaja',
            where: "estado = 'abierta'",
            orderBy: 'id DESC',
            limit: 1,
          )
        : <Map<String, Object?>>[];
    final expenseId = await txn.insert('Gastos', {
      'fecha': date.split('T').first,
      'created_at': date.contains('T')
          ? date
          : DateTime.now().toIso8601String(),
      'categoria': 'Cuentas por Pagar',
      'descripcion': 'Pago CxP $payableId: $reason',
      'monto': amount,
      'usuario_id': userId,
      'sesion_caja_id': sessions.isEmpty ? null : sessions.first['id'],
    });
    int? movementId;
    if (sessions.isNotEmpty) {
      movementId = await txn.insert('MovimientosCaja', {
        'sesion_caja_id': sessions.first['id'],
        'tipo': 'salida',
        'metodo_pago': paymentMethod,
        'monto': amount,
        'descripcion': 'Pago CxP: $reason',
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
