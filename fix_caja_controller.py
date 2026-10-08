import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/caja_controller.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("await checkEstadoCaja();", "await loadDatosCaja();")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
