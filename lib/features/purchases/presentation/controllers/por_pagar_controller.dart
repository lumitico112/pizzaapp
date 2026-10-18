import 'package:flutter/material.dart';
import 'package:pizzaapp/models/cuenta_por_pagar.dart';
import 'package:pizzaapp/features/purchases/application/compra_service.dart';

class PorPagarController extends ChangeNotifier {
  final CompraService _service;

  PorPagarController(this._service);

  List<CuentaPorPagar> _cuentas = [];
  bool _isLoading = false;
  String? _error;

  List<CuentaPorPagar> get cuentas => _cuentas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCuentas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cuentas = await _service.obtenerCuentasPorPagar();
    } catch (e) {
      _error = 'Error al cargar cuentas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> pagarCuenta(
    int cuentaId,
    double montoAbono, {
    String metodoPago = 'efectivo',
    String? nota,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.pagarCuentaPorPagar(
        cuentaId,
        montoAbono,
        metodoPago: metodoPago,
        nota: nota,
      );
      await loadCuentas();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> historialPagos(int cuentaId) =>
      _service.obtenerHistorialPagos(cuentaId);
}
