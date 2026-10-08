import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/caja_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("  Future<void> registrarCierre(", "  Future<void> reabrirCaja() async {\n    final hoy = DateTime.now().toIso8601String().split('T')[0];\n    await _repository.reabrirCaja(hoy);\n  }\n\n  Future<void> registrarCierre(")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
