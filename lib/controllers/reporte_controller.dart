import 'package:flutter/material.dart';
import 'package:pizzaapp/models/reporte_data.dart';
import 'package:pizzaapp/models/reporte_periodo.dart';
import 'package:pizzaapp/services/reportes_service.dart';

class ReporteController extends ChangeNotifier {
  final ReportesService _service;

  ReporteController(this._service);

  bool _isLoading = false;
  String? _error;
  ReporteData? _reporte;
  int _requestId = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ReporteData? get reporte => _reporte;

  Future<void> cargarReporte(ReportePeriodo periodo) async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reporte = await _service.getReporteGlobal(periodo);
      if (requestId != _requestId) return;
      _reporte = reporte;
    } catch (e) {
      if (requestId != _requestId) return;
      _error = 'Error al generar reporte: $e';
      _reporte = null;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<String?> generarPDF() async {
    if (_isLoading || _reporte == null) return null;

    _error = null;
    notifyListeners();

    try {
      return await _service.generarReportePDF(_reporte!);
    } catch (e) {
      _error = 'Error PDF: $e';
      notifyListeners();
      return null;
    }
  }
}
