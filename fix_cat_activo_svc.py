import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/categoria_activo_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_guardar = """  Future<void> guardarCategoria(CategoriaActivo categoria) async {
    if (categoria.nombre.trim().isEmpty) {
      throw Exception('El nombre no puede estar vac\u00c3\u00b3o');
    }
    if (categoria.id == null) {
      await _repo.insertCategoria(categoria);
    } else {
      await _repo.updateCategoria(categoria);
    }
  }"""

new_guardar = """  Future<void> guardarCategoria(CategoriaActivo categoria) async {
    if (categoria.nombre.trim().isEmpty) {
      throw Exception('El nombre no puede estar vacío.');
    }
    // Verificar duplicados
    final existentes = await _repo.getCategorias();
    final yaExiste = existentes.any(
      (c) => c.nombre.trim().toLowerCase() == categoria.nombre.trim().toLowerCase() && c.id != categoria.id
    );
    if (yaExiste) {
      throw Exception('Ya existe una categoría con ese nombre.');
    }
    if (categoria.id == null) {
      await _repo.insertCategoria(categoria);
    } else {
      await _repo.updateCategoria(categoria);
    }
  }"""

text = text.replace(old_guardar, new_guardar)
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
