import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/categoria_insumo_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_guardar = """  Future<void> guardarCategoria(String nombre) async {
    if (nombre.trim().isEmpty) {
      throw Exception('El nombre de la categoria es obligatorio.');
    }
    final cat = CategoriaInsumo(nombre: nombre.trim());
    await _repository.insertCategoriaInsumo(cat);
  }"""

new_guardar = """  Future<void> guardarCategoria(String nombre, {int? idEditar}) async {
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
  }"""

text = text.replace(old_guardar, new_guardar)
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
