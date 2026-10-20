import 'package:flutter/material.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/services/caja_service.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';

class CajaController extends ChangeNotifier {
  final CajaService _service;

  CajaController(this._service);

  bool _isLoading = false;
  String? _error;

  SesionCaja? _sesionActual;
  SesionCaja? _ultimaSesionCerrada;
  CashCloseSummary? _resumenActual;
  CashCloseSummary? _resumenUltimoCierre;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SesionCaja? get sesionActual => _sesionActual;
  SesionCaja? get ultimaSesionCerrada => _ultimaSesionCerrada;
  CashCloseSummary? get resumenActual => _resumenActual;
  CashCloseSummary? get resumenUltimoCierre => _resumenUltimoCierre;
  bool get puedeAutorizarReapertura => _service.puedeAutorizarReapertura;

  bool get yaEstaCerrado => _sesionActual == null;

  Future<void> loadDatosCaja() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sesionActual = await _service.getSesionActiva();
      if (_sesionActual != null) {
        _resumenActual = await _service.getResumenActual();
        _ultimaSesionCerrada = null;
        _resumenUltimoCierre = null;
      } else {
        _resumenActual = null;
        _ultimaSesionCerrada = await _service.getUltimaSesionCerrada();
        if (_ultimaSesionCerrada == null) {
          _resumenUltimoCierre = null;
        } else {
          try {
            _resumenUltimoCierre = await _service.getResumenSesion(
              _ultimaSesionCerrada!,
            );
          } catch (_) {
            // El último cierre sigue visible aunque falle el ajuste histórico.
            _resumenUltimoCierre = null;
          }
        }
      }
    } catch (e) {
      _error = 'Error al cargar caja: $e';
      _resumenActual = null;
      _ultimaSesionCerrada = null;
      _resumenUltimoCierre = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reabrirCaja(int sesionId, String motivo, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.reabrirCaja(sesionId, motivo, password);
      await loadDatosCaja();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> abrirCaja(
    double montoApertura,
    double transferenciasApertura,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.abrirCaja(montoApertura, transferenciasApertura);
      await loadDatosCaja();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<SesionCaja> cerrarCaja(
    double efectivoContado,
    double transferenciasContadas,
    String nota,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cerrada = await _service.cerrarCaja(
        efectivoContado,
        transferenciasContadas,
        nota,
      );
      await loadDatosCaja();
      return cerrada;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registrarMovimientoManual(
    String tipo,
    String descripcion,
    double monto,
    String metodoPago,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_sesionActual == null) {
        throw Exception("No hay sesión activa");
      }
      await _service.registrarMovimiento(
        _sesionActual!.id!,
        tipo,
        descripcion,
        monto,
        metodoPago,
      );
      await loadDatosCaja();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> generarArqueoPDF(SesionCaja sesion) async {
    return await _service.generarArqueoPDF(sesion);
  }
}
