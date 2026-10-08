import 'package:flutter/material.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/services/pos_service.dart';

class PosController extends ChangeNotifier {
  final PosService _service;

  PosController(this._service);

  List<Categoria> _categorias = [];
  List<PosItem> _posItems = [];
  List<CartItem> _carrito = [];
  int? _categoriaSeleccionada;

  bool _isLoading = false;
  String? _error;

  List<Categoria> get categorias => _categorias;
  List<PosItem> get posItems => _posItems;
  List<CartItem> get carrito => _carrito;
  int? get categoriaSeleccionada => _categoriaSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get granTotal => _carrito.fold(0, (sum, item) => sum + item.total);
  int get totalArticulos => _carrito.fold(0, (sum, item) => sum + item.cantidad);

  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorias = await _service.getCategorias();
      await filtrarPorCategoria(null);
    } catch (e) {
      _error = 'Error al cargar el menú: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarPorCategoria(int? categoriaId) async {
    _isLoading = true;
    _categoriaSeleccionada = categoriaId;
    notifyListeners();

    try {
      _posItems = await _service.getPosItems(categoriaId);
    } catch (e) {
      _error = 'Error al filtrar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? agregarAlCarrito(PosItem item, int cantidad, {double? precioPersonalizado, bool esCortesia = false}) {
    if (cantidad <= 0) return 'Cantidad inválida';

    int currentInCart = 0;
    
    int existingIndex = -1;
    if (precioPersonalizado == null && !esCortesia) {
      existingIndex = _carrito.indexWhere((c) => c.variante?.id == item.variante.id && !c.esPromocion && c.precioPersonalizado == null && !c.esCortesia);
      if (existingIndex >= 0) {
        currentInCart = _carrito[existingIndex].cantidad;
      }
    } else {
      currentInCart = _carrito.where((c) => c.variante?.id == item.variante.id && !c.esPromocion).fold(0, (sum, c) => sum + c.cantidad);
    }

    if (item.producto.tipoPreparacion == 'anticipado') {
      if ((currentInCart + cantidad) > item.variante.stock) {
        return 'Stock insuficiente. Solo hay ${item.variante.stock} disponibles.';
      }
    }

    if (existingIndex >= 0) {
      _carrito[existingIndex].cantidad += cantidad;
    } else {
      _carrito.add(CartItem(
        producto: item.producto,
        variante: item.variante,
        cantidad: cantidad,
        precioPersonalizado: precioPersonalizado,
        esCortesia: esCortesia,
      ));
    }
    notifyListeners();
    return null; // Éxito
  }

  String? agregarPromocionAlCarrito(Promocion promo) {
    if (promo.activa != 1) return 'Promoción inactiva';
    
    _carrito.add(CartItem(
      esPromocion: true,
      promocionId: promo.id,
      nombrePromocion: promo.nombre,
      precioPromocion: promo.precio,
      cantidad: 1,
    ));
    notifyListeners();
    return null;
  }

  void removerDelCarrito(CartItem cartItem) {
    _carrito.remove(cartItem);
    notifyListeners();
  }

  void limpiarCarrito() {
    _carrito.clear();
    notifyListeners();
  }

  Future<String?> procesarCobro(String metodoPago, String observaciones, {String? fechaPersonalizada}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pdfPath = await _service.registrarVenta(
        carrito: _carrito,
        metodoPago: metodoPago,
        totalCalculado: granTotal,
        observaciones: observaciones,
        fechaPersonalizada: fechaPersonalizada,
      );
      limpiarCarrito();
      _isLoading = false;
      return pdfPath;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}

