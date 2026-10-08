import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/insumo_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_query = """  Future<List<Map<String, dynamic>>> getCuentasPorPagar() async {
      final db = await dbHelper.database;
      return await db.rawQuery('''
        SELECT c.*, i.nombre as insumo_nombre, i.unidad_medida
        FROM CuentasPorPagar c
        JOIN Insumos i ON c.insumo_id = i.id
        ORDER BY c.pagado ASC, c.fecha DESC
      ''');
    }"""

new_query = """  Future<List<Map<String, dynamic>>> getCuentasPorPagar() async {
      final db = await dbHelper.database;
      return await db.rawQuery('''
        SELECT 
          c.*,
          COALESCE(i.nombre, c.motivo, 'Activo Fijo') as insumo_nombre,
          i.unidad_medida
        FROM CuentasPorPagar c
        LEFT JOIN Insumos i ON c.insumo_id = i.id AND c.insumo_id > 0
        ORDER BY c.pagado ASC, c.fecha DESC
      ''');
    }"""

text = text.replace(old_query, new_query)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Done")
