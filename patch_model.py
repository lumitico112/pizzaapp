import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/models/activo_fijo.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_vars = """
  final String? fotoRuta;
  final int activo;
  final String condicion;

  ActivoFijo({
"""
new_vars = """
  final String? fotoRuta;
  final int activo;
  final String condicion;
  final String metodoPago;
  final int cuotas;

  ActivoFijo({
"""
text = text.replace(old_vars, new_vars)

old_cons = """
    this.fotoRuta,
    this.activo = 1,
    this.condicion = 'Comprado',
  });
"""
new_cons = """
    this.fotoRuta,
    this.activo = 1,
    this.condicion = 'Comprado',
    this.metodoPago = 'Contado',
    this.cuotas = 1,
  });
"""
text = text.replace(old_cons, new_cons)

old_map = """
      'foto_ruta': fotoRuta,
      'activo': activo,
      'condicion': condicion,
    };
  }
"""
new_map = """
      'foto_ruta': fotoRuta,
      'activo': activo,
      'condicion': condicion,
      'metodo_pago': metodoPago,
      'cuotas': cuotas,
    };
  }
"""
text = text.replace(old_map, new_map)

old_from = """
      fotoRuta: map['foto_ruta'],
      activo: map['activo'] ?? 1,
      condicion: map['condicion'] ?? 'Comprado',
    );
  }
"""
new_from = """
      fotoRuta: map['foto_ruta'],
      activo: map['activo'] ?? 1,
      condicion: map['condicion'] ?? 'Comprado',
      metodoPago: map['metodo_pago'] ?? 'Contado',
      cuotas: map['cuotas'] ?? 1,
    );
  }
"""
text = text.replace(old_from, new_from)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
