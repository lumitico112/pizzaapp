import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';

class ProductoService {
  final ProductoRepository _repository;

  ProductoService(this._repository);

  // --- CATEGORÍAS ---
  Future<List<Categoria>> getCategorias() async {
    return await _repository.getCategorias();
  }

  Future<void> guardarCategoria(Categoria c) async {
    if (c.nombre.trim().isEmpty) throw Exception('El nombre es requerido');
    if (c.id == null) {
      await _repository.insertCategoria(c);
    } else {
      await _repository.updateCategoria(c);
    }
  }

  Future<void> eliminarCategoria(int id) async {
    await _repository.deleteCategoria(id);
  }

  // --- PRODUCTOS ---
  Future<List<Producto>> getProductos({int? categoriaId}) async {
    return await _repository.getProductos(categoriaId: categoriaId);
  }

  Future<void> guardarProductoCompleto(Producto p, List<VarianteProducto> variantes) async {
    if (p.nombre.trim().isEmpty) throw Exception('El nombre del producto es requerido');
    if (variantes.isEmpty) throw Exception('Debe existir al menos una variante (Ej. Tamaño o Porción)');

    for (var v in variantes) {
      if (v.nombreVariante.trim().isEmpty) throw Exception('Todas las variantes deben tener un nombre');
      if (v.precioVenta < 0) throw Exception('El precio no puede ser negativo');
    }

    await _repository.guardarProductoCompleto(p, variantes);
  }

  Future<void> eliminarProducto(int id) async {
    await _repository.deleteProducto(id);
  }

  // --- VARIANTES & RECETAS ---
  Future<List<VarianteProducto>> getVariantes(int productoId) async {
    return await _repository.getVariantesPorProducto(productoId);
  }
}
