import 'package:flutter/material.dart';
import 'package:pizzaapp/services/receta_service.dart';
import 'package:pizzaapp/models/receta.dart';

class RecetaController extends ChangeNotifier {
  final RecetaService _service;

  RecetaController(this._service);

  List<RecetaItem> _recetaActual = [];
  bool _isLoading = false;
  String? _error;

  List<RecetaItem> get recetaActual => _recetaActual;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get costoTotalEstimado {
    return _recetaActual.fold(0.0, (sum, item) {
      return sum + (item.costoCalculado ?? 0.0);
    });
  }

  Future<void> loadReceta(int varianteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recetaActual = await _service.obtenerRecetaCompleta(varianteId);
    } catch (e) {
      _error = 'Error al cargar receta: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarInsumo({
    required int varianteId,
    required int insumoId,
    required String cantidadText,
    required String unidadMedida,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cantidad = double.tryParse(cantidadText) ?? 0.0;
      final item = RecetaItem(
        varianteId: varianteId,
        insumoId: insumoId,
        cantidad: cantidad,
        unidadMedida: unidadMedida,
      );
      await _service.agregarInsumoAReceta(item);
      await loadReceta(varianteId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminarInsumo(int varianteId, int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.eliminarInsumoDeReceta(id);
      await loadReceta(varianteId);
    } catch (e) {
      _error = 'Error al eliminar: \$e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
