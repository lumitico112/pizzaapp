import 'package:pizzaapp/core/database/database_helper.dart';

class BalanceData {
  final double ventas;
  final double gastos; // Egresos totales (Compras, Cuentas pagadas, Reparaciones, Servicios)
  
  BalanceData({required this.ventas, required this.gastos});
  
  double get ganancia => ventas - gastos;
}

class ProductoRanking {
  final String nombre;
  final int cantidad;
  final double total;
  
  ProductoRanking({required this.nombre, required this.cantidad, required this.total});
}

class ReporteService {
  final _db = DatabaseHelper.instance;

  Future<BalanceData> obtenerBalancePorRango(String fechaInicio, String fechaFin) async {
    final db = await _db.database;

    // 1. Ventas Totales
    final ventasRes = await db.rawQuery('''
      SELECT SUM(total) as suma
      FROM Ventas
      WHERE date(fecha) >= date(?) AND date(fecha) <= date(?)
    ''', [fechaInicio, fechaFin]);
    final ventas = (ventasRes.first['suma'] as num?)?.toDouble() ?? 0.0;

    // 2. Gastos Totales (Compras directas, Pagos a créditos, Reparaciones, etc)
    // El sistema ya guarda TODOS los egresos en la tabla Gastos (incluyendo pagos parciales de cuentas)
    final gastosRes = await db.rawQuery('''
      SELECT SUM(monto) as suma
      FROM Gastos
      WHERE date(fecha) >= date(?) AND date(fecha) <= date(?)
    ''', [fechaInicio, fechaFin]);
    final gastos = (gastosRes.first['suma'] as num?)?.toDouble() ?? 0.0;

    return BalanceData(ventas: ventas, gastos: gastos);
  }

  Future<List<ProductoRanking>> obtenerRankingProductos(String fechaInicio, String fechaFin, {int limite = 5}) async {
    final db = await _db.database;
    final res = await db.rawQuery('''
      SELECT 
        v.nombre_variante as nombre,
        SUM(d.cantidad) as cantidad,
        SUM(d.subtotal) as total
      FROM DetalleVenta d
      JOIN Ventas ve ON d.venta_id = ve.id
      JOIN VariantesProducto v ON d.variante_id = v.id
      WHERE date(ve.fecha) >= date(?) AND date(ve.fecha) <= date(?)
      GROUP BY v.id
      ORDER BY cantidad DESC
      LIMIT ?
    ''', [fechaInicio, fechaFin, limite]);

    return res.map((m) => ProductoRanking(
      nombre: m['nombre'].toString(),
      cantidad: (m['cantidad'] as num).toInt(),
      total: (m['total'] as num).toDouble(),
    )).toList();
  }

  // Agrupación para gráficos
  Future<List<Map<String, dynamic>>> obtenerVentasAgrupadas(String fechaInicio, String fechaFin) async {
    final db = await _db.database;
    // Agrupa por fecha exacta para mostrar tendencia de ventas
    final res = await db.rawQuery('''
      SELECT 
        date(fecha) as dia, 
        SUM(total) as total
      FROM Ventas
      WHERE date(fecha) >= date(?) AND date(fecha) <= date(?)
      GROUP BY dia
      ORDER BY dia ASC
    ''', [fechaInicio, fechaFin]);
    return res;
  }
}
