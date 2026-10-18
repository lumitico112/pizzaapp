import 'package:flutter/material.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/services/pos_service.dart';

class PosController extends ChangeNotifier {
  final PosService _service;

  PosController(this._service);

  List<Categoria> _categorias = [];
  List<PosItem> _posItems = [];
  List<PosItem> _allPosItems = [];
  List<Promocion> _promociones = [];
  final List<CartItem> _carrito = [];
  int? _categoriaSeleccionada;

  bool _isLoading = false;
  String? _error;

  List<Categoria> get categorias => _categorias;
  List<PosItem> get posItems => _posItems;
  List<PosItem> get allPosItems => _allPosItems;
  List<Promocion> get promociones => _promociones;
  List<CartItem> get carrito => _carrito;
  int? get categoriaSeleccionada => _categoriaSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get granTotal => _carrito.fold(0, (sum, item) => sum + item.total);
  int get totalArticulos =>
      _carrito.fold(0, (sum, item) => sum + item.cantidad);

  bool esVariantePorVaso(Producto producto, VarianteProducto variante) {
    final esBebida = _categorias.any(
      (categoria) =>
          categoria.id == producto.categoriaId &&
          categoria.nombre.toLowerCase().contains('bebida'),
    );
    return esBebida && variante.nombreVariante.toLowerCase().contains('vaso');
  }

  String nombreVenta(Producto producto, VarianteProducto variante) =>
      esVariantePorVaso(producto, variante)
      ? '1 vaso de ${producto.nombre}'
      : producto.nombre;

  String descripcionPromocion(Promocion promo) {
    if (promo.descripcion != null && promo.descripcion!.trim().isNotEmpty) {
      return promo.descripcion!.trim();
    }
    if (promo.items.isNotEmpty) {
      final parts = <String>[];
      for (final comp in promo.items) {
        PosItem? found;
        for (final p in _allPosItems) {
          if (p.variante.id == comp.varianteId) {
            found = p;
            break;
          }
        }
        if (found != null) {
          parts.add(
            '${comp.cantidad}x ${found.producto.nombre} (${found.variante.nombreVariante})',
          );
        }
      }
      if (parts.isNotEmpty) return parts.join(' + ');
    }
    return 'Combo promocional';
  }

  int? stockDisponiblePromocion(Promocion promo) {
    int? minCombos;
    for (final comp in promo.items) {
      if (comp.varianteId == null) continue;
      PosItem? found;
      for (final p in _allPosItems) {
        if (p.variante.id == comp.varianteId) {
          found = p;
          break;
        }
      }
      if (found == null) continue;
      final tipo = found.producto.tipoPreparacion.toLowerCase();
      if ((tipo == 'anticipado' || tipo == 'ambos') &&
          !esVariantePorVaso(found.producto, found.variante)) {
        final req = comp.cantidad > 0 ? comp.cantidad : 1;
        final possible = found.variante.stock ~/ req;
        if (minCombos == null || possible < minCombos) {
          minCombos = possible;
        }
      }
    }
    return minCombos;
  }

