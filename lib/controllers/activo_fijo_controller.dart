import 'package:flutter/material.dart';
import 'package:pizzaapp/models/activo_fijo.dart';
import 'package:pizzaapp/services/activo_fijo_service.dart';

class ActivoFijoController extends ChangeNotifier {
  final ActivoFijoService _service;

  ActivoFijoController(this._service);

  List<ActivoFijo> _activos = [];
  bool _isLoading = false;
  String? _error;

  List<ActivoFijo> get activos => _activos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalInvertido => _service.calcularTotalInvertido(_activos);

  Future<void> loadActivos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activos = await _service.obtenerTodos();
    } catch (e) {
      _error = 'Error al cargar los activos: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarActivo({
    int? id,
    required String nombre,
    String? categoria,
    required double costo,
    String? fechaAdquisicion,
    required String estado,
    String? observaciones,
    String? fotoRuta,
    required String condicion,
    required String metodoPago,
    required int cuotas,
    required int cantidad,
    String? frecuenciaAlquiler,
    double adelanto = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final obj = ActivoFijo(
        id: id,
        nombre: nombre,
        categoria: categoria,
        costo: costo,
        fechaAdquisicion: fechaAdquisicion,
        estado: estado,
        observaciones: observaciones,
        fotoRuta: fotoRuta,
        condicion: condicion,
        metodoPago: metodoPago,
        cuotas: cuotas,
        cantidad: cantidad,
        frecuenciaAlquiler: frecuenciaAlquiler,
      );

      if (id == null) {
        await _service.registrarActivo(obj, adelanto);
      } else {
        await _service.actualizarActivo(obj);
      }
      await loadActivos();
      return true;
    } catch (e) {
      _error = 'Error al guardar: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cambiarEstado(int id, String nuevoEstado) async {
    _isLoading = true;
    notifyListeners();
    try {
      final activo = _activos.firstWhere((a) => a.id == id);
      final updated = ActivoFijo(
        id: activo.id,
        nombre: activo.nombre,
        categoria: activo.categoria,
        costo: activo.costo,
        fechaAdquisicion: activo.fechaAdquisicion,
        estado: nuevoEstado,
        condicion: activo.condicion,
        metodoPago: activo.metodoPago,
        cuotas: activo.cuotas,
        cantidad: activo.cantidad,
        frecuenciaAlquiler: activo.frecuenciaAlquiler,
        observaciones: activo.observaciones,
        fotoRuta: activo.fotoRuta,
        activo: activo.activo,
      );
      await _service.actualizarActivo(updated);
      await loadActivos();
    } catch (e) {
      _error = 'Error al cambiar estado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> eliminarActivo(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.eliminarActivo(id);
      await loadActivos();
    } catch(e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> registrarReparacion(ActivoFijo activo, double costo, String descripcion) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.registrarGastoReparacion(activo, costo, descripcion);
      return true;
    } catch(e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
