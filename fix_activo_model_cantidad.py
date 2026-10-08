import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/models/activo_fijo.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final int cuotas;", "final int cuotas;\n  final int cantidad;")
text = text.replace("this.cuotas = 1,", "this.cuotas = 1,\n    this.cantidad = 1,")
text = text.replace("'cuotas': cuotas,", "'cuotas': cuotas,\n      'cantidad': cantidad,")
text = text.replace("cuotas: map['cuotas'] ?? 1,", "cuotas: map['cuotas'] ?? 1,\n      cantidad: map['cantidad'] ?? 1,")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
