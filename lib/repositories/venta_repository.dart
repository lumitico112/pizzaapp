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
          promocionId: det.promocionId,
          cantidad: det.cantidad,
          precioUnitario: det.precioUnitario,
          descuento: det.descuento,
        );
        
        await txn.insert('DetalleVenta', nuevoDetalle.toMap());
        
        // Fase 2: Descuento de PRODUCTO PREPARADO (No de insumos crudos)
        if (det.varianteId != null) {
          // Descontar la variante individual
          await txn.rawUpdate('''
            UPDATE VariantesProducto 
            SET stock = stock - ? 
            WHERE id = ?
          ''', [det.cantidad, det.varianteId]);
        } else if (det.promocionId != null) {
          // Descontar todas las variantes dentro de esta promoción
          final promoVariantes = await txn.query(
            'PromocionVariantes',
            where: 'promo_id = ?',
            whereArgs: [det.promocionId],
          );
          for (var pv in promoVariantes) {
            final varId = pv['variante_id'] as int;
            final cantIncluida = (pv['cantidad'] as num).toInt();
            final totalADescontar = cantIncluida * det.cantidad;
            
            await txn.rawUpdate('''
              UPDATE VariantesProducto 
              SET stock = stock - ? 
              WHERE id = ?
            ''', [totalADescontar, varId]);
          }
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
