import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/models/cuenta_por_pagar.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final String? fechaPago;", "final String? fechaPago;\n  final double montoPagado;")
text = text.replace("this.fechaPago,", "this.fechaPago,\n    this.montoPagado = 0.0,")
text = text.replace("'fecha_pago': fechaPago,", "'fecha_pago': fechaPago,\n      'monto_pagado': montoPagado,")
text = text.replace("fechaPago: map['fecha_pago'],", "fechaPago: map['fecha_pago'],\n      montoPagado: (map['monto_pagado'] as num?)?.toDouble() ?? 0.0,")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
