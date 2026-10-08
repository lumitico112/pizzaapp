import 'package:flutter/material.dart';
import 'package:pizzaapp/services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService _service;

  DashboardController(this._service);

  DashboardSummary _summary = DashboardSummary();
  bool _isLoading = false;
  String? _error;

  DashboardSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _service.obtenerResumenDelDia();
    } catch (e) {
      _error = 'Error al cargar el resumen: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getDiaSemana(int weekday) {
    const dias = ['', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    return weekday < dias.length ? dias[weekday] : '';
  }
}
