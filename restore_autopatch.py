import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/core/database/database_helper.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

patch_code = """
    // --- HACKY AUTO-PATCH PARA HOT RESTART ---
    try { await database.execute('CREATE TABLE IF NOT EXISTS CategoriasActivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}
    
    // Insertar categorias iniciales si están vacías
    try {
      final res = await database.query('CategoriasActivo');
      if (res.isEmpty) {
        await database.insert('CategoriasActivo', {'nombre': 'Maquinaria'});
        await database.insert('CategoriasActivo', {'nombre': 'Muebles'});
        await database.insert('CategoriasActivo', {'nombre': 'Tecnología'});
        await database.insert('CategoriasActivo', {'nombre': 'Otros'});
      }
    } catch (_) {}
    // ------------------------------------------
    
    return database;
"""

text = text.replace("return database;", patch_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
