import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/features/purchases/domain/entities/compra_ocasional.dart';
import 'package:pizzaapp/features/purchases/domain/rules/occasional_purchase_rules.dart';
import 'package:pizzaapp/features/reporting/data/repositories/reportes_repository.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

String _soloFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

String _hoy() => _soloFecha(DateTime.now());

String _manana() => _soloFecha(DateTime.now().add(const Duration(days: 1)));

CompraOcasional _ocasional({
  int? id,
  bool esPorPagar = false,
  double adelanto = 0,
  double total = 50,
  double cantidad = 1,
  String descripcion = 'Fósforos',
  String categoria = 'Insumos',
  String? fecha,
  int cuotas = 1,
  String metodoPago = 'efectivo',
  String? proveedor = 'Bodega central',
}) {
  return CompraOcasional(
    id: id,
    fecha: fecha ?? DateTime.now().toIso8601String(),
    descripcion: descripcion,
    cantidad: cantidad,
    unidadMedida: 'caja',
    costoTotal: total,
    categoria: categoria,
    proveedor: proveedor,
    esPorPagar: esPorPagar,
    adelanto: adelanto,
    cuotas: cuotas,
    metodoPago: metodoPago,
  );
}

Future<int> _abrirSesion(Database db) {
  return db.insert('SesionesCaja', {
    'fecha_apertura': DateTime.now().toIso8601String(),
    'monto_apertura': 100.0,
    'transferencias_apertura': 10.0,
    'estado': 'abierta',
  });
}

Future<int> _crearInsumo(Database db) {
  return db.insert('Insumos', {
    'nombre': 'Queso mozzarella',
    'unidad_medida': 'kg',
    'costo_por_unidad': 20.0,
    'stock_actual': 10.0,
  });
}

