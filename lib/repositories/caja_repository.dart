import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';
import 'package:pizzaapp/core/database/audit_log_writer.dart';

class CajaRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<SesionCaja?> getSesionActiva() async {
    final db = await dbHelper.database;
    final res = await db.query(
      'SesionesCaja',
      where: 'estado = ?',
      whereArgs: ['abierta'],
    );
    if (res.isEmpty) return null;
    return SesionCaja.fromMap(res.first);
  }

  Future<SesionCaja?> getUltimaSesionCerrada() async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'SesionesCaja',
      where: "estado = 'cerrada'",
      orderBy: 'fecha_cierre DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : SesionCaja.fromMap(rows.first);
  }

  Future<void> reabrirSesion({
    required int sesionId,
    required String motivo,
    required int usuarioId,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final active = await txn.query(
        'SesionesCaja',
        where: "estado = 'abierta'",
        limit: 1,
      );
      if (active.isNotEmpty) {
        throw Exception('Ya existe una caja abierta.');
      }
      final rows = await txn.query(
        'SesionesCaja',
        where: "id = ? AND estado = 'cerrada'",
        whereArgs: [sesionId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw Exception(
          'La sesión ya no está cerrada. Actualiza la pantalla e inténtalo de nuevo.',
        );
      }
      final session = SesionCaja.fromMap(rows.first);
      final now = DateTime.now().toIso8601String();
      final affected = await txn.update(
        'SesionesCaja',
        {
          'estado': 'abierta',
          'fecha_cierre': null,
          'total_efectivo_sistema': 0,
          'total_yape_plin': 0,
          'efectivo_contado': 0,
          'transferencias_contadas': 0,
          'diferencia_efectivo': 0,
          'diferencia_transferencia': 0,
          'diferencia': 0,
          'total_esperado': 0,
          'total_gastos': 0,
          'total_gastos_ciclo': 0,
          'nota': null,
          'usuario_cierre_id': null,
        },
        where: "id = ? AND estado = 'cerrada'",
        whereArgs: [sesionId],
      );
      if (affected != 1) throw Exception('La caja ya fue modificada.');
      await AuditLogWriter.record(
        txn,
        action: 'caja_reabierta_excepcionalmente',
        userId: usuarioId,
        detail:
            'Sesión $sesionId del ciclo iniciado ${session.fechaApertura}; autorización $now; motivo: ${motivo.trim()}; cierre previo ${session.fechaCierre}; diferencia previa ${session.diferencia.toStringAsFixed(2)}',
      );
    });
  }

  Future<int> crearSesion(SesionCaja sesion) async {
    final db = await dbHelper.database;
    return await db.insert('SesionesCaja', sesion.toMap());
  }

  Future<int> abrirSesion(
    SesionCaja sesion,
    MovimientoCaja? apertura, {
    required int? userId,
  }) async {
    final db = await dbHelper.database;
    return db.transaction((txn) async {
      final active = await txn.query(
        'SesionesCaja',
        where: "estado = 'abierta'",
        limit: 1,
      );
      if (active.isNotEmpty) {
        throw Exception('Ya hay una sesión de caja abierta.');
      }
      final id = await txn.insert('SesionesCaja', sesion.toMap());
      if (apertura != null) {
        await txn.insert('MovimientosCaja', {
          ...apertura.toMap(),
          'sesion_caja_id': id,
        });
      }
      final fechaApertura = sesion.fechaApertura.length >= 10
          ? sesion.fechaApertura.substring(0, 10)
          : sesion.fechaApertura;
      await txn.update(
        'Gastos',
        {'sesion_caja_id': id},
        where: 'sesion_caja_id IS NULL AND substr(fecha, 1, 10) = ?',
        whereArgs: [fechaApertura],
      );
      await AuditLogWriter.record(
        txn,
        action: 'caja_abierta',
        userId: userId,
        detail:
            'Sesión $id; fecha ${sesion.fechaApertura}; fondo inicial efectivo ${sesion.montoApertura.toStringAsFixed(2)}; saldo inicial Yape/Plin ${sesion.transferenciasApertura.toStringAsFixed(2)}',
      );
      return id;
    });
  }

  Future<void> actualizarSesion(SesionCaja sesion) async {
    final db = await dbHelper.database;
    await db.update(
      'SesionesCaja',
      sesion.toMap(),
      where: 'id = ?',
      whereArgs: [sesion.id],
    );
  }

  Future<CashCloseSummary> resumenSesion(SesionCaja sesion) async {
    final db = await dbHelper.database;
    final movimientos = await getMovimientos(sesion.id!);
    final gastosCiclo = await _gastosDelCiclo(db, sesion);
    final sales = await db.rawQuery(
      '''
      SELECT COALESCE(p.nombre, promo.nombre, 'Producto') AS producto,
             COALESCE(vp.nombre_variante, CASE WHEN dv.promocion_id IS NOT NULL THEN 'Promoción' ELSE 'Variante' END) AS variante,
             SUM(dv.cantidad) AS cantidad,
             SUM(CASE WHEN dv.es_cortesia = 1 THEN dv.cantidad ELSE 0 END) AS cortesia,
             SUM(dv.cantidad * dv.precio_unitario - COALESCE(dv.descuento, 0)) AS total
      FROM MovimientosCaja mc
      JOIN Ventas v ON v.id = COALESCE(mc.venta_id,
        CAST(REPLACE(mc.descripcion, 'Venta #', '') AS INTEGER))
      JOIN DetalleVenta dv ON dv.venta_id = v.id
      LEFT JOIN VariantesProducto vp ON vp.id = dv.variante_id
      LEFT JOIN Productos p ON p.id = vp.producto_id
      LEFT JOIN Promociones promo ON promo.id = dv.promocion_id
      WHERE mc.sesion_caja_id = ? AND mc.tipo IN ('venta', 'cortesia') AND v.anulada = 0
      GROUP BY COALESCE(p.nombre, promo.nombre, 'Producto'), vp.nombre_variante, dv.promocion_id
      ORDER BY producto, variante
    ''',
      [sesion.id],
    );
    final stockRows = await db.rawQuery('''
      SELECT p.nombre AS producto, vp.nombre_variante AS variante, vp.stock AS cantidad
      FROM VariantesProducto vp JOIN Productos p ON p.id = vp.producto_id
      WHERE COALESCE(vp.stock, 0) > 0
        AND p.activo = 1
        AND vp.active = 1
        AND vp.variante_base_id IS NULL
      ORDER BY p.nombre, vp.nombre_variante
    ''');
    return CashCloseSummary.calculate(
      sesion,
      movimientos,
      ventasPorProducto: sales
          .map(
            (row) => CashProductSale(
              productName: row['producto'] as String,
              variantName: row['variante'] as String,
              quantity: (row['cantidad'] as num?)?.toInt() ?? 0,
              courtesyQuantity: (row['cortesia'] as num?)?.toInt() ?? 0,
              total: (row['total'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
      preparadosRestantes: stockRows
          .map(
            (row) => PreparedStockBalance(
              productName: row['producto'] as String,
              variantName: row['variante'] as String,
              quantity: (row['cantidad'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(),
      gastosDelCiclo: gastosCiclo,
    );
  }

  Future<double> _gastosDelCiclo(
    DatabaseExecutor executor,
    SesionCaja sesion,
  ) async {
    if (sesion.id == null) return 0;
    final rows = await executor.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS total FROM Gastos WHERE sesion_caja_id = ?',
      [sesion.id],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<SesionCaja> cerrarSesion({
    required int sesionId,
    required double efectivoContado,
    required double transferenciasContadas,
    required String nota,
    required int? usuarioId,
  }) async {
    final db = await dbHelper.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'SesionesCaja',
        where: 'id = ?',
        whereArgs: [sesionId],
        limit: 1,
      );
      if (rows.isEmpty || rows.first['estado'] != 'abierta') {
        throw Exception(
          'La caja ya fue cerrada o no existe una sesión abierta.',
        );
      }
      final session = SesionCaja.fromMap(rows.first);
      final movementRows = await txn.query(
        'MovimientosCaja',
        where: 'sesion_caja_id = ?',
        whereArgs: [sesionId],
      );
      final summary = CashCloseSummary.calculate(
        session,
        movementRows.map((row) => MovimientoCaja.fromMap(row)),
        gastosDelCiclo: await _gastosDelCiclo(txn, session),
      );
      final diffCash = efectivoContado - summary.efectivoEsperado;
      final diffTransfer =
          transferenciasContadas - summary.transferenciasEsperadas;
      final diffTotal = diffCash + diffTransfer;
      final closeTimestamp = DateTime.now().toIso8601String();
      final closed = SesionCaja(
        id: session.id,
        fechaApertura: session.fechaApertura,
        montoApertura: session.montoApertura,
        transferenciasApertura: session.transferenciasApertura,
        estado: 'cerrada',
        fechaCierre: closeTimestamp,
        totalEfectivoSistema: summary.efectivoEsperado,
        totalYapePlin: summary.transferenciasEsperadas,
        efectivoContado: efectivoContado,
        transferenciasContadas: transferenciasContadas,
        diferenciaEfectivo: diffCash,
        diferenciaTransferencia: diffTransfer,
        diferencia: diffTotal,
        totalEsperado:
            summary.efectivoEsperado + summary.transferenciasEsperadas,
        totalGastos: summary.gastos,
        totalGastosCiclo: summary.gastosDelCiclo,
        nota: nota.trim().isEmpty ? null : nota.trim(),
        usuarioAperturaId: session.usuarioAperturaId,
        usuarioCierreId: usuarioId,
      );
      final affected = await txn.update(
        'SesionesCaja',
        closed.toMap(),
        where: "id = ? AND estado = 'abierta'",
        whereArgs: [sesionId],
      );
      if (affected != 1) throw Exception('La caja ya fue cerrada.');

      // Si quedaron productos con stock al cerrar caja y no tienen fila en
      // ItemsPreparacion para hoy, registrarlos como pendientes de decisión
      // para que al abrir el siguiente ciclo y entrar a Preparación aparezca el modal.
      final closeDate = closeTimestamp.split('T').first;
      final leftoverVars = await txn.rawQuery('''
        SELECT vp.id AS variante_id, COALESCE(vp.stock, 0) AS stock
        FROM VariantesProducto vp
        JOIN Productos p ON p.id = vp.producto_id
        WHERE COALESCE(vp.stock, 0) > 0
          AND p.activo = 1
          AND vp.active = 1
          AND vp.variante_base_id IS NULL
      ''');
      if (leftoverVars.isNotEmpty) {
        final prepRows = await txn.query(
          'PreparacionDiaria',
          where: 'fecha = ?',
          whereArgs: [closeDate],
          limit: 1,
        );
        final prepId = prepRows.isEmpty
            ? await txn.insert('PreparacionDiaria', {
                'fecha': closeDate,
                'nota': 'Stock al cierre de caja #$sesionId',
                'created_at': closeTimestamp,
              })
            : prepRows.first['id'] as int;
        for (final row in leftoverVars) {
          final vid = row['variante_id'] as int;
          final stock = (row['stock'] as num).toInt();

          // Si el producto ya fue gestionado en este cierre de caja (resuelto = 1), no marcarlo como no resuelto.
          final resolvedRecently = await txn.rawQuery(
            '''
            SELECT ip.id
            FROM ItemsPreparacion ip
            JOIN PreparacionDiaria p ON p.id = ip.preparacion_id
            WHERE ip.variante_id = ?
              AND COALESCE(ip.resuelto, 0) = 1
              AND (p.fecha = ? OR p.fecha = date(?, '+1 day'))
            LIMIT 1
            ''',
            [vid, closeDate, closeDate],
          );
          if (resolvedRecently.isNotEmpty) continue;

          final existingItems = await txn.query(
            'ItemsPreparacion',
            where: 'preparacion_id = ? AND variante_id = ?',
            whereArgs: [prepId, vid],
            limit: 1,
          );
          if (existingItems.isEmpty) {
            await txn.insert('ItemsPreparacion', {
              'preparacion_id': prepId,
              'variante_id': vid,
              'cantidad_preparada': stock,
              'enviado_merma': 0,
              'llevado_manana': 0,
              'sobrante': 0,
              'resuelto': 0,
              'notas': 'Sobrante al cierre de caja #$sesionId',
            });
          }
        }
      }

      await AuditLogWriter.record(
        txn,
        action: 'caja_cerrada',
        userId: usuarioId,
        detail:
            'Sesión $sesionId; apertura ${session.fechaApertura}; cierre ${closed.fechaCierre}; esperado efectivo ${summary.efectivoEsperado.toStringAsFixed(2)}; contado ${efectivoContado.toStringAsFixed(2)}; esperado Yape/Plin ${summary.transferenciasEsperadas.toStringAsFixed(2)}; contado ${transferenciasContadas.toStringAsFixed(2)}; diferencia ${diffTotal.toStringAsFixed(2)}; nota ${closed.nota ?? "-"}',
      );
      return closed;
    });
  }

  Future<int> insertMovimiento(MovimientoCaja mov) async {
    final db = await dbHelper.database;
    return db.transaction((txn) async {
      final sessions = await txn.query(
        'SesionesCaja',
        where: "id = ? AND estado = 'abierta'",
        whereArgs: [mov.sesionCajaId],
        limit: 1,
      );
      if (sessions.isEmpty) {
        throw Exception(
          'No se puede registrar un movimiento: la caja no está abierta.',
        );
      }
      return txn.insert('MovimientosCaja', mov.toMap());
    });
  }

  Future<void> registrarMovimientoManual(
    MovimientoCaja movimiento, {
    required int? userId,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'SesionesCaja',
        where: "id = ? AND estado = 'abierta'",
        whereArgs: [movimiento.sesionCajaId],
        limit: 1,
      );
      if (rows.isEmpty) throw Exception('La caja ya no está abierta.');
      await txn.insert('MovimientosCaja', movimiento.toMap());
      if (movimiento.tipo == 'salida') {
        await txn.insert('Gastos', {
          'fecha': movimiento.fecha.split('T').first,
          'created_at': movimiento.fecha,
          'categoria': 'Salida Manual de Caja',
          'monto': movimiento.monto,
          'descripcion': movimiento.descripcion,
          'usuario_id': userId,
          'sesion_caja_id': movimiento.sesionCajaId,
        });
      }
      await AuditLogWriter.record(
        txn,
        action: movimiento.tipo == 'salida'
            ? 'caja_gasto_manual'
            : 'caja_entrada_manual',
        userId: userId,
        detail:
            'Sesión ${movimiento.sesionCajaId}; monto ${movimiento.monto.toStringAsFixed(2)}; medio ${movimiento.metodoPago}; descripción ${movimiento.descripcion ?? "-"}',
      );
    });
  }

  Future<List<MovimientoCaja>> getMovimientos(int sesionId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'MovimientosCaja',
      where: 'sesion_caja_id = ?',
      whereArgs: [sesionId],
    );
    return res.map((m) => MovimientoCaja.fromMap(m)).toList();
  }
}
