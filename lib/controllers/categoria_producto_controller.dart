import 'package:flutter/material.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/services/producto_service.dart';

class CategoriaProductoController extends ChangeNotifier {
  final ProductoService _service;

  CategoriaProductoController(this._service);

  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _error;

  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategorias() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorias = await _service.getCategorias();
    } catch (e) {
      _error = 'Error al cargar categorias: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarCategoria({int? id, required String nombre}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cat = Categoria(id: id, nombre: nombre);
      await _service.guardarCategoria(cat);
      await loadCategorias();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
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
      _error = 'Error al eliminar: \$e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
