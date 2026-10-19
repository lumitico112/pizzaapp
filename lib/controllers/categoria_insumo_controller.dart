import 'package:flutter/material.dart';
import 'package:pizzaapp/models/categoria_insumo.dart';
import 'package:pizzaapp/services/categoria_insumo_service.dart';

class CategoriaInsumoController extends ChangeNotifier {
  final CategoriaInsumoService _service;

  CategoriaInsumoController(this._service);

  List<CategoriaInsumo> _categorias = [];
  bool _isLoading = false;
  String? _error;

  List<CategoriaInsumo> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategorias() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorias = await _service.obtenerCategorias();
    } catch (e) {
      _error = 'Error al cargar categorias: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> guardarCategoria(String nombre) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.guardarCategoria(nombre);
      await loadCategorias();
      return null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<void> eliminarCategoria(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.eliminarCategoria(id);
      await loadCategorias();
    } catch (e) {
      _error = 'Error al eliminar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
