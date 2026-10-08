import 'package:pizzaapp/models/categoria_activo.dart';
import 'package:pizzaapp/repositories/categoria_activo_repository.dart';

class CategoriaActivoService {
  final CategoriaActivoRepository _repo;

  CategoriaActivoService(this._repo);

  Future<List<CategoriaActivo>> obtenerCategorias() async {
    return await _repo.getCategorias();
  }

  Future<void> guardarCategoria(CategoriaActivo categoria) async {
    if (categoria.nombre.trim().isEmpty) {
      throw Exception('El nombre no puede estar vacío');
    }
    if (categoria.id == null) {
      await _repo.insertCategoria(categoria);
    } else {
      await _repo.updateCategoria(categoria);
    }
  }

  Future<void> eliminarCategoria(int id) async {
    await _repo.deleteCategoria(id);
  }
}
