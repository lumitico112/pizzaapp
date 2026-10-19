import 'package:flutter/material.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/services/producto_service.dart';

class ProductoController extends ChangeNotifier {
  final ProductoService _service;

  ProductoController(this._service);

  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProductos({int? categoriaId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await _service.getProductos(categoriaId: categoriaId);
    } catch (e) {
      _error = 'Error al cargar productos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarProductoCompleto({
    required Producto producto,
    required List<VarianteProducto> variantes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.guardarProductoCompleto(producto, variantes);
      await loadProductos(); // Recarga general (podría optimizarse según el filtro activo)
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminarProducto(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.eliminarProducto(id);
      await loadProductos();
    } catch (e) {
      _error = 'Error al eliminar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<VarianteProducto>> obtenerVariantes(int productoId) async {
    try {
      return await _service.getVariantes(productoId);
    } catch (e) {
      return [];
    }
  }
}
