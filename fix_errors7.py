import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/caja_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# restore insertCierre and add reabrirCaja
old_part = "Future<void> insertCierre("
new_part = """
  Future<void> insertCierre(CierreCaja cierre) async {
    final db = await dbHelper.database;
    await db.insert('CierreCaja', cierre.toMap());
  }

  Future<void> reabrirCaja(String fecha) async {
    final db = await dbHelper.database;
    await db.delete('CierreCaja', where: 'fecha = ?', whereArgs: [fecha]);
  }

  Future<void> dummy_method_do_not_call_insertCierre("""

if "insertCierre(CierreCaja cierre)" not in text:
    text = text.replace("Future<void> reabrirCaja(String fecha) async {", new_part + "Future<void> reabrirCaja(String fecha) async {")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
