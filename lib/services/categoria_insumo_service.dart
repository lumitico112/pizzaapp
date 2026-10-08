import 'package:pizzaapp/models/categoria_insumo.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';

class CategoriaInsumoService {
  final InsumoRepository _repository;

  CategoriaInsumoService(this._repository);

  Future<List<CategoriaInsumo>> obtenerCategorias() async {
    return await _repository.getCategoriasInsumo();
  }

  Future<void> guardarCategoria(String nombre, {int? idEditar}) async {
    if (nombre.trim().isEmpty) {
      throw Exception('El nombre de la categoría es obligatorio.');
    }
    // Verificar duplicados
    final existentes = await _repository.getCategoriasInsumo();
    final yaExiste = existentes.any(
      (c) => c.nombre.trim().toLowerCase() == nombre.trim().toLowerCase() && c.id != idEditar
    );
    if (yaExiste) {
      throw Exception('La categoría ya existe.');
    }
    final cat = CategoriaInsumo(nombre: nombre.trim());
    await _repository.insertCategoriaInsumo(cat);
  }

  Future<void> eliminarCategoria(int id) async {
    await _repository.deleteCategoriaInsumo(id);
  }
}
