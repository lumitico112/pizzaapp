import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/reporte_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizzaapp/core/utils/pdf_helper.dart';
import 'package:pizzaapp/features/inventory/domain/services/unit_converter.dart';

import 'dart:io';

class ReportesService {
  final DatabaseHelper dbHelper;

  ReportesService({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<ReporteData> getReporteGlobal(
    String fechaInicio,
    String fechaFin,
  ) async {
    final db = await dbHelper.database;

    // Total Ingresos (Ventas no anuladas)
    final ventasRes = await db.rawQuery(
      '''
      SELECT SUM(total) as total 
      FROM Ventas 
      WHERE fecha >= ? AND fecha <= ? AND anulada = 0
    ''',
      [fechaInicio, fechaFin],
    );
    final totalIngresos = (ventasRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Total Gastos (Desde la tabla Gastos para incluir compras, activos, pagos CxP y salidas manuales)
    final gastosRes = await db.rawQuery(
      '''
      SELECT SUM(monto) as total
      FROM Gastos
      WHERE fecha >= ? AND fecha <= ? AND categoria NOT IN ('Compras', 'Activos Fijos', 'Cuentas por Pagar')
    ''',
      [fechaInicio, fechaFin],
    );
    final totalGastos = (gastosRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Costo de Mercaderia Vendida (COGS) segun RN-05 / BR-REP-02:
    // Prioriza el costo calculado automaticamente por la receta activa de la variante
    // (Recetas + Insumos con conversion de unidades).
    // Solo cuando una variante no tenga receta configurada se utiliza costo_estimado_manual como respaldo.

    // 1. Obtener todas las recetas e insumos asociados
    final recetasRows = await db.rawQuery('''
      SELECT r.variante_id, r.cantidad as receta_cantidad, r.unidad_medida as receta_unidad,
             i.costo_por_unidad as insumo_costo, i.unidad_medida as insumo_unidad,
             i.contenido_paquete
      FROM Recetas r
      JOIN Insumos i ON r.insumo_id = i.id
    ''');

    final Map<int, double> costoRecetaPorVariante = {};
    for (final row in recetasRows) {
      final vId = (row['variante_id'] as num).toInt();
      final cant = (row['receta_cantidad'] as num).toDouble();
      final rUnidad = row['receta_unidad'] as String? ?? 'unidad';
      final iUnidad = row['insumo_unidad'] as String? ?? 'unidad';
      final costoUnidad = (row['insumo_costo'] as num?)?.toDouble() ?? 0.0;
      final packContent = (row['contenido_paquete'] as num?)?.toInt() ?? 1;

      double cantidadConvertida = cant;
      try {
        cantidadConvertida = UnitConverter.convert(
          cant,
          rUnidad,
          iUnidad,
          packageContent: packContent,
        );
      } catch (_) {
        // En caso de discrepancia de unidad no convertible, mantener cantidad base
      }
      final costoItem = cantidadConvertida * costoUnidad;
      costoRecetaPorVariante[vId] =
          (costoRecetaPorVariante[vId] ?? 0.0) + costoItem;
    }

    // 2. Precalcular costos de promociones si existen
    final promoItemsRows = await db.rawQuery('''
      SELECT pi.promocion_id, pi.variante_id, pi.insumo_id, pi.cantidad,
             vp.costo_estimado_manual, i.costo_por_unidad
      FROM PromocionItems pi
      LEFT JOIN VariantesProducto vp ON pi.variante_id = vp.id
      LEFT JOIN Insumos i ON pi.insumo_id = i.id
    ''');

    final Map<int, double> costoPorPromocion = {};
    for (final row in promoItemsRows) {
      final pId = (row['promocion_id'] as num).toInt();
      final cant = (row['cantidad'] as num?)?.toDouble() ?? 1.0;
      final vId = (row['variante_id'] as num?)?.toInt();
      final iId = (row['insumo_id'] as num?)?.toInt();

      double itemUnitCost = 0.0;
      if (vId != null) {
        final recipeCost = costoRecetaPorVariante[vId];
        if (recipeCost != null && recipeCost > 0) {
          itemUnitCost = recipeCost;
        } else {
          itemUnitCost =
              (row['costo_estimado_manual'] as num?)?.toDouble() ?? 0.0;
        }
      } else if (iId != null) {
        itemUnitCost = (row['costo_por_unidad'] as num?)?.toDouble() ?? 0.0;
      }
      costoPorPromocion[pId] =
          (costoPorPromocion[pId] ?? 0.0) + (cant * itemUnitCost);
    }

    // 3. Calcular COGS para todas las lineas de venta del periodo
    final detalleVentasRes = await db.rawQuery('''
      SELECT dv.variante_id, dv.promocion_id, dv.cantidad,
             vp.costo_estimado_manual
      FROM DetalleVenta dv
      JOIN Ventas v ON dv.venta_id = v.id
      LEFT JOIN VariantesProducto vp ON dv.variante_id = vp.id
      WHERE v.fecha >= ? AND v.fecha <= ? AND v.anulada = 0
    ''', [fechaInicio, fechaFin]);

    double costoMercaderia = 0.0;
    for (final row in detalleVentasRes) {
      final cant = (row['cantidad'] as num?)?.toDouble() ?? 0.0;
      final vId = (row['variante_id'] as num?)?.toInt();
      final pId = (row['promocion_id'] as num?)?.toInt();

      double costoUnitario = 0.0;
      if (vId != null) {
        final recipeCost = costoRecetaPorVariante[vId];
        if (recipeCost != null && recipeCost > 0) {
          costoUnitario = recipeCost;
        } else {
          costoUnitario =
              (row['costo_estimado_manual'] as num?)?.toDouble() ?? 0.0;
        }
      } else if (pId != null) {
        costoUnitario = costoPorPromocion[pId] ?? 0.0;
      }
      costoMercaderia += cant * costoUnitario;
    }

    // Productos mas vendidos
    final productosRes = await db.rawQuery(
      '''
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
    ''',
      [fechaInicio, fechaFin],
    );

    List<ProductoVendido> lista = productosRes
        .map(
          (r) => ProductoVendido(
            nombre: r['nombre_prod'] as String,
            cantidad: (r['cant'] as num).toInt(),
            total: (r['tot'] as num).toDouble(),
          ),
        )
        .toList();

    return ReporteData(
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      costoMercaderia: costoMercaderia,
      beneficioNeto: totalIngresos - totalGastos - costoMercaderia,
      productosVendidos: lista,
    );
  }

  Future<String?> generarReportePDF(
    ReporteData data,
    String rangoFechas,
  ) async {
    final pdf = pw.Document();

    final totalCantProd = data.productosVendidos.fold<int>(
      0,
      (sum, p) => sum + p.cantidad,
    );
    final totalMontoProd = data.productosVendidos.fold<double>(
      0.0,
      (sum, p) => sum + p.total,
    );
    final margenBruto = data.totalIngresos - data.costoMercaderia;
    final margenPorcentaje = data.totalIngresos > 0
        ? ((data.beneficioNeto / data.totalIngresos) * 100).toStringAsFixed(1)
        : '0.0';
    final ahora = DateTime.now();
    final fechaGenStr =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year} ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

    final colorRed800 = PdfColor.fromHex('#B71C1C');
    final colorRed50 = PdfColor.fromHex('#FFEBEE');
    final colorGreen800 = PdfColor.fromHex('#2E7D32');
    final colorGreen50 = PdfColor.fromHex('#E8F5E9');
    final colorOrange800 = PdfColor.fromHex('#E65100');
    final colorOrange50 = PdfColor.fromHex('#FFF3E0');
    final colorTeal900 = PdfColor.fromHex('#004D40');
    final colorTeal50 = PdfColor.fromHex('#E0F2F1');
    final colorGrey100 = PdfColor.fromHex('#F5F5F5');
    final colorGrey200 = PdfColor.fromHex('#EEEEEE');
    final colorGrey300 = PdfColor.fromHex('#E0E0E0');
    final colorGrey700 = PdfColor.fromHex('#616161');
    final colorGrey800 = PdfColor.fromHex('#424242');
    final colorGrey900 = PdfColor.fromHex('#212121');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: colorRed800, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KIMI PIZZA',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: colorRed800,
                      ),
                    ),
                    pw.Text(
                      'SISTEMA INTEGRAL DE GESTION & POS',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: colorGrey700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: colorRed50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: colorRed800, width: 0.5),
                      ),
                      child: pw.Text(
                        'REPORTE FINANCIERO Y OPERATIVO',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: colorRed800,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Periodo: ${PdfHelper.sanitize(rangoFechas)}',
                      style: pw.TextStyle(fontSize: 8, color: colorGrey700),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: colorGrey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Kimi Pizza POS - Documento confidencial de control interno',
                  style: pw.TextStyle(fontSize: 7.5, color: colorGrey700),
                ),
                pw.Text(
                  'Emitido: $fechaGenStr | Pag. ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: colorGrey700),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // Informacion General Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: colorGrey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: colorGrey300, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Rango analizado: ${PdfHelper.sanitize(rangoFechas)}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: colorGrey800,
                  ),
                ),
                pw.Text(
                  'Moneda: Soles (PEN)',
                  style: pw.TextStyle(fontSize: 8.5, color: colorGrey700),
                ),
                pw.Text(
                  'Fecha Emision: $fechaGenStr',
                  style: pw.TextStyle(fontSize: 8.5, color: colorGrey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Titulo de Seccion: Resumen Ejecutivo
          pw.Text(
            'RESUMEN FINANCIERO EJECUTIVO',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: colorGrey900,
            ),
          ),
          pw.SizedBox(height: 8),

          // 4 Cajas KPI
          pw.Row(
            children: [
              // 1. Ingresos
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: colorGreen50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: colorGreen800, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INGRESOS TOTALES',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: colorGreen800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'S/ ${data.totalIngresos.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: colorGreen800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Ventas cobradas',
                        style: pw.TextStyle(fontSize: 7, color: colorGreen800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              // 2. Costo Mercaderia
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: colorOrange50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: colorOrange800, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'COSTO MERCADERIA',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: colorOrange800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'S/ ${data.costoMercaderia.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: colorOrange800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Insumos de recetas',
                        style: pw.TextStyle(fontSize: 7, color: colorOrange800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              // 3. Gastos Operativos
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: colorRed50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: colorRed800, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GASTOS / SALIDAS',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: colorRed800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'S/ ${data.totalGastos.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: colorRed800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Gastos operativos caja',
                        style: pw.TextStyle(fontSize: 7, color: colorRed800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              // 4. Beneficio Neto
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: data.beneficioNeto >= 0 ? colorTeal50 : colorRed50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: data.beneficioNeto >= 0
                          ? colorTeal900
                          : colorRed800,
                      width: 1.0,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BENEFICIO NETO',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: data.beneficioNeto >= 0
                              ? colorTeal900
                              : colorRed800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'S/ ${data.beneficioNeto.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: data.beneficioNeto >= 0
                              ? colorTeal900
                              : colorRed800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Margen: $margenPorcentaje%',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: data.beneficioNeto >= 0
                              ? colorTeal900
                              : colorRed800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Estado de Resultados Estructurado
          pw.Text(
            'ESTADO DE RESULTADOS (P&L)',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: colorGrey900,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: colorGrey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _buildPdfPlRow(
                  '(+) Ingresos Netos por Ventas',
                  data.totalIngresos,
                ),
                pw.Divider(height: 1, thickness: 0.5, color: colorGrey200),
                _buildPdfPlRow(
                  '(-) Costo de Mercaderia Vendida (COGS)',
                  data.costoMercaderia,
                  isDeduction: true,
                ),
                pw.Divider(height: 1, thickness: 0.5, color: colorGrey200),
                _buildPdfPlRow(
                  '(=) Margen Bruto Operativo',
                  margenBruto,
                  isSubtotal: true,
                ),
                pw.Divider(height: 1, thickness: 0.5, color: colorGrey200),
                _buildPdfPlRow(
                  '(-) Gastos Operativos / Egresos de Caja',
                  data.totalGastos,
                  isDeduction: true,
                ),
                pw.Divider(height: 1, thickness: 1, color: colorGrey300),
                _buildPdfPlRow(
                  '(=) BENEFICIO NETO ESTIMADO',
                  data.beneficioNeto,
                  isTotal: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Seccion: Productos Mas Vendidos
          pw.Text(
            'DETALLE DE PRODUCTOS MAS VENDIDOS',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: colorGrey900,
            ),
          ),
          pw.SizedBox(height: 8),

          if (data.productosVendidos.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: colorGrey100,
                border: pw.Border.all(color: colorGrey200, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'No se registraron ventas en el periodo seleccionado.',
                style: pw.TextStyle(fontSize: 9, color: colorGrey700),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: colorGrey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: colorRed800),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(fontSize: 8, color: colorGrey900),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              headers: [
                '#',
                'PRODUCTO / VARIANTE',
                'CANTIDAD',
                'TOTAL RECAUDADO',
                '% VENTAS',
              ],
              data: [
                for (int i = 0; i < data.productosVendidos.length; i++)
                  [
                    '${i + 1}',
                    PdfHelper.sanitize(data.productosVendidos[i].nombre),
                    '${data.productosVendidos[i].cantidad} un.',
                    'S/ ${data.productosVendidos[i].total.toStringAsFixed(2)}',
                    totalMontoProd > 0
                        ? '${((data.productosVendidos[i].total / totalMontoProd) * 100).toStringAsFixed(1)}%'
                        : '0.0%',
                  ],
                // Fila de Total
                [
                  'TOTAL',
                  'CONSOLIDADO',
                  '$totalCantProd un.',
                  'S/ ${totalMontoProd.toStringAsFixed(2)}',
                  '100.0%',
                ],
              ],
            ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildPdfPlRow(
    String label,
    double amount, {
    bool isDeduction = false,
    bool isSubtotal = false,
    bool isTotal = false,
  }) {
    final colorTeal50 = PdfColor.fromHex('#E0F2F1');
    final colorTeal900 = PdfColor.fromHex('#004D40');
    final colorRed50 = PdfColor.fromHex('#FFEBEE');
    final colorRed800 = PdfColor.fromHex('#B71C1C');
    final colorGrey100 = PdfColor.fromHex('#F5F5F5');
    final colorGrey900 = PdfColor.fromHex('#212121');

    final bgColor = isTotal
        ? (amount >= 0 ? colorTeal50 : colorRed50)
        : (isSubtotal ? colorGrey100 : PdfColors.white);

    final textColor = isTotal
        ? (amount >= 0 ? colorTeal900 : colorRed800)
        : (isDeduction ? colorRed800 : colorGrey900);

    return pw.Container(
      color: bgColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 9.5 : 8.5,
              fontWeight: (isTotal || isSubtotal)
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
          pw.Text(
            'S/ ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: isTotal ? 10 : 8.5,
              fontWeight: (isTotal || isSubtotal)
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
