import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/insumo_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_pagar = """  Future<void> pagarCuenta(int id) async {
    final db = await dbHelper.database;
    final fecha = DateTime.now().toIso8601String().split('T')[0];
    await db.rawUpdate('UPDATE CuentasPorPagar SET pagado = 1, fecha_pago = ? WHERE id = ?', [fecha, id]);
  }"""

new_pagar = """  Future<void> abonarCuenta(int id, double abono) async {
    final db = await dbHelper.database;
    final res = await db.query('CuentasPorPagar', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return;
    
    final row = res.first;
    double pagado = (row['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    double total = (row['costo_total'] as num?)?.toDouble() ?? 0.0;
    
    double nuevoPagado = pagado + abono;
    int estadoPagado = nuevoPagado >= total ? 1 : 0;
    
    final fecha = DateTime.now().toIso8601String().split('T')[0];
    
    await db.rawUpdate(
      'UPDATE CuentasPorPagar SET monto_pagado = ?, pagado = ?, fecha_pago = ? WHERE id = ?',
      [nuevoPagado, estadoPagado, fecha, id]
    );
  }

  Future<void> pagarCuenta(int id) async {
    final db = await dbHelper.database;
    final fecha = DateTime.now().toIso8601String().split('T')[0];
    await db.rawUpdate('UPDATE CuentasPorPagar SET pagado = 1, fecha_pago = ? WHERE id = ?', [fecha, id]);
  }"""

if "abonarCuenta" not in text:
    text = text.replace(old_pagar, new_pagar)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
