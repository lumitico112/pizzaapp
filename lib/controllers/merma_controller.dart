import 'package:flutter/material.dart';
import 'package:pizzaapp/models/merma.dart';
import 'package:pizzaapp/services/merma_service.dart';

class MermaController extends ChangeNotifier {
  final MermaService _service;

  MermaController(this._service);

  List<Merma> _mermas = [];
  bool _isLoading = false;
  String? _error;

  List<Merma> get mermas => _mermas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMermas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mermas = await _service.obtenerMermas();
    } catch (e) {
      _error = 'Error al cargar mermas: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarMerma({
    required String tipo,
    required String cantidadText,
    String? descripcion,
    int? insumoId,
    int? varianteId,
    String? fotoRuta,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cantidad = double.tryParse(cantidadText) ?? 0.0;
      await _service.registrarMerma(
        tipo: tipo,
        cantidad: cantidad,
        descripcion: descripcion,
        insumoId: insumoId,
        varianteId: varianteId,
        fotoRuta: fotoRuta,
      );
      
      await loadMermas();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
