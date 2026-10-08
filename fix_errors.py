import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/merma_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("  MermaService(this._mermaRepo, this._insumoRepo);", "  final ProductoRepository _prodRepo;\n\n  MermaService(this._mermaRepo, this._insumoRepo, this._prodRepo);")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

path2 = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/caja_controller.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("await loadResumen();", "await loadCajaEstado();")

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text)

path3 = 'C:/D/ProyectoPizza/pizzaapp/lib/services/caja_service.dart'
with open(path3, 'r', encoding='utf-8') as f:
    text = f.read()
if "reabrirCaja" not in text:
    text = text.replace("  Future<void> cerrarCaja", "  Future<void> reabrirCaja() async {\n    final hoy = DateTime.now().toIso8601String().split('T')[0];\n    await _cajaRepo.reabrirCaja(hoy);\n  }\n\n  Future<void> cerrarCaja")
    with open(path3, 'w', encoding='utf-8') as f:
        f.write(text)
