import 'package:flutter/material.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/services/caja_service.dart';

class CajaController extends ChangeNotifier {
  final CajaService _service;

  CajaController(this._service);

  bool _isLoading = false;
  String? _error;
  
  SesionCaja? _sesionActual;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SesionCaja? get sesionActual => _sesionActual;
  
  bool get yaEstaCerrado => _sesionActual == null;

  Future<void> loadDatosCaja() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sesionActual = await _service.getSesionActiva();
    } catch (e) {
      _error = 'Error al cargar caja: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> abrirCaja(double montoApertura) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.abrirCaja(montoApertura);
      await loadDatosCaja();
    } catch(e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> cerrarCaja(double efectivoContado, String nota) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.cerrarCaja(efectivoContado, nota);
      await loadDatosCaja();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> registrarMovimientoManual(String tipo, String descripcion, double monto, String metodoPago) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_sesionActual == null) {
         throw Exception("No hay sesión activa");
      }
      await _service.registrarMovimiento(_sesionActual!.id!, tipo, descripcion, monto, metodoPago);
      await loadDatosCaja();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<String?> generarArqueoPDF(SesionCaja sesion) async {
    return await _service.generarArqueoPDF(sesion);
  }
}
