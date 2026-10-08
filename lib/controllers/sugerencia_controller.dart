import 'package:flutter/material.dart';
import 'package:pizzaapp/models/preparacion.dart';
import 'package:pizzaapp/services/preparacion_service.dart';

class SugerenciaController extends ChangeNotifier {
  final PreparacionService _service;

  SugerenciaController(this._service);

  List<SugerenciaPreparacion> _sugerencias = [];
  bool _isLoading = false;
  String? _error;
  String _filtroActivo = 'hoy'; // hoy, manana, semana

  List<SugerenciaPreparacion> get sugerencias => _sugerencias;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroActivo => _filtroActivo;

  Future<void> loadSugerencias(String filtro) async {
    _isLoading = true;
    _error = null;
    _filtroActivo = filtro;
    notifyListeners();

    try {
      final now = DateTime.now();
      int? targetWeekday;

      if (filtro == 'hoy') {
        targetWeekday = now.weekday;
      } else if (filtro == 'mañana') {
        targetWeekday = (now.weekday % 7) + 1;
      } else if (filtro == 'semana') {
        targetWeekday = null; // Todos los días
      }

      _sugerencias = await _service.obtenerSugerencias(targetWeekday: targetWeekday);
    } catch (e) {
      _error = 'Error al calcular sugerencias: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
