import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/producto_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_guardar = """  Future<void> guardarCategoria(Categoria c) async {
      if (c.nombre.trim().isEmpty) throw Exception('El nombre es requerido');
      if (c.id == null) {
        await _repository.insertCategoria(c);
      } else {
        await _repository.updateCategoria(c);
      }
    }"""

new_guardar = """  Future<void> guardarCategoria(Categoria c) async {
      if (c.nombre.trim().isEmpty) throw Exception('El nombre es requerido.');
      // Verificar duplicados
      final existentes = await _repository.getCategorias();
      final yaExiste = existentes.any(
        (cat) => cat.nombre.trim().toLowerCase() == c.nombre.trim().toLowerCase() && cat.id != c.id
      );
      if (yaExiste) throw Exception('La categoría ya existe.');
      if (c.id == null) {
        await _repository.insertCategoria(c);
      } else {
        await _repository.updateCategoria(c);
      }
    }"""

text = text.replace(old_guardar, new_guardar)
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
