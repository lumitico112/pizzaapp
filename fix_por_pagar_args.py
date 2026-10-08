import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/compras/por_pagar_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("_confirmarPago(c.id, c.insumoNombre, c.costoTotal),", "_confirmarPago(c.id, c.insumoNombre, c.costoTotal, c.montoPagado),")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
