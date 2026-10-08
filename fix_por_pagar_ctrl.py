import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/por_pagar_controller.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("Future<bool> pagarCuenta(int cuentaId) async {", "Future<bool> pagarCuenta(int cuentaId, double montoAbono) async {")
text = text.replace("await _service.pagarCuentaPorPagar(cuentaId);", "await _service.pagarCuentaPorPagar(cuentaId, montoAbono);")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
