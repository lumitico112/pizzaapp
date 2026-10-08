import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/insumo_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Find the abonarCuenta method and replace with the new version that redistributes
old_abonar = """  Future<void> abonarCuenta(int id, double abono) async {
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
  }"""

new_abonar = """  Future<void> abonarCuenta(int id, double abono) async {
    final db = await dbHelper.database;
    final res = await db.query('CuentasPorPagar', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return;
    
    final row = res.first;
    double pagado = (row['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    double total = (row['costo_total'] as num?)?.toDouble() ?? 0.0;
    final motivo = row['motivo']?.toString() ?? '';
    
    // Cuanto se pago en esta cuota (limitado al máximo de la cuota)
    double nuevoPagado = pagado + abono;
    double diferencia = 0.0; // positivo=pagaste de más, negativo=pagaste de menos
    
    if (nuevoPagado > total) {
      // Pagaste de más: marca cuota como pagada y guarda el sobrante
      diferencia = nuevoPagado - total;
      nuevoPagado = total;
    }
    
    int estadoPagado = nuevoPagado >= total ? 1 : 0;
    final fecha = DateTime.now().toIso8601String().split('T')[0];
    
    await db.rawUpdate(
      'UPDATE CuentasPorPagar SET monto_pagado = ?, pagado = ?, fecha_pago = ? WHERE id = ?',
      [nuevoPagado, estadoPagado, fecha, id]
    );
    
    // Si pagaste de más y hay cuotas pendientes, aplicar sobrante a la siguiente
    if (diferencia > 0) {
      // Buscar las cuotas pendientes del mismo activo/insumo (mismo motivo base)
      // Extraer prefijo del motivo (ej: "Cuota 1/3:" -> buscar otras cuotas del mismo)
      final todasPendientes = await db.rawQuery('''
        SELECT * FROM CuentasPorPagar 
        WHERE pagado = 0 AND id != ? AND motivo LIKE ?
        ORDER BY id ASC
      ''', [id, '%${motivo.contains(':') ? motivo.split(':').last.trim() : motivo}%']);
      
      if (todasPendientes.isNotEmpty) {
        // Aplicar el sobrante a la primera cuota pendiente
        final siguienteCuota = todasPendientes.first;
        final sigId = siguienteCuota['id'] as int;
        await abonarCuenta(sigId, diferencia);
      }
    }
    
    // Si pagaste de menos, recalcular la deuda restante de las otras cuotas
    // Las cuotas siguientes ya son independientes y muestran su saldo original
    // Solo necesitamos redistribuir si se paga de más (lo que ya hacemos arriba)
  }"""

if "abonarCuenta" in text:
    text = text.replace(old_abonar, new_abonar)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Done")
