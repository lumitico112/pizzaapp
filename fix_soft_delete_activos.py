import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/activo_fijo_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("return await db.delete('ActivosFijos', where: 'id = ?', whereArgs: [id]);", "return await db.update('ActivosFijos', {'activo': 0}, where: 'id = ?', whereArgs: [id]);")
text = text.replace("final res = await db.query('ActivosFijos');", "final res = await db.query('ActivosFijos', where: 'activo = 1');")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
