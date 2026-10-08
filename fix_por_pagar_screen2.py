import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/compras/por_pagar_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("onPressed: () => _confirmarPago(cuenta.id!, cuenta.motivo ?? 'Compra', cuenta.costoTotal),", "onPressed: () => _confirmarPago(cuenta.id!, cuenta.motivo ?? 'Compra', cuenta.costoTotal, cuenta.montoPagado),")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
