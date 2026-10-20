import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_historical_adjustment.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/services/caja_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

void main() {
  late Database db;
  late CajaRepository cajaRepo;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb(seed: false);
    cajaRepo = CajaRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> abrirSesion({
    required String fechaApertura,
    double efectivo = 100.0,
    double digital = 50.0,
  }) {
    return cajaRepo.abrirSesion(
      SesionCaja(
        fechaApertura: fechaApertura,
        montoApertura: efectivo,
        transferenciasApertura: digital,
        usuarioAperturaId: null,
      ),
      efectivo > 0
          ? MovimientoCaja(
              sesionCajaId: 0,
              tipo: 'apertura',
              metodoPago: 'efectivo',
              monto: efectivo,
              descripcion: 'Apertura de prueba',
              fecha: fechaApertura,
            )
          : null,
      userId: null,
    );
  }

  Future<int> insertarVentaHistorica({
    required String fecha,
    required String metodoPago,
    required double total,
    bool anulada = false,
    int? movimientoSesionId,
  }) async {
    final ventaId = await db.insert('Ventas', {
      'fecha': fecha,
      'hora': '00:00',
      'metodo_pago': metodoPago,
      'subtotal': total,
      'total': total,
      'anulada': anulada ? 1 : 0,
      'es_historica': 1,
      'nota': '[REGISTRO HISTÓRICO]',
    });
    if (movimientoSesionId != null) {
      await db.insert('MovimientosCaja', {
        'sesion_caja_id': movimientoSesionId,
        'venta_id': ventaId,
        'tipo': 'venta',
        'metodo_pago': metodoPago,
        'monto': total,
        'descripcion': 'Venta #$ventaId',
        'fecha': '${fecha}T12:00:00.000',
      });
    }
    return ventaId;
  }

  Future<SesionCaja> sesionPorId(int id) async {
    final rows = await db.query(
      'SesionesCaja',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return SesionCaja.fromMap(rows.single);
  }

  test(
    'el ajuste histórico separa efectivo/digital y conserva el cierre original',
    () async {
      final sesionId = await abrirSesion(
        fechaApertura: '2026-10-18T20:00:00.000',
      );
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: 'Cierre original',
        usuarioId: null,
      );
      await db.update(
        'SesionesCaja',
        {'fecha_cierre': '2026-10-19T00:30:00.000'},
        where: 'id = ?',
        whereArgs: [sesionId],
      );

      await insertarVentaHistorica(
        fecha: '2026-10-18',
        metodoPago: 'efectivo',
        total: 30.0,
      );
      await insertarVentaHistorica(
        fecha: '2026-10-18',
        metodoPago: 'yape',
        total: 20.0,
      );
      await insertarVentaHistorica(
        fecha: '2026-10-18',
        metodoPago: 'tarjeta',
        total: 15.0,
      );
      // Cruza la medianoche y no existe otra sesión para el 19/10.
      await insertarVentaHistorica(
        fecha: '2026-10-19',
        metodoPago: 'yape/plin',
        total: 10.0,
      );
      // Anulada, fuera de la ventana y con movimiento (defensivo).
      await insertarVentaHistorica(
        fecha: '2026-10-18',
        metodoPago: 'efectivo',
        total: 5.0,
        anulada: true,
      );
      await insertarVentaHistorica(
        fecha: '2026-10-17',
        metodoPago: 'efectivo',
        total: 99.0,
      );
      final sesionAuxiliarId = await db.insert('SesionesCaja', {
        'fecha_apertura': '2026-10-20T10:00:00.000',
        'estado': 'cerrada',
      });
      await insertarVentaHistorica(
        fecha: '2026-10-19',
        metodoPago: 'efectivo',
        total: 7.0,
        movimientoSesionId: sesionAuxiliarId,
      );

      final sesion = await sesionPorId(sesionId);
      final ajuste = await cajaRepo.getAjusteHistorico(sesion);
      expect(ajuste.cantidad, 4);
      expect(ajuste.efectivo, 30.0);
      expect(ajuste.digital, 45.0);
      expect(ajuste.total, 75.0);

      final resumen = await cajaRepo.resumenSesion(sesion);
      expect(resumen.efectivoEsperado, 100.0);
      expect(resumen.transferenciasEsperadas, 50.0);
      expect(resumen.ajusteEfectivo, 30.0);
      expect(resumen.ajusteDigital, 45.0);
      expect(resumen.efectivoEsperadoAjustado, 130.0);
      expect(resumen.transferenciasEsperadasAjustadas, 95.0);
      expect(resumen.totalEsperadoAjustado, 225.0);
      expect(resumen.diferenciaEfectivoAjustada(efectivo: 100.0), -30.0);
      expect(
        resumen.diferenciaTransferenciaAjustada(transferencias: 50.0),
        -45.0,
      );
      expect(
        resumen.diferenciaAjustada(efectivo: 100.0, transferencias: 50.0),
        -75.0,
      );

      final persistida = await sesionPorId(sesionId);
      expect(persistida.totalEfectivoSistema, 100.0);
      expect(persistida.totalYapePlin, 50.0);
      expect(persistida.efectivoContado, 100.0);
      expect(persistida.transferenciasContadas, 50.0);
      expect(persistida.diferencia, 0.0);
      expect(persistida.nota, 'Cierre original');
    },
  );

  test(
    'una sesión abierta no incorpora el ajuste histórico a su caja actual',
    () async {
      final sesionId = await abrirSesion(
        fechaApertura: '2026-10-18T20:00:00.000',
      );
      await insertarVentaHistorica(
        fecha: '2026-10-18',
        metodoPago: 'efectivo',
        total: 40.0,
      );

      final sesion = await sesionPorId(sesionId);
      final resumen = await cajaRepo.resumenSesion(sesion);
      expect(resumen.efectivoEsperado, 100.0);
      expect(resumen.tieneAjusteHistorico, isFalse);
      expect(resumen.ajusteEfectivo, 0.0);
    },
  );

  test('si existe una sesión nueva en la fecha de cierre, la venta se atribuye a esa sesión', () async {
    final anteriorId = await abrirSesion(
      fechaApertura: '2026-10-18T20:00:00.000',
    );
    await cajaRepo.cerrarSesion(
      sesionId: anteriorId,
      efectivoContado: 100.0,
      transferenciasContadas: 50.0,
      nota: '',
      usuarioId: null,
    );
    await db.update(
      'SesionesCaja',
      {'fecha_cierre': '2026-10-19T00:30:00.000'},
      where: 'id = ?',
      whereArgs: [anteriorId],
    );

    final nuevaId = await abrirSesion(
      fechaApertura: '2026-10-19T10:00:00.000',
      efectivo: 0,
      digital: 0,
    );
    await cajaRepo.cerrarSesion(
      sesionId: nuevaId,
      efectivoContado: 0,
      transferenciasContadas: 0,
      nota: '',
      usuarioId: null,
    );
    await db.update(
      'SesionesCaja',
      {'fecha_cierre': '2026-10-19T22:00:00.000'},
      where: 'id = ?',
      whereArgs: [nuevaId],
    );

    await insertarVentaHistorica(
      fecha: '2026-10-18',
      metodoPago: 'efectivo',
      total: 25.0,
    );
    await insertarVentaHistorica(
      fecha: '2026-10-19',
      metodoPago: 'yape',
      total: 12.0,
    );

    final ajusteAnterior = await cajaRepo.getAjusteHistorico(
      await sesionPorId(anteriorId),
    );
    expect(ajusteAnterior.ventas.map((v) => v.ventaId), hasLength(1));
    expect(ajusteAnterior.efectivo, 25.0);
    expect(ajusteAnterior.digital, 0.0);

    final ajusteNueva = await cajaRepo.getAjusteHistorico(
      await sesionPorId(nuevaId),
    );
    expect(ajusteNueva.cantidad, 1);
    expect(ajusteNueva.efectivo, 0.0);
    expect(ajusteNueva.digital, 12.0);
  });

  test('el ajuste histórico redondea a centavos', () {
    const ajuste = CashHistoricalAdjustment(
      ventas: [
        CashHistoricalSale(
          ventaId: 1,
          fecha: '2026-10-18',
          hora: '00:00',
          metodoPago: 'efectivo',
          total: 0.10,
        ),
        CashHistoricalSale(
          ventaId: 2,
          fecha: '2026-10-18',
          hora: '00:00',
          metodoPago: 'yape',
          total: 0.20,
        ),
      ],
    );

    expect(ajuste.efectivo, 0.10);
    expect(ajuste.digital, 0.20);
    expect(ajuste.total, 0.30);

    final resumen = CashCloseSummary(
      efectivoEsperado: 1.0,
      transferenciasEsperadas: 1.0,
      gastos: 0,
      ajusteHistorico: ajuste,
    );
    expect(resumen.efectivoEsperadoAjustado, 1.10);
    expect(resumen.transferenciasEsperadasAjustadas, 1.20);
    expect(resumen.totalEsperadoAjustado, 2.30);
  });

  test(
    'el controlador expone el resumen del último cierre con ajuste',
    () async {
      final sesionId = await abrirSesion(
        fechaApertura: '2026-10-18T20:00:00.000',
      );
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: '',
        usuarioId: null,
      );
      await insertarVentaHistorica(
        fecha: '2026-10-18',
        metodoPago: 'efectivo',
        total: 18.0,
      );

      final controller = CajaController(CajaService(cajaRepo));
      addTearDown(controller.dispose);
      await controller.loadDatosCaja();

      expect(controller.sesionActual, isNull);
      expect(controller.ultimaSesionCerrada?.id, sesionId);
      expect(controller.resumenUltimoCierre?.ajusteEfectivo, 18.0);
      expect(controller.resumenUltimoCierre?.totalEsperadoAjustado, 168.0);
    },
  );

  test(
    'el PDF de arqueo histórico se genera con cierre original y ajuste',
    () async {
      final sesionId = await abrirSesion(
        fechaApertura: '2026-10-18T20:00:00.000',
      );
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 100.0,
        transferenciasContadas: 50.0,
        nota: 'Cierre original',
        usuarioId: null,
      );
      await insertarVentaHistorica(
        fecha: '2026-10-18',
        metodoPago: 'efectivo',
        total: 22.0,
      );

      final output = await Directory.systemTemp.createTemp(
        'kimi_arqueo_historico_',
      );
      addTearDown(() async {
        if (await output.exists()) {
          await output.delete(recursive: true);
        }
      });

      final service = CajaService(cajaRepo);
      final ruta = await service.generarArqueoPDF(
        await sesionPorId(sesionId),
        outputDirectory: output,
      );

      expect(ruta, isNotNull);
      final archivo = File(ruta!);
      expect(await archivo.exists(), isTrue);
      expect(await archivo.length(), greaterThan(1000));
    },
  );
}
