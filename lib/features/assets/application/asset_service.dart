import 'package:pizzaapp/features/assets/domain/entities/asset.dart';
import 'package:pizzaapp/features/assets/data/repositories/asset_repository.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/database/audit_log_writer.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:pizzaapp/features/assets/domain/rules/asset_acquisition_rules.dart';

class ActivoFijoService {
  final ActivoFijoRepository _repository;
  final AuthService _authService;

  ActivoFijoService(this._repository, this._authService);

  Future<List<ActivoFijo>> obtenerTodos() async {
    return await _repository.getAll();
  }

  Future<void> registrarActivo(ActivoFijo activo, [double adelanto = 0]) async {
    _validateAsset(activo, adelanto);
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      final map = activo.toMap();
      map.remove('id');
      final activoId = await txn.insert('ActivosFijos', map);
      final userId = _authService.currentUser?.id;
      final when = activo.fechaAdquisicion ?? DateTime.now().toIso8601String();
      if (activo.condicion == 'Comprado') {
        if (activo.metodoPago == 'Contado') {
          await _recordAssetExpense(
            txn,
            date: when,
            assetId: activoId,
            amount: activo.costo,
            description: 'Compra de activo: ${activo.nombre}',
            userId: userId,
          );
        } else if (activo.metodoPago == 'Crédito' ||
            activo.metodoPago.contains('Cr')) {
          final payableId = await txn.insert('CuentasPorPagar', {
            'fecha': when,
            'insumo_id': null,
            'cantidad': activo.cantidad,
            'costo_total': activo.costo,
            'monto_pagado': adelanto,
            'adelanto': adelanto,
            'cuotas': activo.cuotas,
            'proveedor': 'Proveedor de ${activo.nombre}',
            'motivo': 'Activo: ${activo.nombre}',
            'pagado': adelanto >= activo.costo ? 1 : 0,
            'fecha_pago': adelanto >= activo.costo ? when : null,
            'activo_fijo_id': activoId,
          });
          if (adelanto > 0) {
            final paymentId = await txn.insert('PagosCuentaPorPagar', {
              'cuenta_id': payableId,
              'fecha': when,
              'monto': adelanto,
              'metodo_pago': 'efectivo',
              'nota': 'Adelanto de activo fijo',
              'usuario_id': userId,
            });
            await _recordAssetExpense(
              txn,
              date: when,
              assetId: activoId,
              amount: adelanto,
              description: 'Adelanto de activo: ${activo.nombre}',
              userId: userId,
              paymentId: paymentId,
            );
          }
        }
      } else if (activo.condicion == 'Alquilado' && activo.costo > 0) {
        await _recordAssetExpense(
          txn,
          date: when,
          assetId: activoId,
          amount: activo.costo,
          description: 'Alquiler de activo: ${activo.nombre}',
          userId: userId,
        );
      }
      await AuditLogWriter.record(
        txn,
        action: 'activo_registrado',
        detail:
            'Activo $activoId: ${activo.nombre}; adquisición ${activo.condicion}; costo ${activo.costo}; unidades ${activo.cantidad}',
        userId: userId,
      );
    });
  }

  Future<void> actualizarActivo(ActivoFijo activo) async {
    _validateAsset(activo, 0, forUpdate: true);
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final changed = await txn.update(
        'ActivosFijos',
        activo.toMap(),
        where: 'id = ?',
        whereArgs: [activo.id],
      );
      if (changed == 0) {
        throw Exception('El activo ya no existe.');
      }
      await AuditLogWriter.record(
        txn,
        action: 'activo_actualizado',
        detail:
            'Activo ${activo.id}: ${activo.nombre}; estado ${activo.estado}',
        userId: _authService.currentUser?.id,
      );
    });
  }

  Future<void> eliminarActivo(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final changed = await txn.update(
        'ActivosFijos',
        {'activo': 0},
        where: 'id = ? AND activo = 1',
        whereArgs: [id],
      );
      if (changed == 0) {
        throw Exception('El activo no existe o ya fue dado de baja.');
      }
      await AuditLogWriter.record(
        txn,
        action: 'activo_dado_de_baja',
        detail: 'Activo $id',
        userId: _authService.currentUser?.id,
      );
    });
  }

  double calcularTotalInvertido(List<ActivoFijo> activos) {
    return activos
        .where(
          (item) => AssetAcquisitionRules.countsAsInvestment(item.condicion),
        )
        .fold(0, (sum, item) => sum + item.costo);
  }

  Future<void> registrarGastoReparacion(
    ActivoFijo activo,
    double costo,
    String descripcion,
  ) async {
    if (costo <= 0) {
      throw Exception('Costo inválido');
    }
    if (activo.id == null) {
      throw Exception('Guarda el activo antes de registrar una reparación.');
    }
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final expenseId = await txn.insert('Gastos', {
        'fecha': now.split('T').first,
        'created_at': now,
        'categoria': 'Mantenimiento/Reparación',
        'monto': costo,
        'descripcion': 'Reparación de activo [${activo.nombre}]: $descripcion',
        'usuario_id': _authService.currentUser?.id,
      });
      final sessions = await txn.query(
        'SesionesCaja',
        where: "estado = 'abierta'",
        orderBy: 'id DESC',
        limit: 1,
      );
      if (sessions.isNotEmpty) {
        await txn.update(
          'Gastos',
          {'sesion_caja_id': sessions.first['id']},
          where: 'id = ?',
          whereArgs: [expenseId],
        );
        await txn.insert('MovimientosCaja', {
          'sesion_caja_id': sessions.first['id'],
          'tipo': 'salida',
          'metodo_pago': 'efectivo',
          'monto': costo,
          'descripcion': 'Reparación: ${activo.nombre}',
          'fecha': now,
        });
      }
      final changed = await txn.update(
        'ActivosFijos',
        {'estado': 'En reparación'},
        where: 'id = ? AND activo = 1',
        whereArgs: [activo.id],
      );
      if (changed == 0) {
        throw Exception('El activo no existe o ya fue dado de baja.');
      }
      await AuditLogWriter.record(
        txn,
        action: 'activo_reparacion_registrada',
        detail: 'Activo ${activo.id}; costo $costo; $descripcion',
        userId: _authService.currentUser?.id,
      );
    });
  }

  void _validateAsset(
    ActivoFijo asset,
    double advance, {
    bool forUpdate = false,
  }) {
    AssetAcquisitionRules.validate(
      name: asset.nombre,
      condition: asset.condicion,
      paymentMethod: asset.metodoPago,
      totalCost: asset.costo,
      quantity: asset.cantidad,
      installments: asset.cuotas,
      advance: advance,
      forUpdate: forUpdate,
    );
  }

  Future<void> _recordAssetExpense(
    Transaction txn, {
    required String date,
    required int assetId,
    required double amount,
    required String description,
    required int? userId,
    int? paymentId,
  }) async {
    final expenseId = await txn.insert('Gastos', {
      'fecha': date.split('T').first,
        'created_at': date.contains('T')
            ? date
            : DateTime.now().toIso8601String(),
      'categoria': 'Activos Fijos',
      'monto': amount,
      'descripcion': description,
      'activo_fijo_id': assetId,
      'usuario_id': userId,
    });
    final expenseDate = date.split('T').first.split(' ').first;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final sessions = expenseDate == today
        ? await txn.query(
            'SesionesCaja',
            where: "estado = 'abierta'",
            orderBy: 'id DESC',
            limit: 1,
          )
        : <Map<String, Object?>>[];
    int? movementId;
    if (sessions.isNotEmpty) {
      await txn.update(
        'Gastos',
        {'sesion_caja_id': sessions.first['id']},
        where: 'id = ?',
        whereArgs: [expenseId],
      );
      movementId = await txn.insert('MovimientosCaja', {
        'sesion_caja_id': sessions.first['id'],
        'tipo': 'salida',
        'metodo_pago': 'efectivo',
        'monto': amount,
        'descripcion': description,
        'fecha': date,
      });
    }
    if (paymentId != null) {
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
  }
}
