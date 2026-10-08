import 'package:flutter/material.dart';
import 'package:pizzaapp/models/proveedor.dart';
import 'package:pizzaapp/services/proveedor_service.dart';

class ProveedorController extends ChangeNotifier {
  final ProveedorService _service;
  ProveedorController(this._service);

  List<Proveedor> _proveedores = [];
  bool _isLoading = false;
  String? _error;

  List<Proveedor> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProveedores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _proveedores = await _service.obtenerProveedores();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> guardarProveedor(Proveedor p) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.guardarProveedor(p);
      await loadProveedores();
      return null; // null = éxito
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<String?> eliminarProveedor(int id) async {
    try {
      await _service.eliminarProveedor(id);
      await loadProveedores();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}
