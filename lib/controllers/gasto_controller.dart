import 'package:flutter/material.dart';
import 'package:pizzaapp/models/gasto.dart';
import 'package:pizzaapp/services/gasto_service.dart';

class GastoController extends ChangeNotifier {
  final GastoService _service;

  GastoController(this._service);

  List<Gasto> _gastos = [];
  bool _isLoading = false;
  String? _error;

  List<Gasto> get gastos => _gastos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGastos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gastos = await _service.obtenerGastos();
    } catch (e) {
      _error = 'Error al cargar gastos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarGastoMap({
    int? id,
    required String categoria,
    required String descripcion,
    required String montoText,
    String? fotoReciboRuta,
    required String fecha,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final monto = double.tryParse(montoText) ?? 0.0;
      final gasto = Gasto(
        id: id,
        fecha: fecha,
        categoria: categoria,
        descripcion: descripcion,
        monto: monto,
        fotoReciboRuta: fotoReciboRuta,
      );

      await _service.registrarGasto(gasto);
      await loadGastos();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminarGasto(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.eliminarGasto(id);
      await loadGastos();
    } catch (e) {
      _error = 'Error al eliminar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
