import 'package:pizzaapp/models/gasto.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/models/compra.dart';
import 'package:pizzaapp/models/cuenta_por_pagar.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';

class CompraService {
  final InsumoRepository _repository;
  final GastoRepository _gastoRepo;
  final CajaRepository _cajaRepo;

  CompraService(this._repository, this._gastoRepo, this._cajaRepo);

  Future<List<Compra>> obtenerHistorialCompras() async {
    final maps = await _repository.getHistorialCompras();
    return maps.map((m) => Compra.fromMap(m)).toList();
  }

  Future<List<CuentaPorPagar>> obtenerCuentasPorPagar() async {
    final maps = await _repository.getCuentasPorPagar();
    return maps
        .where((m) => m['pagado'] == 0) // <--- Filtro: solo cuentas pendientes
        .map((m) => CuentaPorPagar.fromMap(m))
        .toList();
  }

  Future<void> registrarCompraDirecta({
    required int insumoId,
    required double cantidad,
    required double costoTotal,
    String? motivo,
    String? facturaRuta,
    String? fecha,
  }) async {
    if (cantidad <= 0 || costoTotal < 0) {
      throw Exception('Cantidad y costo deben ser positivos.');
    }
    await _repository.registrarCompra(
      insumoId, 
      cantidad, 
      costoTotal, 
      motivo,
      facturaRuta: facturaRuta,
      fecha: fecha,
    );

    // Registrar en Caja si hay sesiÃ³n activa (asumiendo que compra directa es en efectivo)
    final sesionActiva = await _cajaRepo.getSesionActiva();
    if (sesionActiva != null && costoTotal > 0) {
      await _cajaRepo.insertMovimiento(MovimientoCaja(
        sesionCajaId: sesionActiva.id!,
        tipo: 'compra',
        metodoPago: 'efectivo', // Asumimos efectivo por defecto para compras directas si no hay selector
        monto: costoTotal,
        descripcion: motivo ?? 'Compra directa',
        fecha: DateTime.now().toIso8601String(),
      ));
    }
  }

  Future<void> registrarCompraPorPagar({
    required int insumoId,
    required double cantidad,
    required double costoTotal,
    String? proveedor,
    String? factura,
    String? facturaRuta,
    double adelanto = 0.0,
    String? fecha,
  }) async {
    if (cantidad <= 0 || costoTotal < 0) {
      throw Exception('Cantidad y costo deben ser positivos.');
    }
    if (adelanto > 0) {
      final hoy = fecha ?? DateTime.now().toIso8601String().split('T')[0];
      await _gastoRepo.insertGasto(Gasto(
        categoria: 'Compras',
        monto: adelanto,
        descripcion: 'Adelanto compra (cuenta por pagar)',
        fecha: hoy,
      ));
      
      // Registrar adelanto en Caja si hay sesiÃ³n activa
      final sesionActiva = await _cajaRepo.getSesionActiva();
      if (sesionActiva != null) {
        await _cajaRepo.insertMovimiento(MovimientoCaja(
          sesionCajaId: sesionActiva.id!,
          tipo: 'compra',
          metodoPago: 'efectivo', // Asumimos efectivo para el adelanto de caja
          monto: adelanto,
          descripcion: 'Adelanto compra a proveedor',
          fecha: DateTime.now().toIso8601String(),
        ));
      }

      costoTotal = costoTotal - adelanto;
    }
    await _repository.registrarCuentaPorPagar(
      insumoId: insumoId,
      cantidad: cantidad,
      costoTotal: costoTotal,
      proveedor: proveedor,
      factura: factura,
      facturaRuta: facturaRuta,
      fecha: fecha,
    );
  }


  Future<List<Map<String, dynamic>>> obtenerGastosRaw() async {
    return await _gastoRepo.getGastosRaw();
  }

  Future<void> pagarCuentaPorPagar(int cuentaId, double montoAbono) async {
    // 1. Obtener datos de la cuenta directamente de la DB
    final db = await _repository.dbHelper.database;
    final res = await db.query('CuentasPorPagar', where: 'id = ?', whereArgs: [cuentaId]);
    if (res.isEmpty) throw Exception('Cuenta no encontrada.');
    final row = res.first;
    
    final double costoTotal = (row['costo_total'] as num).toDouble();
    final double pagadoAntes = (row['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final double pendiente = costoTotal - pagadoAntes;
    final String motivo = row['motivo']?.toString() ?? 'Cuenta';
    
    // Calcular el abono efectivo (no exceder el pendiente de esta cuota)
    final double abonoEfectivo = montoAbono > pendiente ? pendiente : montoAbono;
    final double sobrante = montoAbono > pendiente ? (montoAbono - pendiente) : 0.0;
    final double faltante = abonoEfectivo < pendiente ? (pendiente - abonoEfectivo) : 0.0;
    
    // 2. Registrar el abono en esta cuota
    await _repository.abonarCuenta(cuentaId, abonoEfectivo);
    
    // 3. Si pagÃ³ de MENOS â†’ el faltante se suma al costo de la siguiente cuota
    if (faltante > 0.01) {
      final base = motivo.contains(':') ? motivo.split(':').last.trim() : motivo;
      final siguientes = await db.rawQuery('''
        SELECT * FROM CuentasPorPagar
        WHERE pagado = 0 AND id != ? AND motivo LIKE ?
        ORDER BY id ASC LIMIT 1
      ''', [cuentaId, '%$base%']);
      
      if (siguientes.isNotEmpty) {
        final sigId = siguientes.first['id'] as int;
        final sigTotal = (siguientes.first['costo_total'] as num).toDouble();
        // La siguiente cuota absorbe el faltante
        await db.rawUpdate(
          'UPDATE CuentasPorPagar SET costo_total = ? WHERE id = ?',
          [sigTotal + faltante, sigId]
        );
      }
    }
    
    // 4. Si pagÃ³ de MÃS â†’ el sobrante se abona automÃ¡ticamente a la siguiente cuota
    if (sobrante > 0.01) {
      final base = motivo.contains(':') ? motivo.split(':').last.trim() : motivo;
      final siguientes = await db.rawQuery('''
        SELECT * FROM CuentasPorPagar
        WHERE pagado = 0 AND id != ? AND motivo LIKE ?
        ORDER BY id ASC LIMIT 1
      ''', [cuentaId, '%$base%']);
      
      if (siguientes.isNotEmpty) {
        final sigId = siguientes.first['id'] as int;
        await pagarCuentaPorPagar(sigId, sobrante); // Recursivo, aplica el sobrante
        return; // el gasto ya lo registra la llamada recursiva
      }
    }
    
    // 5. Registrar gasto del monto efectivamente pagado
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _gastoRepo.insertGasto(Gasto(
      categoria: 'Cuentas por Pagar',
      monto: abonoEfectivo,
      descripcion: 'Abono: $motivo',
      fecha: hoy,
    ));

    final sesionActiva = await _cajaRepo.getSesionActiva();
    if (sesionActiva != null) {
      await _cajaRepo.insertMovimiento(MovimientoCaja(
        sesionCajaId: sesionActiva.id!,
        tipo: 'salida',
        metodoPago: 'efectivo',
        monto: abonoEfectivo,
        descripcion: 'Abono CxP: $motivo',
        fecha: DateTime.now().toIso8601String(),
      ));
    }
  }
}



