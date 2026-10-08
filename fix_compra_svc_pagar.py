import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/compra_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_pagar = """  Future<void> pagarCuentaPorPagar(int cuentaId, double montoAbono) async {
    // 1. Obtener datos de la cuenta
    final cuentas = await this.obtenerCuentasPorPagar();
    final cuenta = cuentas.firstWhere((c) => c.id == cuentaId);
    
    // 2. Registrar el abono en SQLite
    await _repository.abonarCuenta(cuentaId, montoAbono);
    
    // 3. Registrar el gasto
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _gastoRepo.insertGasto(Gasto(
      categoria: 'Cuentas por Pagar',
      monto: montoAbono,
      descripcion: 'Abono/Pago de: \${cuenta.motivo ?? cuenta.insumoNombre}',
      fecha: hoy,
    ));
  }"""

new_pagar = """  Future<void> pagarCuentaPorPagar(int cuentaId, double montoAbono) async {
    // 1. Obtener datos de la cuenta
    final db = await _repository.dbHelper.database;
    final res = await db.query('CuentasPorPagar', where: 'id = ?', whereArgs: [cuentaId]);
    if (res.isEmpty) throw Exception('Cuenta no encontrada.');
    final row = res.first;
    
    final double costoTotal = (row['costo_total'] as num).toDouble();
    final double pagadoAntes = (row['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final double pendiente = costoTotal - pagadoAntes;
    
    // Limitar el abono al máximo de la cuota
    final double abonoEfectivo = montoAbono > pendiente ? pendiente : montoAbono;
    final double sobrante = montoAbono > pendiente ? (montoAbono - pendiente) : 0.0;
    final double faltante = abonoEfectivo < pendiente ? (pendiente - abonoEfectivo) : 0.0;

    final motivo = row['motivo']?.toString() ?? 'Cuenta';
    final insumoNombre = motivo;
    
    // 2. Registrar el abono en SQLite (con redistribución de sobrante ya en el repo)
    await _repository.abonarCuenta(cuentaId, abonoEfectivo);
    
    // 3. Si pagó de menos, añadir el faltante a la siguiente cuota pendiente
    if (faltante > 0.01) {
      final base = motivo.contains(':') ? motivo.split(':').last.trim() : motivo;
      final siguientes = await db.rawQuery('''
        SELECT * FROM CuentasPorPagar 
        WHERE pagado = 0 AND id != ? AND motivo LIKE ?
        ORDER BY id ASC
        LIMIT 1
      ''', [cuentaId, '%\$base%']);
      
      if (siguientes.isNotEmpty) {
        final sigId = siguientes.first['id'] as int;
        final sigTotal = (siguientes.first['costo_total'] as num).toDouble();
        // Añadir el faltante al costo total de la siguiente cuota
        await db.rawUpdate(
          'UPDATE CuentasPorPagar SET costo_total = ? WHERE id = ?',
          [sigTotal + faltante, sigId]
        );
      }
    }
    
    // 4. Si pagó de más y hay sobrante, ya fue aplicado automáticamente en abonarCuenta
    
    // 5. Registrar el gasto del monto realmente pagado (no el ingresado)
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _gastoRepo.insertGasto(Gasto(
      categoria: 'Cuentas por Pagar',
      monto: abonoEfectivo,
      descripcion: 'Abono: \$insumoNombre',
      fecha: hoy,
    ));
    
    // Si también había sobrante aplicado a la siguiente cuota y esa quedó pagada,
    // se registró automáticamente en abonarCuenta (recursivo).
    if (sobrante > 0.01) {
      await _gastoRepo.insertGasto(Gasto(
        categoria: 'Cuentas por Pagar',
        monto: sobrante,
        descripcion: 'Sobrante aplicado: \$insumoNombre',
        fecha: hoy,
      ));
    }
  }"""

if "pagarCuentaPorPagar" in text:
    text = text.replace(old_pagar, new_pagar)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Done")
