import sys

new_content = """import 'package:flutter/material.dart';
import 'package:pizzaapp/models/activo_fijo.dart';
import 'package:pizzaapp/services/activo_fijo_service.dart';

class ActivoFijoController extends ChangeNotifier {
  final ActivoFijoService _service;

  ActivoFijoController(this._service);

  List<ActivoFijo> _activos = [];
  bool _isLoading = false;
  String? _error;

  List<ActivoFijo> get activos => _activos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalInvertido => _service.calcularTotalInvertido(_activos);

  Future<void> loadActivos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activos = await _service.obtenerTodos();
    } catch (e) {
      _error = 'Error al cargar los activos: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarActivo(ActivoFijo obj) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.registrarActivo(obj);
      await loadActivos();
      return true;
    } catch (e) {
      _error = 'Error al guardar: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> actualizarActivo(ActivoFijo obj) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.actualizarActivo(obj);
      await loadActivos();
      return true;
    } catch (e) {
      _error = 'Error al guardar: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminarActivo(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.eliminarActivo(id);
      await loadActivos();
    } catch(e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> registrarReparacion(ActivoFijo activo, double costo, String descripcion) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.registrarGastoReparacion(activo, costo, descripcion);
      return true;
    } catch(e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
"""

with open('C:/D/ProyectoPizza/pizzaapp/lib/controllers/activo_fijo_controller.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
