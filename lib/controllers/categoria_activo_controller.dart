import 'package:flutter/material.dart';
import 'package:pizzaapp/models/categoria_activo.dart';
import 'package:pizzaapp/services/categoria_activo_service.dart';

class CategoriaActivoController extends ChangeNotifier {
  final CategoriaActivoService _service;

  CategoriaActivoController(this._service);

  List<CategoriaActivo> _categorias = [];
  bool _isLoading = false;
  String? _error;

  List<CategoriaActivo> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategorias() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorias = await _service.obtenerCategorias();
    } catch (e) {
      _error = 'Error al cargar: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarCategoria(CategoriaActivo categoria) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.guardarCategoria(categoria);
      await loadCategorias();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminarCategoria(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.eliminarCategoria(id);
      await loadCategorias();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