  Future<void> loadInitialData() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorias = await _service.getCategorias();
      _promociones = await _service.getPromociones();
      _allPosItems = await _service.getPosItems(null);
      if (_categoriaSeleccionada == -1) {
        _posItems = [];
      } else if (_categoriaSeleccionada == null) {
        _posItems = _allPosItems;
      } else {
        _posItems = await _service.getPosItems(_categoriaSeleccionada);
      }
    } catch (e) {
      _error = 'Error al cargar el menú: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filtrarPorCategoria(int? categoriaId) async {
    _isLoading = true;
    _categoriaSeleccionada = categoriaId;
    notifyListeners();

    try {
      _promociones = await _service.getPromociones();
      _allPosItems = await _service.getPosItems(null);
      if (categoriaId == -1) {
        _posItems = [];
      } else if (categoriaId == null) {
        _posItems = _allPosItems;
      } else {
        _posItems = await _service.getPosItems(categoriaId);
      }
    } catch (e) {
      _error = 'Error al filtrar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? agregarAlCarrito(
    PosItem item,
    int cantidad, {
    double? precioPersonalizado,
    bool esCortesia = false,
  }) {
    if (cantidad <= 0) return 'Cantidad inválida';

    final currentInCart = _carrito
        .where((c) => c.variante?.id == item.variante.id && !c.esPromocion)
        .fold(0, (sum, c) => sum + c.cantidad);
    int existingIndex = -1;
    if (precioPersonalizado == null && !esCortesia) {
      existingIndex = _carrito.indexWhere(
        (c) =>
            c.variante?.id == item.variante.id &&
            !c.esPromocion &&
            c.precioPersonalizado == null &&
            !c.esCortesia,
      );
    }

    if (item.producto.tipoPreparacion == 'anticipado' &&
        !esVariantePorVaso(item.producto, item.variante)) {
      if ((currentInCart + cantidad) > item.variante.stock) {
        return 'Stock insuficiente. Solo hay ${item.variante.stock} disponibles.';
      }
    }

    if (existingIndex >= 0) {
      _carrito[existingIndex].cantidad += cantidad;
    } else {
      _carrito.add(
        CartItem(
          producto: item.producto,
          variante: item.variante,
          cantidad: cantidad,
          precioPersonalizado: precioPersonalizado,
          esCortesia: esCortesia,
        ),
      );
    }
    notifyListeners();
    return null; // Éxito
  }

  String? agregarPromocionAlCarrito(
    Promocion promo, {
    int cantidad = 1,
    double? precioPersonalizado,
    bool esCortesia = false,
  }) {
    if (cantidad <= 0) return 'Cantidad inválida';
    if (promo.activa != 1) return 'Promoción inactiva';
    if (promo.items.isEmpty) {
      return 'La promoción no tiene productos configurados.';
    }

    final currentPromoInCart = _carrito
        .where((c) => c.esPromocion && c.promocionId == promo.id)
        .fold(0, (sum, c) => sum + c.cantidad);

    for (final component in promo.items) {
      if (component.varianteId == null) {
        return 'La promoción tiene un producto sin configurar.';
      }
      PosItem? product;
      for (final candidate in _allPosItems) {
        if (candidate.variante.id == component.varianteId) {
          product = candidate;
          break;
        }
      }
      if (product == null) {
        return 'No se encontró un producto de la promoción.';
      }
      if (product.producto.tipoPreparacion == 'anticipado' &&
          !esVariantePorVaso(product.producto, product.variante)) {
        final requiredTotal =
            (currentPromoInCart + cantidad) * component.cantidad;
        if (product.variante.stock < requiredTotal) {
          return 'Stock insuficiente para ${product.producto.nombre}.';
        }
      }
    }

    int existingIndex = -1;
    if (precioPersonalizado == null && !esCortesia) {
      existingIndex = _carrito.indexWhere(
        (c) =>
            c.esPromocion &&
            c.promocionId == promo.id &&
            c.precioPersonalizado == null &&
            !c.esCortesia,
      );
    }

    if (existingIndex >= 0) {
      _carrito[existingIndex].cantidad += cantidad;
    } else {
      _carrito.add(
        CartItem(
          esPromocion: true,
          promocionId: promo.id,
          nombrePromocion: promo.nombre,
          precioPromocion: promo.precio,
          precioPersonalizado: precioPersonalizado,
          esCortesia: esCortesia,
          cantidad: cantidad,
        ),
      );
    }
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

  Future<String?> procesarCobro(
    String metodoPago,
    String observaciones, {
    String? fechaPersonalizada,
    double? montoRecibido,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final total = granTotal;
      final esCortesia = total <= 0 || _carrito.every((item) => item.esCortesia);
      final metodoPagoFinal = esCortesia
          ? 'efectivo'
          : (metodoPago.isEmpty ? 'efectivo' : metodoPago);

      final pdfPath = await _service.registrarVenta(
        carrito: _carrito,
        metodoPago: metodoPagoFinal,
        totalCalculado: total,
        observaciones: observaciones,
        fechaPersonalizada: fechaPersonalizada,
        montoRecibido: esCortesia ? 0.0 : montoRecibido,
      );
      limpiarCarrito();
      await filtrarPorCategoria(_categoriaSeleccionada);
      _isLoading = false;
      return pdfPath;
    } catch (e, stackTrace) {
      debugPrint('Error en PosController.procesarCobro: $e');
      debugPrint(stackTrace.toString());
      final rawError = e.toString().replaceAll('Exception: ', '').trim();
      _error = rawError.contains('Null check operator')
          ? 'Error al procesar cortesía: faltan datos en el producto o caja.'
          : (rawError.isEmpty ? 'Error al registrar la venta.' : rawError);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getHistorialVentas() async {
    try {
      return await _service.getHistorialVentas();
    } catch (e) {
      _error = 'Error al cargar historial: $e';
      notifyListeners();
      return [];
    }
  }

  Future<String?> obtenerBoleta(int ventaId) async {
    try {
      return await _service.obtenerORecrearBoletaPDF(ventaId);
    } catch (e) {
      _error = 'Error al abrir boleta: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> anularVenta(
    int ventaId, {
    required String motivo,
    bool recargarEnCarrito = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      Map<String, dynamic>? ventaData;
      if (recargarEnCarrito) {
        ventaData = await _service.getVentaConDetalles(ventaId);
      }
      await _service.anularVenta(ventaId: ventaId, motivo: motivo);

      if (recargarEnCarrito && ventaData != null) {
        _carrito.clear();
        final dList = (ventaData['detalles'] as List<dynamic>? ?? const []);
        for (final item in dList) {
          final map = Map<String, dynamic>.from(item as Map);
          final promoId = map['promocion_id'] as int?;
          final varId = map['variante_id'] as int?;
          final cant = (map['cantidad'] as num).toInt();
          final precioUnit = (map['precio_unitario'] as num).toDouble();
          final esCortesia = (map['es_cortesia'] as num?)?.toInt() == 1;

          if (promoId != null) {
            Promocion? foundPromo;
            for (final pr in _promociones) {
              if (pr.id == promoId) {
                foundPromo = pr;
                break;
              }
            }
            _carrito.add(
              CartItem(
                esPromocion: true,
                promocionId: promoId,
                nombrePromocion: foundPromo?.nombre ??
                    map['promo_nombre']?.toString() ??
                    'Promoción',
                precioPromocion: foundPromo?.precio ?? precioUnit,
                precioPersonalizado: precioUnit,
                esCortesia: esCortesia,
                cantidad: cant,
              ),
            );
          } else if (varId != null) {
            PosItem? foundItem;
            for (final pi in _allPosItems) {
              if (pi.variante.id == varId) {
                foundItem = pi;
                break;
              }
            }
            if (foundItem != null) {
              _carrito.add(
                CartItem(
                  producto: foundItem.producto,
                  variante: foundItem.variante,
                  cantidad: cant,
                  precioPersonalizado: precioUnit,
                  esCortesia: esCortesia,
                ),
              );
            }
          }
        }
      }

      await filtrarPorCategoria(_categoriaSeleccionada);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cambiarMetodoPago(int ventaId, String nuevoMetodo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.actualizarMetodoPagoVenta(
        ventaId: ventaId,
        nuevoMetodo: nuevoMetodo,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '').trim();
      notifyListeners();
      return false;
    }
  }
}
