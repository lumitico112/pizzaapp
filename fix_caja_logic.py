import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/caja_controller.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_method = """
  Future<void> reabrirCaja() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.reabrirCaja();
      await loadResumen();
    } catch(e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
"""
text = text.replace("  Future<bool> cerrarCaja(", new_method + "\n  Future<bool> cerrarCaja(")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

path2 = 'C:/D/ProyectoPizza/pizzaapp/lib/services/caja_service.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

new_method2 = """
  Future<void> reabrirCaja() async {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _cajaRepo.reabrirCaja(hoy);
  }
"""
text2 = text2.replace("  Future<void> cerrarCaja(", new_method2 + "\n  Future<void> cerrarCaja(")

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)

path3 = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/caja_repository.dart'
with open(path3, 'r', encoding='utf-8') as f:
    text3 = f.read()

new_method3 = """
  Future<void> reabrirCaja(String fecha) async {
    final db = await dbHelper.database;
    await db.rawUpdate('UPDATE CierreCaja SET cerrado = 0 WHERE fecha = ?', [fecha]);
  }
"""
text3 = text3.replace("  Future<void> registrarCierre(", new_method3 + "\n  Future<void> registrarCierre(")

with open(path3, 'w', encoding='utf-8') as f:
    f.write(text3)

