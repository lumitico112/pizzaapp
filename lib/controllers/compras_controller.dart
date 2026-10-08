import 'package:flutter/material.dart';
import 'package:pizzaapp/models/compra.dart';
import 'package:pizzaapp/services/compra_service.dart';

class ComprasController extends ChangeNotifier {
  final CompraService _service;

  ComprasController(this._service);

  List<Compra> _historial = [];
  List<Map<String, dynamic>> _gastos = [];
  bool _isLoading = false;
  String? _error;

  List<Compra> get historial => _historial;
  List<Map<String, dynamic>> get gastos => _gastos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHistorial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _historial = await _service.obtenerHistorialCompras();
      _gastos = await _service.obtenerGastosRaw();
    } catch (e) {
      _error = 'Error al cargar: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarCompra(
    bool esPorPagar, {
    required int insumoId,
    required String cantidadText,
    required String costoText,
    String? nota,
    String? proveedor,
    String? facturaRuta,
    double adelanto = 0.0,
    String? fechaPersonalizada,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cantidad = double.tryParse(cantidadText) ?? 0.0;
      final costo = double.tryParse(costoText) ?? 0.0;

      if (esPorPagar) {
        await _service.registrarCompraPorPagar(
          insumoId: insumoId,
          cantidad: cantidad,
          costoTotal: costo,
          proveedor: proveedor,
          factura: nota,
          facturaRuta: facturaRuta,
          adelanto: adelanto,
          fecha: fechaPersonalizada,
        );
      } else {
        await _service.registrarCompraDirecta(
          insumoId: insumoId,
          cantidad: cantidad,
          costoTotal: costo,
          motivo: nota,
          facturaRuta: facturaRuta,
          fecha: fechaPersonalizada,
        );
        await loadHistorial();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
