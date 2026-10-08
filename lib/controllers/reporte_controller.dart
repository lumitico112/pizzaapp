import 'package:flutter/material.dart';
import 'package:pizzaapp/models/reporte_data.dart';
import 'package:pizzaapp/services/reportes_service.dart';
import 'package:intl/intl.dart';

class ReporteController extends ChangeNotifier {
  final ReportesService _service;

  ReporteController(this._service);

  bool _isLoading = false;
  String? _error;
  ReporteData? _reporte;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ReporteData? get reporte => _reporte;

  String _lastRangoStr = '';

  Future<void> cargarReporte(DateTime inicio, DateTime fin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final strInicio = DateFormat('yyyy-MM-dd').format(inicio);
      final strFin = DateFormat('yyyy-MM-dd').format(fin);
      _lastRangoStr = '$strInicio al $strFin';
      _reporte = await _service.getReporteGlobal(strInicio, strFin);
    } catch (e) {
      _error = 'Error al generar reporte: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generarPDF() async {
    if (_reporte == null) return null;
    try {
      return await _service.generarReportePDF(_reporte!, _lastRangoStr);
    } catch (e) {
      _error = 'Error PDF: $e';
      notifyListeners();
      return null;
    }
  }
}
