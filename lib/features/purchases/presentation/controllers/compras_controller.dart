import 'package:flutter/material.dart';
import 'package:pizzaapp/models/compra.dart';
import 'package:pizzaapp/features/purchases/application/compra_service.dart';

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
      _error = 'Error al cargar: $e';
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
    int? proveedorId,
    String? facturaRuta,
    double adelanto = 0.0,
    String? fechaPersonalizada,
    String metodoPago = 'efectivo',
    int cuotas = 1,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cantidad =
          double.tryParse(cantidadText.replaceAll(',', '.')) ?? 0.0;
      final costo = double.tryParse(costoText.replaceAll(',', '.')) ?? 0.0;

      if (esPorPagar) {
        await _service.registrarCompraPorPagar(
          insumoId: insumoId,
          cantidad: cantidad,
          costoTotal: costo,
          proveedor: proveedor,
          proveedorId: proveedorId,
          factura: nota,
          facturaRuta: facturaRuta,
          adelanto: adelanto,
          fecha: fechaPersonalizada,
          metodoPago: metodoPago,
          cuotas: cuotas,
        );
      } else {
        await _service.registrarCompraDirecta(
          insumoId: insumoId,
          cantidad: cantidad,
          costoTotal: costo,
          motivo: nota,
          facturaRuta: facturaRuta,
          fecha: fechaPersonalizada,
          metodoPago: metodoPago,
          proveedorId: proveedorId,
        );
      }

      _historial = await _service.obtenerHistorialCompras();
      _gastos = await _service.obtenerGastosRaw();

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

  Future<bool> corregirCompra({
    required Compra compra,
    required String cantidadText,
    required String costoText,
    int? nuevoInsumoId,
    String? fecha,
    String? motivo,
    String? proveedor,
    int? proveedorId,
    String? facturaRuta,
    bool? esPorPagar,
    double? adelanto,
    int cuotas = 1,
    String metodoPago = 'efectivo',
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cantidad = double.tryParse(cantidadText.replaceAll(',', '.')) ?? 0;
      final costo = double.tryParse(costoText.replaceAll(',', '.')) ?? 0;
      final id = compra.movimientoId ?? compra.id;
      await _service.corregirCompra(
        movimientoId: id,
        cantidad: cantidad,
        costoTotal: costo,
        nuevoInsumoId: nuevoInsumoId,
        fecha: fecha,
        motivo: motivo,
        proveedor: proveedor,
        proveedorId: proveedorId,
        facturaRuta: facturaRuta,
        esPorPagar: esPorPagar,
        adelanto: adelanto,
        cuotas: cuotas,
        metodoPago: metodoPago,
      );
      _historial = await _service.obtenerHistorialCompras();
      _gastos = await _service.obtenerGastosRaw();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarCompra(int movimientoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.eliminarCompra(movimientoId);
      _historial = await _service.obtenerHistorialCompras();
      _gastos = await _service.obtenerGastosRaw();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarGasto(int gastoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.eliminarGasto(gastoId);
      _historial = await _service.obtenerHistorialCompras();
      _gastos = await _service.obtenerGastosRaw();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
