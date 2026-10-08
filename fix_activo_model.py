import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/models/activo_fijo.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_vars = """
  final String? fotoRuta;
  final int activo;

  ActivoFijo({
"""
new_vars = """
  final String? fotoRuta;
  final int activo;
  final String condicion;

  ActivoFijo({
"""
text = text.replace(old_vars, new_vars)

old_cons = """
    this.fotoRuta,
    this.activo = 1,
  });
"""
new_cons = """
    this.fotoRuta,
    this.activo = 1,
    this.condicion = 'Comprado',
  });
"""
text = text.replace(old_cons, new_cons)

old_map = """
      'foto_ruta': fotoRuta,
      'activo': activo,
    };
  }
"""
new_map = """
      'foto_ruta': fotoRuta,
      'activo': activo,
      'condicion': condicion,
    };
  }
"""
text = text.replace(old_map, new_map)

old_from = """
      fotoRuta: map['foto_ruta'],
      activo: map['activo'] ?? 1,
    );
  }
"""
new_from = """
      fotoRuta: map['foto_ruta'],
      activo: map['activo'] ?? 1,
      condicion: map['condicion'] ?? 'Comprado',
    );
  }
"""
text = text.replace(old_from, new_from)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
