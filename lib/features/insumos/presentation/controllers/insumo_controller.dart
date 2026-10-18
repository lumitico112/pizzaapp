import 'package:flutter/material.dart';
import 'package:pizzaapp/features/insumos/domain/usecases/insumo_catalog_use_cases.dart';
import 'package:pizzaapp/models/insumo.dart';

/// Presentation state for ingredient catalog screens.
class InsumoController extends ChangeNotifier {
  final InsumoCatalogUseCases _useCases;

  InsumoController(this._useCases);

  List<Insumo> _insumos = [];
  bool _isLoading = false;
  String? _error;

  List<Insumo> get insumos => _insumos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInsumos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _insumos = await _useCases.list();
    } catch (e) {
      _error = 'Error al cargar insumos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarInsumo({
    int? id,
    required String nombre,
    required String tipoInsumo,
    required String unidadMedida,
    required String stockMinimoText,
    required String rendimientoPorUnidadText,
    int contenidoPaquete = 1,
    String? fotoRuta,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final insumo = Insumo(
        id: id,
        nombre: nombre,
        tipoInsumo: tipoInsumo,
        unidadMedida: unidadMedida,
        contenidoPaquete: contenidoPaquete,
        stockMinimo: double.tryParse(stockMinimoText) ?? 0.0,
        rendimientoPorUnidad: double.tryParse(rendimientoPorUnidadText) ?? 1.0,
        fotoRuta: fotoRuta,
      );
      await _useCases.save(insumo);
      await loadInsumos();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> ajustarStock({
    required int insumoId,
    required String cantidadText,
    String motivo = 'Ajuste manual',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cantidad = double.tryParse(cantidadText) ?? 0.0;
      await _useCases.adjustStock(
        insumoId: insumoId,
        quantity: cantidad,
        reason: motivo,
      );
      await loadInsumos();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminarInsumo(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _useCases.deactivate(id);
      await loadInsumos();
    } catch (e) {
      _error = 'Error al eliminar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
