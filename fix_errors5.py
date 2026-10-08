import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/caja_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_logic = "await db.rawUpdate('UPDATE CierreCaja SET cerrado = 0 WHERE fecha = ?', [fecha]);"
new_logic = "await db.delete('CierreCaja', where: 'fecha = ?', whereArgs: [fecha]);"

text = text.replace(old_logic, new_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
