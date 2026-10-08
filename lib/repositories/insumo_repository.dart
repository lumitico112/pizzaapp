import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/models/categoria_insumo.dart';



class InsumoRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertInsumo(Insumo insumo) async {
    final db = await dbHelper.database;
    return await db.insert('Insumos', insumo.toMap());
  }

  Future<List<Insumo>> getInsumos() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Insumos', where: 'activo = 1');
    return List.generate(maps.length, (i) => Insumo.fromMap(maps[i]));
  }

  Future<int> updateInsumo(Insumo insumo) async {
    final db = await dbHelper.database;
    return await db.update('Insumos', insumo.toMap(), where: 'id = ?', whereArgs: [insumo.id]);
  }

  Future<int> deleteInsumo(int id) async {
    final db = await dbHelper.database;
    return await db.update('Insumos', {'activo': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CategoriaInsumo>> getCategoriasInsumo() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('CategoriasInsumo');
    return List.generate(maps.length, (i) => CategoriaInsumo.fromMap(maps[i]));
  }

  Future<int> insertCategoriaInsumo(CategoriaInsumo cat) async {
    final db = await dbHelper.database;
    return await db.insert('CategoriasInsumo', cat.toMap());
  }

  Future<int> deleteCategoriaInsumo(int id) async {
    final db = await dbHelper.database;
    return await db.delete('CategoriasInsumo', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> ajustarStock({
    required int insumoId,
    required double cantidadAjuste,
    String? tipoAdquisicion,
    String? motivo,
    double costoUnitario = 0,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final fecha = DateTime.now().toIso8601String();
      await txn.insert('AjustesStock', {
        'fecha': fecha,
        'insumo_id': insumoId,
        'cantidad_ajuste': cantidadAjuste,
        'tipo_adquisicion': tipoAdquisicion ?? 'ajuste',
        'costo_unitario': costoUnitario,
        'motivo': motivo ?? 'Ajuste manual',
      });

      final maps = await txn.query('Insumos', where: 'id = ?', whereArgs: [insumoId]);
      if (maps.isNotEmpty) {
        final insumo = Insumo.fromMap(maps.first);
        final nuevoStock = insumo.stockActual + cantidadAjuste;
        
        double nuevoCosto = insumo.costoPorUnidad;
        if (tipoAdquisicion == 'comprado' && cantidadAjuste > 0) {
           final stockPrevio = insumo.stockActual > 0 ? insumo.stockActual : 0;
           final valorPrevio = stockPrevio * insumo.costoPorUnidad;
           final valorNuevo = cantidadAjuste * costoUnitario;
           final stockTotal = stockPrevio + cantidadAjuste;
           if (stockTotal > 0) {
              nuevoCosto = (valorPrevio + valorNuevo) / stockTotal;
           }
        }

        await txn.update(
          'Insumos', 
          {'stock_actual': nuevoStock, 'costo_por_unidad': nuevoCosto}, 
          where: 'id = ?', 
          whereArgs: [insumoId]
        );
      }
    });
  }

  Future<void> registrarCompra(int insumoId, double cantidadComprada, double costoTotal, String? motivo, {String? facturaRuta, String? fecha}) async {
    final db = await dbHelper.database;
    final row = await db.query('Insumos', where: 'id = ?', whereArgs: [insumoId]);
    if (row.isEmpty) return;
    
    final actual = (row.first['stock_actual'] as num).toDouble();
    final costoUnitarioAntiguo = (row.first['costo_por_unidad'] as num).toDouble();
    
    final stockAntiguoTotal = actual > 0 ? actual : 0;
    final nuevoCostoUnitario = ((stockAntiguoTotal * costoUnitarioAntiguo) + costoTotal) / (stockAntiguoTotal + cantidadComprada);

    await db.update('Insumos', {
      'stock_actual': actual + cantidadComprada,
      'costo_por_unidad': nuevoCostoUnitario,
    }, where: 'id = ?', whereArgs: [insumoId]);

    final fechaIngreso = fecha ?? DateTime.now().toIso8601String();
    await db.insert('AjustesStock', {
      'fecha': fechaIngreso,
      'insumo_id': insumoId,
      'cantidad_ajuste': cantidadComprada,
      'tipo_adquisicion': 'comprado',
      'costo_unitario': costoTotal / cantidadComprada,
      'motivo': motivo ?? 'Compra',
    });
    
    await db.insert('Gastos', {
      'fecha': fechaIngreso,
      'categoria': 'Compras',
      'descripcion': 'Compra: ${motivo ?? ''}',
      'monto': costoTotal,
      'insumo_id': insumoId
    });
  }
  Future<void> registrarCuentaPorPagar({
    required int insumoId,
    required double cantidad,
    required double costoTotal,
    String? proveedor,
    String? factura,
    String? facturaRuta,
    String? fecha,
  }) async {
    final db = await dbHelper.database;
    await db.insert('CuentasPorPagar', {
      'fecha': fecha ?? DateTime.now().toIso8601String(),
      'insumo_id': insumoId,
      'cantidad': cantidad,
      'costo_total': costoTotal,
      'proveedor': proveedor,
      'motivo': factura,
      'factura_ruta': facturaRuta,
      'pagado': 0,
    });
  }

  Future<void> abonarCuenta(int id, double abono) async {
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
  }

  Future<void> pagarCuenta(int cuentaId) async {
    final db = await dbHelper.database;
    final cuentas = await db.query('CuentasPorPagar', where: 'id = ?', whereArgs: [cuentaId]);
    if (cuentas.isEmpty) return;
    final cuenta = cuentas.first;
    
    // Marcar como pagado
    await db.update('CuentasPorPagar', {
      'pagado': 1,
      'fecha_pago': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [cuentaId]);

    // Solo actualizar el stock si es una compra de insumo (insumo_id > 0)
    final insumoId = cuenta['insumo_id'] as int? ?? 0;
    if (insumoId > 0) {
      await registrarCompra(
        insumoId,
        (cuenta['cantidad'] as num).toDouble(),
        (cuenta['costo_total'] as num).toDouble(),
        cuenta['motivo']?.toString() ?? 'Pago de cuenta',
        facturaRuta: cuenta['factura_ruta']?.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCuentasPorPagar() async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        c.*,
        COALESCE(i.nombre, c.motivo, 'Activo Fijo') as insumo_nombre,
        i.unidad_medida
      FROM CuentasPorPagar c
      LEFT JOIN Insumos i ON c.insumo_id = i.id AND c.insumo_id > 0
      ORDER BY c.pagado ASC, c.fecha DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getHistorialCompras() async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT a.*, COALESCE(i.nombre, a.motivo, 'Activo Fijo') as insumo_nombre, COALESCE(i.unidad_medida, 'Und') as unidad_medida 
      FROM AjustesStock a
      LEFT JOIN Insumos i ON a.insumo_id = i.id
      WHERE a.tipo_adquisicion = 'comprado'
      ORDER BY a.fecha DESC
    ''');
  }
}


