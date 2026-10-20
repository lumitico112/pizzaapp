import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/reporte_controller.dart';
import 'package:pizzaapp/models/reporte_data.dart';
import 'package:pizzaapp/models/reporte_periodo.dart';
import 'package:pizzaapp/services/reportes_service.dart';

class _FakeReportesService extends ReportesService {
  final List<Completer<ReporteData>> pendientes = [];
  ReporteData? pdfData;
  Object? pdfError;
  String? pdfPath = 'reporte.pdf';

  @override
  Future<ReporteData> getReporteGlobal(ReportePeriodo periodo) {
    final completer = Completer<ReporteData>();
    pendientes.add(completer);
    return completer.future;
  }

  @override
  Future<String?> generarReportePDF(ReporteData data) async {
    pdfData = data;
    if (pdfError != null) {
      throw pdfError!;
    }
    return pdfPath;
  }
}

ReporteData _data(ReportePeriodo periodo, {double total = 10.0}) {
  return ReporteData(
    totalIngresos: total,
    totalGastos: 0,
    costoMercaderia: 0,
    beneficioNeto: total,
    productosVendidos: const [],
    periodo: periodo,
  );
}

void main() {
  test('la última solicitud gana aunque la anterior termine después', () async {
    final fake = _FakeReportesService();
    final controller = ReporteController(fake);
    addTearDown(controller.dispose);

    final hoy = ReportePeriodo.hoy(ahora: DateTime(2026, 10, 19));
    final ayer = ReportePeriodo.ayer(ahora: DateTime(2026, 10, 19));

    final primera = controller.cargarReporte(hoy);
    final segunda = controller.cargarReporte(ayer);
    expect(controller.isLoading, isTrue);

    fake.pendientes[1].complete(_data(ayer, total: 20));
    await segunda;

    expect(controller.isLoading, isFalse);
    expect(controller.reporte!.periodo, same(ayer));
    expect(controller.reporte!.totalIngresos, 20);

    // La respuesta vieja llega después y no debe sobrescribir la actual.
    fake.pendientes[0].complete(_data(hoy, total: 10));
    await primera;

    expect(controller.reporte!.periodo, same(ayer));
    expect(controller.reporte!.totalIngresos, 20);
  });

  test('no genera PDF mientras hay una carga en curso', () async {
    final fake = _FakeReportesService();
    final controller = ReporteController(fake);
    addTearDown(controller.dispose);

    final periodo = ReportePeriodo.hoy(ahora: DateTime(2026, 10, 19));
    final carga = controller.cargarReporte(periodo);

    expect(await controller.generarPDF(), isNull);
    expect(fake.pdfData, isNull);

    fake.pendientes[0].complete(_data(periodo));
    await carga;

    expect(await controller.generarPDF(), 'reporte.pdf');
    expect(fake.pdfData!.periodo, same(periodo));
  });

  test(
    'un error de carga limpia el reporte anterior y bloquea el PDF',
    () async {
      final fake = _FakeReportesService();
      final controller = ReporteController(fake);
      addTearDown(controller.dispose);

      final hoy = ReportePeriodo.hoy(ahora: DateTime(2026, 10, 19));
      final ayer = ReportePeriodo.ayer(ahora: DateTime(2026, 10, 19));

      final primera = controller.cargarReporte(hoy);
      fake.pendientes[0].complete(_data(hoy));
      await primera;
      expect(controller.reporte, isNotNull);

      final segunda = controller.cargarReporte(ayer);
      fake.pendientes[1].completeError(StateError('fallo de carga'));
      await segunda;

      expect(controller.reporte, isNull);
      expect(controller.error, contains('fallo de carga'));
      expect(await controller.generarPDF(), isNull);
    },
  );

  test('un error de PDF permite reintentar sin perder el reporte', () async {
    final fake = _FakeReportesService();
    final controller = ReporteController(fake);
    addTearDown(controller.dispose);

    final periodo = ReportePeriodo.hoy(ahora: DateTime(2026, 10, 19));
    final carga = controller.cargarReporte(periodo);
    fake.pendientes[0].complete(_data(periodo));
    await carga;

    fake.pdfError = StateError('no se pudo escribir');
    expect(await controller.generarPDF(), isNull);
    expect(controller.error, contains('no se pudo escribir'));
    expect(controller.reporte, isNotNull);

    fake.pdfError = null;
    expect(await controller.generarPDF(), 'reporte.pdf');
    expect(controller.error, isNull);
    expect(controller.reporte, isNotNull);
  });
}
