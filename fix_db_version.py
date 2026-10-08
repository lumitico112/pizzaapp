import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/core/database/database_helper.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("version: 9,", "version: 10,")

old_upgrade = """        if (oldVersion < 6) {"""
new_upgrade = """        if (oldVersion < 10) {
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}
          
          await db.execute('CREATE TABLE IF NOT EXISTS CategoriasActivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)');
          try {
            await db.insert('CategoriasActivo', {'nombre': 'Maquinaria'});
            await db.insert('CategoriasActivo', {'nombre': 'Muebles'});
            await db.insert('CategoriasActivo', {'nombre': 'Tecnología'});
            await db.insert('CategoriasActivo', {'nombre': 'Otros'});
          } catch (_) {}
        }
        if (oldVersion < 6) {"""
text = text.replace(old_upgrade, new_upgrade)

# Also remove the hacky auto-patch block at the end of _initDB if it exists, to avoid issues.
old_hack = """    // Auto-patch schema
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}"""
text = text.replace(old_hack, "")

# Ensure createDB has them
if "CREATE TABLE CategoriasActivo" not in text:
    old_create = """      // 16. Historial Precios"""
    new_create = """      // 16. CategoriasActivos
      await db.execute('''
        CREATE TABLE CategoriasActivo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL
        )
      ''');
      await db.insert('CategoriasActivo', {'nombre': 'Maquinaria'});
      await db.insert('CategoriasActivo', {'nombre': 'Muebles'});
      
      // 17. Historial Precios"""
    text = text.replace(old_create, new_create)

# In createDB for ActivosFijos, ensure the columns are there
old_activos_table = """        CREATE TABLE ActivosFijos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          categoria TEXT,
          costo REAL DEFAULT 0,
          fecha_adquisicion TEXT,
          estado TEXT DEFAULT 'Bueno',
          observaciones TEXT,
          foto_ruta TEXT,
          activo INTEGER DEFAULT 1
        )"""
new_activos_table = """        CREATE TABLE ActivosFijos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          categoria TEXT,
          costo REAL DEFAULT 0,
          fecha_adquisicion TEXT,
          estado TEXT DEFAULT 'Bueno',
          condicion TEXT DEFAULT 'Comprado',
          metodo_pago TEXT DEFAULT 'Contado',
          cuotas INTEGER DEFAULT 1,
          cantidad INTEGER DEFAULT 1,
          observaciones TEXT,
          foto_ruta TEXT,
          activo INTEGER DEFAULT 1
        )"""
text = text.replace(old_activos_table, new_activos_table)

old_variantes = """        CREATE TABLE VariantesProducto (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          producto_id INTEGER REFERENCES Productos(id) ON DELETE CASCADE,
          nombre_variante TEXT NOT NULL,
          precio_venta REAL NOT NULL,
          costo_estimado_manual REAL,
          empaque_insumo_id INTEGER REFERENCES Insumos(id)
        )"""
new_variantes = """        CREATE TABLE VariantesProducto (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          producto_id INTEGER REFERENCES Productos(id) ON DELETE CASCADE,
          nombre_variante TEXT NOT NULL,
          precio_venta REAL NOT NULL,
          costo_estimado_manual REAL,
          empaque_insumo_id INTEGER REFERENCES Insumos(id),
          imagen TEXT,
          stock INTEGER DEFAULT 0
        )"""
text = text.replace(old_variantes, new_variantes)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
