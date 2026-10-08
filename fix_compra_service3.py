import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/compra_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# fix BOM if exists
if text.startswith('\ufeff'):
    text = text[1:]

text = text.replace("await this.obtenerCuentasPorPagar(soloPendientes: false);", "await this.obtenerCuentasPorPagar();")
text = text.replace("Abono/Pago de: ${cuenta.motivo}", "Abono/Pago de: ${cuenta.motivo ?? cuenta.insumoNombre}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text.lstrip('\ufeff'))
