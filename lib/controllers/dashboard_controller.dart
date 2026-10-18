import 'package:flutter/material.dart';
import 'package:pizzaapp/services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService _service;

  DashboardController(this._service);

  DashboardSummary _summary = DashboardSummary();
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isRefreshing = false;
  String? _error;

  DashboardSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    if (_hasLoaded) {
      await refreshDashboard();
      return;
    }
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _service.obtenerResumenDelDia();
      _hasLoaded = true;
    } catch (e) {
      _error = 'Error al cargar el resumen: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza las cifras sin desmontar ni cubrir el dashboard.
  Future<void> refreshDashboard() async {
    if (_isRefreshing || _isLoading) return;
    _isRefreshing = true;
    try {
      _summary = await _service.obtenerResumenDelDia();
      _error = null;
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar el resumen: $e';
    } finally {
      _isRefreshing = false;
    }
  }

  String getDiaSemana(int weekday) {
    const dias = ['', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    return weekday < dias.length ? dias[weekday] : '';
  }
}
