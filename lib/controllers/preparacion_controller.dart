import 'package:flutter/material.dart';
import 'package:pizzaapp/models/preparacion.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/services/preparacion_service.dart';
import 'package:pizzaapp/services/producto_service.dart';

class PreparacionController extends ChangeNotifier {
  final PreparacionService _prepService;
  final ProductoService _prodService;

  PreparacionController(this._prepService, this._prodService);

  List<Preparacion> _historial = [];
  List<Producto> _productosPreHechos = []; // Para llenar el form de pre-preparacion
  
  bool _isLoading = false;
  String? _error;

  List<Preparacion> get historial => _historial;
  List<Producto> get productosPreHechos => _productosPreHechos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHistorial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _historial = await _prepService.obtenerHistorial();
    } catch (e) {
      _error = 'Error al cargar historial: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductosParaPreparacion() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Filtrar solo los productos que tengan tipoPreparacion == 'pre_hecho' o mostrar todos.
      // Dependiendo de la regla, pero mostramos todos y cargamos sus variantes.
      final prods = await _prodService.getProductos();
      // Vamos a vincularle sus variantes aquí en el controlador para que la vista las lea fácil
      _productosPreHechos = prods;
    } catch (e) {
      _error = 'Error al cargar productos: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<VarianteProducto>> obtenerVariantesPorProducto(int productoId) async {
    return await _prodService.getVariantes(productoId);
  }

  Future<bool> registrarPreparacion({
    required String nota,
    required List<Map<String, dynamic>> seleccion,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _prepService.registrarPreparacion(nota: nota, seleccion: seleccion);
      await loadHistorial();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> marcarComoMerma(int itemId, int cantidad) async {
    try {
      await _prepService.marcarComoMerma(itemId, cantidad);
      await loadHistorial();
    } catch (e) {
      _error = 'Error al marcar como merma: \$e';
      notifyListeners();
    }
  }

  Future<void> llevarParaManana(int itemId, int cantidad) async {
    try {
      await _prepService.llevarParaManana(itemId, cantidad);
      await loadHistorial();
    } catch (e) {
      _error = 'Error al llevar para mañana: \$e';
      notifyListeners();
    }
  }

  Future<List<Transformacion>> obtenerTransformaciones() async {
    try {
      return await _prepService.obtenerTransformaciones();
    } catch (e) {
      _error = 'Error al obtener transformaciones: \$e';
      notifyListeners();
      return [];
    }
  }

  Future<void> crearTransformacion(Transformacion transformacion) async {
    try {
      await _prepService.crearTransformacion(transformacion);
    } catch (e) {
      _error = 'Error al crear transformación: \$e';
      notifyListeners();
    }
  }
}
