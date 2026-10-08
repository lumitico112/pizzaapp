import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/core/database/database_helper.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

patch_code = """    // --- HACKY AUTO-PATCH PARA HOT RESTART ---
    try { await database.execute('CREATE TABLE IF NOT EXISTS CategoriasActivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}
    try { await database.execute('ALTER TABLE CuentasPorPagar ADD COLUMN monto_pagado REAL DEFAULT 0'); } catch (_) {}
"""

old_patch = """    // --- HACKY AUTO-PATCH PARA HOT RESTART ---
    try { await database.execute('CREATE TABLE IF NOT EXISTS CategoriasActivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}"""

text = text.replace(old_patch, patch_code)

old_upgrade = """        if (oldVersion < 10) {
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}"""
new_upgrade = """        if (oldVersion < 10) {
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE CuentasPorPagar ADD COLUMN monto_pagado REAL DEFAULT 0'); } catch (_) {}"""
text = text.replace(old_upgrade, new_upgrade)

# also update CREATE TABLE in _createDB
old_table = """              factura_ruta TEXT,
              motivo TEXT,
              pagado INTEGER DEFAULT 0,
              fecha_pago TEXT,
              usuario_id INTEGER
            )"""
new_table = """              factura_ruta TEXT,
              motivo TEXT,
              pagado INTEGER DEFAULT 0,
              monto_pagado REAL DEFAULT 0,
              fecha_pago TEXT,
              usuario_id INTEGER
            )"""
text = text.replace(old_table, new_table)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
