import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizzaapp/core/utils/pdf_helper.dart';
import 'package:pizzaapp/models/reporte_data.dart';

/// Exportación del PDF del reporte financiero (H-04c).
///
/// El rango mostrado se toma de [ReporteData.periodo], de modo que los datos y
/// el texto del período siempre corresponden a la misma consulta.
class ReportesPdf {
  const ReportesPdf._();

  /// Construye el PDF y lo escribe en disco devolviendo su ruta.
  ///
  /// [outputDirectory] es un punto de inyección para pruebas; en producción
  /// se usa el directorio temporal de la aplicación.
  static Future<String?> generarPDF(
    ReporteData data, {
    Directory? outputDirectory,
  }) async {
    final pdf = pw.Document();
    final periodoLabel = PdfHelper.sanitize(data.periodo.pdfLabel);

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
                      'Periodo: $periodoLabel',
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
                  'Rango analizado: $periodoLabel',
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

    final output = outputDirectory ?? await getTemporaryDirectory();
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
