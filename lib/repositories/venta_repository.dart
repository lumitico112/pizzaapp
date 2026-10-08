import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:intl/intl.dart';

class VentaRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> registrarVentaCompleta(Venta venta, List<DetalleVenta> detalles) async {
    final db = await dbHelper.database;
    int ventaId = 0;

    await db.transaction((txn) async {
      // 1. Insertar Cabecera de Venta
      ventaId = await txn.insert('Ventas', venta.toMap());

      // 2. Insertar los Detalles y descontar Stock
      for (var det in detalles) {
        // Enlazar al ID de venta recién creado
        final nuevoDetalle = DetalleVenta(
          ventaId: ventaId,
          varianteId: det.varianteId,
          cantidad: det.cantidad,
          precioUnitario: det.precioUnitario,
          descuento: det.descuento,
        );
        
        await txn.insert('DetalleVenta', nuevoDetalle.toMap());
        
        // Fase 2: Descuento autom.tico de insumos (Receta)
        final recetaItems = await txn.query(
          'ConsumoEstimadoInsumo',
          where: 'variante_id = ?',
          whereArgs: [det.varianteId],
        );

        for (var ri in recetaItems) {
          final insumoId = ri['insumo_id'] as int;
          final cantidadEstimada = ri['cantidad_estimada'] as double;
          final totalADescontar = cantidadEstimada * det.cantidad;

          await txn.rawUpdate('''
            UPDATE Insumos 
            SET stock_actual = stock_actual - ? 
            WHERE id = ?
          ''', [totalADescontar, insumoId]);
        }
      }
    });

    return ventaId;
  }

  Future<Map<String, dynamic>> getResumenHoy() async {
    final db = await dbHelper.database;
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final res = await db.rawQuery('''
      SELECT 
        SUM(total) as ventas_totales 
      FROM Ventas 
      WHERE fecha = ? AND anulada = 0
    ''', [hoy]);

    final gastos = await db.rawQuery('''
      SELECT SUM(monto) as gastos_totales 
      FROM Gastos 
      WHERE fecha = ?
    ''', [hoy]);

    final double ventas = (res.first['ventas_totales'] as num?)?.toDouble() ?? 0.0;
    final double g = (gastos.first['gastos_totales'] as num?)?.toDouble() ?? 0.0;

    return {
      'ventas': ventas,
      'gastos': g,
      'ganancia': ventas - g,
    };
  }
}

