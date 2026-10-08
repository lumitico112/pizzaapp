import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/reporte_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class ReportesService {
  final dbHelper = DatabaseHelper.instance;

  Future<ReporteData> getReporteGlobal(String fechaInicio, String fechaFin) async {
    final db = await dbHelper.database;
    
    // Total Ingresos (Ventas no anuladas)
    final ventasRes = await db.rawQuery('''
      SELECT SUM(total) as total 
      FROM Ventas 
      WHERE fecha >= ? AND fecha <= ? AND anulada = 0
    ''', [fechaInicio, fechaFin]);
    final totalIngresos = (ventasRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Total Gastos (Movimientos Caja: salidas)
    // Extraemos la fecha del timestamp de movimiento caja.
    final gastosRes = await db.rawQuery('''
      SELECT SUM(monto) as total 
      FROM MovimientosCaja 
      WHERE tipo = 'salida' 
        AND substr(fecha, 1, 10) >= ? 
        AND substr(fecha, 1, 10) <= ?
    ''', [fechaInicio, fechaFin]);
    final totalGastos = (gastosRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Costo de Mercaderia (DetalleVenta join VariantesProducto)
    final costoRes = await db.rawQuery('''
      SELECT SUM(dv.cantidad * vp.costo_estimado_manual) as total_costo
      FROM DetalleVenta dv
      JOIN Ventas v ON dv.venta_id = v.id
      JOIN VariantesProducto vp ON dv.variante_id = vp.id
      WHERE v.fecha >= ? AND v.fecha <= ? AND v.anulada = 0
    ''', [fechaInicio, fechaFin]);
    final costoMercaderia = (costoRes.first['total_costo'] as num?)?.toDouble() ?? 0.0;

    // Productos más vendidos
    final productosRes = await db.rawQuery('''
      SELECT p.nombre || ' ' || vp.nombre_variante as nombre_prod, 
             SUM(dv.cantidad) as cant, 
             SUM(dv.cantidad * dv.precio_unitario) as tot
      FROM DetalleVenta dv
      JOIN Ventas v ON dv.venta_id = v.id
      JOIN VariantesProducto vp ON dv.variante_id = vp.id
      JOIN Productos p ON vp.producto_id = p.id
      WHERE v.fecha >= ? AND v.fecha <= ? AND v.anulada = 0
      GROUP BY vp.id
      ORDER BY cant DESC
      LIMIT 20
    ''', [fechaInicio, fechaFin]);

    List<ProductoVendido> lista = productosRes.map((r) => ProductoVendido(
      nombre: r['nombre_prod'] as String,
      cantidad: (r['cant'] as num).toInt(),
      total: (r['tot'] as num).toDouble(),
    )).toList();

    return ReporteData(
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      costoMercaderia: costoMercaderia,
      beneficioNeto: totalIngresos - totalGastos - costoMercaderia,
      productosVendidos: lista,
    );
  }

  Future<String?> generarReportePDF(ReporteData data, String rangoFechas) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Reporte Financiero', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Período: $rangoFechas'),
              pw.SizedBox(height: 20),
              pw.Text('Resumen', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Ingresos Totales: S/ ${data.totalIngresos.toStringAsFixed(2)}'),
              pw.Text('Costos de Producción: S/ ${data.costoMercaderia.toStringAsFixed(2)}'),
              pw.Text('Gastos (Salidas): S/ ${data.totalGastos.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Text('Beneficio Neto: S/ ${data.beneficioNeto.toStringAsFixed(2)}', 
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)
              ),
              pw.SizedBox(height: 30),
              pw.Text('Top Productos Vendidos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Producto', 'Cantidad', 'Total S/'],
                data: data.productosVendidos.map((p) => [
                  p.nombre,
                  p.cantidad.toString(),
                  p.total.toStringAsFixed(2)
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
