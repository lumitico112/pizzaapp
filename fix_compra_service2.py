import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/compra_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix BOM
if text.startswith('\ufeff'):
    text = text[1:]

text = text.replace("await _repository.obtenerCuentasPorPagar(soloPendientes: false);", "await this.obtenerCuentasPorPagar(soloPendientes: false);")
text = text.replace("await _repository.obtenerCuentasPorPagar", "await this.obtenerCuentasPorPagar")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
