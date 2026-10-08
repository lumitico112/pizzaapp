# === 1. Expand GastoRepository with raw query method ===
path2 = "C:/D/ProyectoPizza/pizzaapp/lib/repositories/gasto_repository.dart"
with open(path2, "r", encoding="utf-8") as f:
    text2 = f.read()

raw_sql = """
  Future<List<Map<String, dynamic>>> getGastosRaw() async {
    final db = await dbHelper.database;
    final res = await db.query("Gastos", orderBy: "fecha DESC");
    return res;
  }
"""

if "getGastosRaw" not in text2:
    text2 = text2.replace("  Future<int> updateGasto", raw_sql + "\n  Future<int> updateGasto")
    with open(path2, "w", encoding="utf-8") as f:
        f.write(text2)

# === 2. Add method to CompraService ===
path = "C:/D/ProyectoPizza/pizzaapp/lib/services/compra_service.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

new_method = """
  Future<List<Map<String, dynamic>>> obtenerGastosRaw() async {
    return await _gastoRepo.getGastosRaw();
  }

"""
if "obtenerGastosRaw" not in text:
    text = text.replace("  Future<void> pagarCuentaPorPagar", new_method + "  Future<void> pagarCuentaPorPagar")
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

print("Done")
