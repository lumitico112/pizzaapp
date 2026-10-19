import 'package:flutter/material.dart';
import 'package:pizzaapp/models/preparacion.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/features/preparation/application/preparacion_service.dart';
import 'package:pizzaapp/services/producto_service.dart';

class PreparacionController extends ChangeNotifier {
  final PreparacionService _prepService;
  final ProductoService _prodService;

  PreparacionController(this._prepService, this._prodService);

  List<Preparacion> _historial = [];
  List<Producto> _productosPreHechos =
      []; // Para llenar el form de pre-preparacion

  bool _isLoading = false;
  String? _error;

  List<Preparacion> get historial => _historial;
  List<Producto> get productosPreHechos => _productosPreHechos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> sobrantesPendientes = [];
  Map<String, dynamic>? preparacionHoy;

  Future<bool> hayCajaActiva() => _prepService.hayCajaActiva();

  Future<void> loadHistorial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _historial = await _prepService.obtenerHistorial();
      preparacionHoy = await _prepService.obtenerPreparacionHoy();
      sobrantesPendientes = await _prepService
          .obtenerProductosConStockParaSobrantes(soloNoResueltos: true);
    } catch (e) {
      _error = 'Error al cargar historial: $e';
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
      final prods = await _prodService.getProductos();
      // Solo los productos que usan stock preparado ('anticipado' o 'ambos')
      // participan en el módulo de Preparación; los 'momento' descuentan su
      // receta directamente al vender sin requerir stock preparado.
      _productosPreHechos = prods
          .where((p) => p.tipoPreparacion.toLowerCase() != 'momento')
          .toList();
    } catch (e) {
      _error = 'Error al cargar productos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<VarianteProducto>> obtenerVariantesPorProducto(
    int productoId,
  ) async {
    return await _prodService.getVariantes(productoId);
  }

  Future<bool> registrarPreparacion({
    required String nota,
    required List<Map<String, dynamic>> seleccion,
    Map<int, int> sobrantesAPreparacion = const {},
    Map<int, int> sobrantesAMerma = const {},
    Map<int, int> trasladadosPorVariante = const {},
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _prepService.registrarPreparacion(
        nota: nota,
        seleccion: seleccion,
        sobrantesAPreparacion: sobrantesAPreparacion,
        sobrantesAMerma: sobrantesAMerma,
        trasladadosPorVariante: trasladadosPorVariante,
      );
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
      _error = 'Error al marcar como merma: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> llevarParaManana(int itemId, int cantidad) async {
    try {
      await _prepService.llevarParaManana(itemId, cantidad);
      await loadHistorial();
    } catch (e) {
      _error = 'Error al llevar para mañana: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refrescarSobrantes() async {
    sobrantesPendientes = await _prepService
        .obtenerProductosConStockParaSobrantes(soloNoResueltos: true);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> obtenerProductosConStockParaSobrantes({
    bool soloNoResueltos = false,
  }) async {
    return await _prepService.obtenerProductosConStockParaSobrantes(
      soloNoResueltos: soloNoResueltos,
    );
  }

  Future<String?> procesarGestionSobrantesStock({
    required Map<int, Map<String, int>> decisiones,
    required bool esCierreDeCiclo,
    String tipoMerma = 'otro',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _prepService.procesarGestionSobrantesStock(
        decisiones: decisiones,
        esCierreDeCiclo: esCierreDeCiclo,
        tipoMerma: tipoMerma,
      );
      await loadHistorial();
      await loadProductosParaPreparacion();
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> procesarSobrantesPendientes({
    required Map<int, int> sobrantesAPreparacion,
    required Map<int, int> sobrantesAMerma,
    required List<int> itemIdsResueltos,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _prepService.procesarSobrantesPendientes(
        sobrantesAPreparacion: sobrantesAPreparacion,
        sobrantesAMerma: sobrantesAMerma,
        itemIdsResueltos: itemIdsResueltos,
      );
      await refrescarSobrantes();
      await loadHistorial();
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Transformacion>> obtenerTransformaciones() async {
    try {
      return await _prepService.obtenerTransformaciones();
    } catch (e) {
      _error = 'Error al obtener transformaciones: $e';
      notifyListeners();
      return [];
    }
  }

  Future<void> crearTransformacion(Transformacion transformacion) async {
    try {
      await _prepService.crearTransformacion(transformacion);
    } catch (e) {
      _error = 'Error al crear transformación: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> aplicarTransformacion({
    required int reglaId,
    required int cantidadOrigen,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _prepService.aplicarTransformacion(
        reglaId: reglaId,
        cantidadOrigen: cantidadOrigen,
      );
      await loadProductosParaPreparacion();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registrarEntradaProductoPreparado({
    required int varianteId,
    required int cantidad,
    required String motivo,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _prepService.registrarEntradaProductoPreparado(
        varianteId: varianteId,
        cantidad: cantidad,
        motivo: motivo,
      );
      await loadProductosParaPreparacion();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
