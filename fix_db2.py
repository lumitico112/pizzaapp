import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/core/database/database_helper.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_end = """        }
      },
    );
  }

  Future _createDB(Database db, int version) async {"""

new_end = """        }
      },
    );

    // Auto-patch schema
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}

    return database;
  }

  Future _createDB(Database db, int version) async {"""

text = text.replace(old_end, new_end)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
