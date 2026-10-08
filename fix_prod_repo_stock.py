import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/producto_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_logic = """
  Future<void> actualizarStockVariante(int varianteId, int cantidadAjuste) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE VariantesProducto SET stock = stock + ? WHERE id = ?',
      [cantidadAjuste, varianteId]
    );
  }
"""

if "actualizarStockVariante" not in text:
    text = text.replace("Future<int> insertProducto", new_logic + "\n  Future<int> insertProducto")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
