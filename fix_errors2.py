import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/caja_controller.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# find the actual method to load the summary
if "loadResumen()" in text:
    text = text.replace("await loadCajaEstado();", "await loadResumen();")
elif "loadTotales" in text:
    text = text.replace("await loadCajaEstado();", "await loadTotales();")
else:
    # default to init? Let's check the code
    text = text.replace("await loadCajaEstado();", "await checkEstadoCaja();")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

path2 = 'C:/D/ProyectoPizza/pizzaapp/lib/services/caja_service.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

text2 = text2.replace("Future<void> cerrarCaja(", "Future<void> reabrirCaja() async {\n    final hoy = DateTime.now().toIso8601String().split('T')[0];\n    await _cajaRepo.reabrirCaja(hoy);\n  }\n\n  Future<void> cerrarCaja(")

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)