void main() {
  late Database db;
  late PurchaseRepository repo;
  late ReportesRepository reportes;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
    repo = PurchaseRepository();
    reportes = ReportesRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  test(
    'contado con caja abierta crea cabecera, gasto y salida de caja sin stock',
    () async {
      final sesionId = await _abrirSesion(db);
      final insumoId = await _crearInsumo(db);
      final stockAntes = (await db.query(
        'Insumos',
        where: 'id = ?',
        whereArgs: [insumoId],
      )).single['stock_actual'];

      final compraId = await repo.registrarCompraOcasional(
        _ocasional(descripcion: 'Fósforos', total: 35, fecha: _hoy()),
      );

      final cabecera = (await db.query(
        'ComprasOcasionales',
        where: 'id = ?',
        whereArgs: [compraId],
      )).single;
      expect(cabecera['es_por_pagar'], 0);
      expect((cabecera['costo_total'] as num).toDouble(), 35.0);
      expect(cabecera['proveedor'], 'Bodega central');

      final gasto = (await db.query('Gastos')).single;
      expect(gasto['compra_ocasional_id'], compraId);
      expect(gasto['insumo_id'], isNull);
      expect(gasto['sesion_caja_id'], sesionId);
      expect((gasto['monto'] as num).toDouble(), 35.0);
      expect(gasto['categoria'], 'Insumos');
      expect(gasto['descripcion'], contains('Compra ocasional'));
      expect(gasto['movimiento_caja_id'], isNotNull);

      final movimiento = (await db.query('MovimientosCaja')).single;
      expect(movimiento['tipo'], 'salida');
      expect(movimiento['sesion_caja_id'], sesionId);
      expect(movimiento['metodo_pago'], 'efectivo');
      expect((movimiento['monto'] as num).toDouble(), 35.0);

      expect(await db.query('AjustesStock'), isEmpty);
      expect(await db.query('CuentasPorPagar'), isEmpty);
      final stockDespues = (await db.query(
        'Insumos',
        where: 'id = ?',
        whereArgs: [insumoId],
      )).single['stock_actual'];
      expect(stockDespues, stockAntes);

      final auditoria = await db.query(
        'LogAuditoria',
        where: 'accion = ?',
        whereArgs: ['compra_ocasional_registrada'],
      );
      expect(auditoria, hasLength(1));
    },
  );

  test(
    'contado sin caja abierta registra gasto pero no movimiento de caja',
    () async {
      final compraId = await repo.registrarCompraOcasional(
        _ocasional(total: 22, fecha: _hoy()),
      );

      final gasto = (await db.query('Gastos')).single;
      expect(gasto['compra_ocasional_id'], compraId);
      expect(gasto['sesion_caja_id'], isNull);
      expect(gasto['movimiento_caja_id'], isNull);
      expect(await db.query('MovimientosCaja'), isEmpty);
    },
  );

  test(
    'crédito sin adelanto crea CxP ocasional sin gasto ni movimiento',
    () async {
      final compraId = await repo.registrarCompraOcasional(
        _ocasional(esPorPagar: true, total: 100, cuotas: 3, fecha: _hoy()),
      );

      final cuenta = (await db.query('CuentasPorPagar')).single;
      expect(cuenta['compra_ocasional_id'], compraId);
      expect(cuenta['insumo_id'], isNull);
      expect(cuenta['activo_fijo_id'], isNull);
      expect(cuenta['compra_movimiento_id'], isNull);
      expect((cuenta['monto_pagado'] as num).toDouble(), 0.0);
      expect((cuenta['adelanto'] as num).toDouble(), 0.0);
      expect(cuenta['pagado'], 0);
      expect(cuenta['motivo'], contains('Compra ocasional'));

      expect(await db.query('Gastos'), isEmpty);
      expect(await db.query('MovimientosCaja'), isEmpty);
      expect(await db.query('PagosCuentaPorPagar'), isEmpty);
      expect(await db.query('AjustesStock'), isEmpty);
    },
  );

  test(
    'crédito con adelanto crea exactamente un pago, gasto y movimiento',
    () async {
      final sesionId = await _abrirSesion(db);
      final compraId = await repo.registrarCompraOcasional(
        _ocasional(
          esPorPagar: true,
          adelanto: 30,
          total: 100,
          cuotas: 2,
          metodoPago: 'yape',
          fecha: _hoy(),
        ),
      );

      final cuenta = (await db.query('CuentasPorPagar')).single;
      expect(cuenta['compra_ocasional_id'], compraId);
      expect((cuenta['monto_pagado'] as num).toDouble(), 30.0);
      expect((cuenta['adelanto'] as num).toDouble(), 30.0);

      final pago = (await db.query('PagosCuentaPorPagar')).single;
      expect(pago['nota'], 'Adelanto de compra');
      expect((pago['monto'] as num).toDouble(), 30.0);
      expect(pago['gasto_id'], isNotNull);
      expect(pago['movimiento_caja_id'], isNotNull);

      final gasto = (await db.query('Gastos')).single;
      expect(gasto['compra_ocasional_id'], compraId);
      expect(gasto['sesion_caja_id'], sesionId);
      expect((gasto['monto'] as num).toDouble(), 30.0);
      expect(gasto['compra_movimiento_id'], isNull);

      final movimiento = (await db.query('MovimientosCaja')).single;
      expect(movimiento['tipo'], 'salida');
      expect(movimiento['metodo_pago'], 'yape');
      expect((movimiento['monto'] as num).toDouble(), 30.0);
      expect(await db.query('AjustesStock'), isEmpty);
    },
  );

  test(
    'un abono posterior actualiza saldo y crea un gasto/movimiento ocasional',
    () async {
      final sesionId = await _abrirSesion(db);
      final compraId = await repo.registrarCompraOcasional(
        _ocasional(esPorPagar: true, total: 100, fecha: _hoy()),
      );
      final cuentaId = (await db.query('CuentasPorPagar')).single['id'] as int;

      await repo.aplicarPago(
        cuentaId,
        40,
        metodoPago: 'yape/plin',
        nota: 'Cuota 1',
      );

      final cuenta = (await db.query(
        'CuentasPorPagar',
        where: 'id = ?',
        whereArgs: [cuentaId],
      )).single;
      expect((cuenta['monto_pagado'] as num).toDouble(), 40.0);

      final pago = (await db.query('PagosCuentaPorPagar')).single;
      expect((pago['monto'] as num).toDouble(), 40.0);
      expect(pago['gasto_id'], isNotNull);
      expect(pago['movimiento_caja_id'], isNotNull);

      final gasto = (await db.query('Gastos')).single;
      expect(gasto['compra_ocasional_id'], compraId);
      expect(gasto['categoria'], 'Insumos');
      expect(gasto['descripcion'], contains('Abono compra ocasional'));

      final movimiento = (await db.query('MovimientosCaja')).single;
      expect(movimiento['tipo'], 'salida');
      expect(movimiento['sesion_caja_id'], sesionId);
      expect((movimiento['monto'] as num).toDouble(), 40.0);
    },
  );

  test('editar una compra con abonos recalcula el saldo y rechaza un total menor al pagado', () async {
    final sesionId = await _abrirSesion(db);
    final fecha = DateTime.now().toIso8601String();
    final compraId = await repo.registrarCompraOcasional(
      _ocasional(esPorPagar: true, adelanto: 20, total: 100, fecha: fecha),
    );
    final cuentaId = (await db.query('CuentasPorPagar')).single['id'] as int;
    await repo.aplicarPago(cuentaId, 30, metodoPago: 'efectivo');

    expect(await db.query('PagosCuentaPorPagar'), hasLength(2));
    expect(await db.query('Gastos'), hasLength(2));
    expect(await db.query('MovimientosCaja'), hasLength(2));

    await repo.corregirCompraOcasional(
      _ocasional(
        id: compraId,
        esPorPagar: true,
        adelanto: 20,
        total: 80,
        cuotas: 2,
        fecha: fecha,
      ),
    );

    final cuenta = (await db.query(
      'CuentasPorPagar',
      where: 'id = ?',
      whereArgs: [cuentaId],
    )).single;
    expect((cuenta['costo_total'] as num).toDouble(), 80.0);
    expect((cuenta['monto_pagado'] as num).toDouble(), 50.0);
    expect((cuenta['adelanto'] as num).toDouble(), 20.0);
    expect(cuenta['pagado'], 0);
    expect(await db.query('PagosCuentaPorPagar'), hasLength(2));
    expect(await db.query('Gastos'), hasLength(2));
    expect(await db.query('MovimientosCaja'), hasLength(2));

    await expectLater(
      () => repo.corregirCompraOcasional(
        _ocasional(
          id: compraId,
          esPorPagar: true,
          adelanto: 20,
          total: 40,
          cuotas: 2,
          fecha: fecha,
        ),
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('no puede ser menor al monto ya abonado'),
        ),
      ),
    );

    final cuentaSinCambios = (await db.query(
      'CuentasPorPagar',
      where: 'id = ?',
      whereArgs: [cuentaId],
    )).single;
    expect((cuentaSinCambios['costo_total'] as num).toDouble(), 80.0);
    expect(await db.query('PagosCuentaPorPagar'), hasLength(2));
    expect(await db.query('Gastos'), hasLength(2));
    expect(await db.query('MovimientosCaja'), hasLength(2));
    expect(sesionId, isNotNull);
  });

  test(
    'editar el adelanto actualiza por ID y crea o elimina el pago sin duplicar',
    () async {
      await _abrirSesion(db);
      final fecha = DateTime.now().toIso8601String();
      final compraId = await repo.registrarCompraOcasional(
        _ocasional(esPorPagar: true, adelanto: 20, total: 100, fecha: fecha),
      );
      final cuentaId = (await db.query('CuentasPorPagar')).single['id'] as int;
      final pagoOriginal = (await db.query('PagosCuentaPorPagar')).single;
      final gastoOriginal = (await db.query('Gastos')).single;
      final movimientoOriginal = (await db.query('MovimientosCaja')).single;

      await repo.corregirCompraOcasional(
        _ocasional(
          id: compraId,
          esPorPagar: true,
          adelanto: 50,
          total: 100,
          cuotas: 3,
          fecha: fecha,
        ),
      );

      final pagoEditado = (await db.query('PagosCuentaPorPagar')).single;
      final gastoEditado = (await db.query('Gastos')).single;
      final movimientoEditado = (await db.query('MovimientosCaja')).single;
      expect(pagoEditado['id'], pagoOriginal['id']);
      expect(gastoEditado['id'], gastoOriginal['id']);
      expect(movimientoEditado['id'], movimientoOriginal['id']);
      expect((pagoEditado['monto'] as num).toDouble(), 50.0);
      expect((gastoEditado['monto'] as num).toDouble(), 50.0);
      expect((movimientoEditado['monto'] as num).toDouble(), 50.0);

      final cuenta = (await db.query(
        'CuentasPorPagar',
        where: 'id = ?',
        whereArgs: [cuentaId],
      )).single;
      expect((cuenta['monto_pagado'] as num).toDouble(), 50.0);
      expect((cuenta['adelanto'] as num).toDouble(), 50.0);

      await repo.corregirCompraOcasional(
        _ocasional(
          id: compraId,
          esPorPagar: true,
          adelanto: 0,
          total: 100,
          cuotas: 1,
          fecha: fecha,
        ),
      );
      expect(await db.query('PagosCuentaPorPagar'), isEmpty);
      expect(await db.query('Gastos'), isEmpty);
      expect(await db.query('MovimientosCaja'), isEmpty);
      final cuentaSinAdelanto = (await db.query(
        'CuentasPorPagar',
        where: 'id = ?',
        whereArgs: [cuentaId],
      )).single;
      expect((cuentaSinAdelanto['monto_pagado'] as num).toDouble(), 0.0);
      expect((cuentaSinAdelanto['adelanto'] as num).toDouble(), 0.0);

      final compraCreditoId = await repo.registrarCompraOcasional(
        _ocasional(esPorPagar: true, total: 60, fecha: fecha),
      );
      final cuentaCreditoId =
          (await db.query(
                'CuentasPorPagar',
                where: 'compra_ocasional_id = ?',
                whereArgs: [compraCreditoId],
              )).single['id']
              as int;
      await repo.corregirCompraOcasional(
        _ocasional(
          id: compraCreditoId,
          esPorPagar: true,
          adelanto: 15,
          total: 60,
          fecha: fecha,
        ),
      );
      expect(await db.query('PagosCuentaPorPagar'), hasLength(1));
      expect(await db.query('Gastos'), hasLength(1));
      expect(await db.query('MovimientosCaja'), hasLength(1));
      final cuentaCredito = (await db.query(
        'CuentasPorPagar',
        where: 'id = ?',
        whereArgs: [cuentaCreditoId],
      )).single;
      expect((cuentaCredito['monto_pagado'] as num).toDouble(), 15.0);
    },
  );

  test('editar el adelanto sin caja abierta desvincula el movimiento sin romper la FK', () async {
    final sesionId = await _abrirSesion(db);
    final fecha = DateTime.now().toIso8601String();
    final compraId = await repo.registrarCompraOcasional(
      _ocasional(esPorPagar: true, adelanto: 20, total: 100, fecha: fecha),
    );
    expect(await db.query('MovimientosCaja'), hasLength(1));

    await db.update(
      'SesionesCaja',
      {'estado': 'cerrada', 'fecha_cierre': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sesionId],
    );

    await repo.corregirCompraOcasional(
      _ocasional(
        id: compraId,
        esPorPagar: true,
        adelanto: 30,
        total: 100,
        fecha: fecha,
      ),
    );

    expect(await db.query('MovimientosCaja'), isEmpty);
    final gasto = (await db.query('Gastos')).single;
    expect((gasto['monto'] as num).toDouble(), 30.0);
    expect(gasto['sesion_caja_id'], isNull);
    final pago = (await db.query('PagosCuentaPorPagar')).single;
    expect((pago['monto'] as num).toDouble(), 30.0);
    expect(pago['movimiento_caja_id'], isNull);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test(
    'eliminar compras ocasionales de contado y crédito borra sus hijos por ID',
    () async {
      await _abrirSesion(db);
      final cashId = await repo.registrarCompraOcasional(
        _ocasional(total: 30, fecha: _hoy()),
      );
      final cashGasto = (await db.query(
        'Gastos',
        where: 'compra_ocasional_id = ?',
        whereArgs: [cashId],
      )).single;
      final cashMovimientoId = cashGasto['movimiento_caja_id'] as int;

      final creditId = await repo.registrarCompraOcasional(
        _ocasional(esPorPagar: true, adelanto: 25, total: 100, fecha: _hoy()),
      );
      final cuentaId =
          (await db.query(
                'CuentasPorPagar',
                where: 'compra_ocasional_id = ?',
                whereArgs: [creditId],
              )).single['id']
              as int;
      await repo.aplicarPago(cuentaId, 20, metodoPago: 'efectivo');
      final creditPagos = await db.query(
        'PagosCuentaPorPagar',
        where: 'cuenta_id = ?',
        whereArgs: [cuentaId],
      );
      final creditGastos = await db.query(
        'Gastos',
        where: 'compra_ocasional_id = ?',
        whereArgs: [creditId],
      );
      final creditMovimientos = creditPagos
          .map((p) => p['movimiento_caja_id'] as int?)
          .whereType<int>()
          .toSet();

      await repo.eliminarCompraOcasional(cashId);
      expect(
        await db.query(
          'ComprasOcasionales',
          where: 'id = ?',
          whereArgs: [cashId],
        ),
        isEmpty,
      );
      expect(
        await db.query(
          'Gastos',
          where: 'compra_ocasional_id = ?',
          whereArgs: [cashId],
        ),
        isEmpty,
      );
      expect(
        await db.query(
          'MovimientosCaja',
          where: 'id = ?',
          whereArgs: [cashMovimientoId],
        ),
        isEmpty,
      );

      await repo.eliminarCompraOcasional(creditId);
      expect(
        await db.query(
          'ComprasOcasionales',
          where: 'id = ?',
          whereArgs: [creditId],
        ),
        isEmpty,
      );
      expect(
        await db.query(
          'CuentasPorPagar',
          where: 'id = ?',
          whereArgs: [cuentaId],
        ),
        isEmpty,
      );
      expect(
        await db.query(
          'PagosCuentaPorPagar',
          where: 'cuenta_id = ?',
          whereArgs: [cuentaId],
        ),
        isEmpty,
      );
      for (final gasto in creditGastos) {
        expect(
          await db.query('Gastos', where: 'id = ?', whereArgs: [gasto['id']]),
          isEmpty,
        );
      }
      for (final movimientoId in creditMovimientos) {
        expect(
          await db.query(
            'MovimientosCaja',
            where: 'id = ?',
            whereArgs: [movimientoId],
          ),
          isEmpty,
        );
      }

      final auditoria = await db.query(
        'LogAuditoria',
        where: 'accion = ?',
        whereArgs: ['compra_ocasional_eliminada'],
      );
      expect(auditoria, hasLength(2));
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  test(
    'eliminarGasto bloquea un gasto vinculado a una compra ocasional',
    () async {
      await _abrirSesion(db);
      final compraId = await repo.registrarCompraOcasional(
        _ocasional(total: 18, fecha: _hoy()),
      );
      final gastoId =
          (await db.query(
                'Gastos',
                where: 'compra_ocasional_id = ?',
                whereArgs: [compraId],
              )).single['id']
              as int;

      await expectLater(
        () => repo.eliminarGasto(gastoId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('compra ocasional'),
          ),
        ),
      );
      expect(
        await db.query('Gastos', where: 'id = ?', whereArgs: [gastoId]),
        hasLength(1),
      );
      expect(
        await db.query(
          'ComprasOcasionales',
          where: 'id = ?',
          whereArgs: [compraId],
        ),
        hasLength(1),
      );
    },
  );

  test('anular el adelanto ocasional revierte pago, gasto y movimiento y conserva la cabecera', () async {
    await _abrirSesion(db);
    final compraId = await repo.registrarCompraOcasional(
      _ocasional(esPorPagar: true, adelanto: 20, total: 100, fecha: _hoy()),
    );
    final cuentaId = (await db.query('CuentasPorPagar')).single['id'] as int;
    final pagoId = (await db.query('PagosCuentaPorPagar')).single['id'] as int;

    await repo.anularPagoCuentaPorPagar(pagoId);

    expect(await db.query('PagosCuentaPorPagar'), isEmpty);
    expect(await db.query('Gastos'), isEmpty);
    expect(await db.query('MovimientosCaja'), isEmpty);
    final cuenta = (await db.query(
      'CuentasPorPagar',
      where: 'id = ?',
      whereArgs: [cuentaId],
    )).single;
    expect((cuenta['monto_pagado'] as num).toDouble(), 0.0);
    expect((cuenta['adelanto'] as num).toDouble(), 0.0);
    expect(cuenta['compra_ocasional_id'], compraId);
    expect(
      await db.query(
        'ComprasOcasionales',
        where: 'id = ?',
        whereArgs: [compraId],
      ),
      hasLength(1),
    );
  });

  test(
    'ninguna compra ocasional toca inventario ni crea AjustesStock',
    () async {
      final insumoId = await _crearInsumo(db);
      final stockAntes = (await db.query(
        'Insumos',
        where: 'id = ?',
        whereArgs: [insumoId],
      )).single['stock_actual'];
      await _abrirSesion(db);

      await repo.registrarCompraOcasional(_ocasional(total: 15, fecha: _hoy()));
      final creditoId = await repo.registrarCompraOcasional(
        _ocasional(esPorPagar: true, adelanto: 10, total: 40, fecha: _hoy()),
      );
      final cuentaId =
          (await db.query(
                'CuentasPorPagar',
                where: 'compra_ocasional_id = ?',
                whereArgs: [creditoId],
              )).single['id']
              as int;
      await repo.aplicarPago(cuentaId, 5, metodoPago: 'efectivo');

      expect(await db.query('AjustesStock'), isEmpty);
      final stockDespues = (await db.query(
        'Insumos',
        where: 'id = ?',
        whereArgs: [insumoId],
      )).single['stock_actual'];
      expect(stockDespues, stockAntes);
      final gastos = await db.query('Gastos');
      expect(gastos.every((g) => g['insumo_id'] == null), isTrue);
      final cuentas = await db.query('CuentasPorPagar');
      expect(cuentas.every((c) => c['insumo_id'] == null), isTrue);
      expect(cuentas.every((c) => c['compra_movimiento_id'] == null), isTrue);
    },
  );

  test(
    'los gastos ocasionales alimentan reportes y el cuadre de caja',
    () async {
      await _abrirSesion(db);
      await repo.registrarCompraOcasional(
        _ocasional(total: 25, categoria: 'Insumos', fecha: _hoy()),
      );
      await repo.registrarCompraOcasional(
        _ocasional(
          esPorPagar: true,
          adelanto: 10,
          total: 50,
          categoria: 'Servicios',
          fecha: _hoy(),
        ),
      );

      final totalGastos = await reportes.getTotalGastos(_hoy(), _manana());
      expect(totalGastos, 35.0);

      final sesion = SesionCaja.fromMap(
        (await db.query('SesionesCaja')).single,
      );
      final movimientos = (await db.query('MovimientosCaja'))
          .map(MovimientoCaja.fromMap)
          .toList();
      final resumen = CashCloseSummary.calculate(sesion, movimientos);
      expect(resumen.salidasEfectivo, 35.0);
      expect(resumen.salidasTransferencias, 0.0);
      expect(resumen.gastos, 35.0);
      expect(resumen.efectivoEsperado, 65.0);
    },
  );

  test('el cuadre separa efectivo de digital en compras ocasionales', () async {
    await _abrirSesion(db);
    await repo.registrarCompraOcasional(
      _ocasional(total: 15, metodoPago: 'efectivo', fecha: _hoy()),
    );
    await repo.registrarCompraOcasional(
      _ocasional(total: 25, metodoPago: 'yape/plin', fecha: _hoy()),
    );

    final sesion = SesionCaja.fromMap((await db.query('SesionesCaja')).single);
    final movimientos = (await db.query('MovimientosCaja'))
        .map(MovimientoCaja.fromMap)
        .toList();
    final resumen = CashCloseSummary.calculate(sesion, movimientos);
    expect(resumen.salidasEfectivo, 15.0);
    expect(resumen.salidasTransferencias, 25.0);
    expect(resumen.efectivoEsperado, 85.0);
    expect(resumen.transferenciasEsperadas, -15.0);
  });

  test('rechaza categorías reservadas y no crea filas', () async {
    for (final categoria in [
      'Compras',
      'Activos Fijos',
      'Cuentas por Pagar',
      'compras',
    ]) {
      await expectLater(
        () => repo.registrarCompraOcasional(
          _ocasional(categoria: categoria, fecha: _hoy()),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('no es válida'),
          ),
        ),
      );
    }
    expect(await db.query('ComprasOcasionales'), isEmpty);
    expect(await db.query('Gastos'), isEmpty);
    expect(OccasionalPurchaseRules.categoriaPermitida('Insumos'), isTrue);
    expect(OccasionalPurchaseRules.categoriaPermitida('compras'), isFalse);
  });
}
