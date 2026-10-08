import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/caja_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

if "reabrirCaja" not in text:
    text = text.replace("Future<int> insertCierre", "Future<void> reabrirCaja(String fecha) async {\n    final db = await dbHelper.database;\n    await db.delete('CierreCaja', where: 'fecha = ?', whereArgs: [fecha]);\n  }\n\n  Future<int> insertCierre")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
