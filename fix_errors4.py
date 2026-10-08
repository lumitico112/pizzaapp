import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/caja_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("  Future<void> insertCierre(", "  Future<void> reabrirCaja(String fecha) async {\n    final db = await dbHelper.database;\n    await db.rawUpdate('UPDATE CierreCaja SET cerrado = 0 WHERE fecha = ?', [fecha]);\n  }\n\n  Future<void> insertCierre(")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
