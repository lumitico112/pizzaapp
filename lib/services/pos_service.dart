import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/core/utils/pdf_helper.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';

class PosItem {
  final Producto producto;
  final VarianteProducto variante;
  PosItem(this.producto, this.variante);
}

class CartItem {
  final Producto? producto;
  final VarianteProducto? variante;
  int cantidad;
  double? precioPersonalizado;
  bool esCortesia;
  bool esPromocion;
  int? promocionId;
  String? nombrePromocion;
  double? precioPromocion;

  CartItem({
    this.producto,
    this.variante,
    this.cantidad = 1,
    this.precioPersonalizado,
    this.esCortesia = false,
    this.esPromocion = false,
    this.promocionId,
    this.nombrePromocion,
    this.precioPromocion,
  });

  double get total => esCortesia
      ? 0.0
      : ((precioPersonalizado ??
                (esPromocion
                    ? (precioPromocion ?? 0.0)
                    : (variante?.precioVenta ?? 0.0))) *
            cantidad);
  double get precioFinal => esCortesia
      ? 0.0
      : (precioPersonalizado ??
            (esPromocion
                ? (precioPromocion ?? 0.0)
                : (variante?.precioVenta ?? 0.0)));
}

class PosService {
  final ProductoRepository _productoRepo;
  final VentaRepository _ventaRepo;
  final CajaRepository _cajaRepo;
  final PromocionRepository _promocionRepo;

  PosService(
    this._productoRepo,
    this._ventaRepo,
    this._cajaRepo,
    this._promocionRepo,
  );

  Future<List<Promocion>> getPromociones() => _promocionRepo.getPromociones();

  Future<List<Categoria>> getCategorias() async {
    return await _productoRepo.getCategorias();
  }

  Future<List<PosItem>> getPosItems(int? categoriaId) async {
    final prods = await _productoRepo.getProductos(categoriaId: categoriaId);
    List<PosItem> flatItems = [];
    for (var p in prods) {
      final vars = await _productoRepo.getVariantesPorProducto(p.id!);
      for (var v in vars) {
        flatItems.add(PosItem(p, v));
      }
    }
    return flatItems;
  }

  Future<String?> registrarVenta({
    required List<CartItem> carrito,
    required String metodoPago,
    required double totalCalculado,
    required String observaciones,
    String? fechaPersonalizada,
    double? montoRecibido,
  }) async {
    if (carrito.isEmpty) {
      throw Exception('El carrito está vacío.');
    }

    final esSoloCortesia =
        totalCalculado <= 0 || carrito.every((item) => item.esCortesia);
    final metodoPagoFinal = esSoloCortesia
        ? 'efectivo'
        : (metodoPago.isEmpty ? 'efectivo' : metodoPago);

    if (!esSoloCortesia &&
        metodoPagoFinal == 'efectivo' &&
        montoRecibido != null &&
        montoRecibido < totalCalculado) {
      throw Exception('El monto recibido no cubre el total de la venta.');
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final requestedDate = DateTime.tryParse(
      fechaPersonalizada ?? now.toIso8601String().split('T')[0],
    );
    if (requestedDate == null) {
      throw Exception('La fecha de venta no es válida.');
    }
    final saleDay = DateTime(
      requestedDate.year,
      requestedDate.month,
      requestedDate.day,
    );
    if (saleDay.isAfter(today)) {
      throw Exception('No se pueden registrar ventas con fecha futura.');
    }
    final fecha = saleDay.toIso8601String().split('T')[0];
    final esHistorica = saleDay.isBefore(today);

    if (!esHistorica &&
        !esSoloCortesia &&
        await _cajaRepo.getSesionActiva() == null) {
      throw Exception('Abre una caja antes de registrar ventas.');
    }

    String notasFinales = observaciones;
    if (esHistorica) {
      notasFinales = notasFinales.isEmpty
          ? '[REGISTRO HISTÓRICO]'
          : '[REGISTRO HISTÓRICO] $notasFinales';
    }
    if (carrito.any((item) => item.esCortesia)) {
      notasFinales = (notasFinales.isEmpty)
          ? "(Cortesía)"
          : "$notasFinales (Cortesía)";
    }

    final venta = Venta(
      fecha: fecha,
      hora: esHistorica
          ? '00:00'
          : "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      subtotal: totalCalculado,
      total: totalCalculado,
      metodoPago: metodoPagoFinal,
      montoRecibido: !esSoloCortesia &&
              metodoPagoFinal == 'efectivo' &&
              montoRecibido != null
          ? montoRecibido
          : 0.0,
      vuelto: !esSoloCortesia &&
              metodoPagoFinal == 'efectivo' &&
              montoRecibido != null
          ? montoRecibido - totalCalculado
          : 0.0,
      nota: notasFinales,
    );

    final detalles = carrito
        .map(
          (item) => DetalleVenta(
            ventaId: 0, // El repository lo autogenera
            varianteId: item.variante?.id,
            promocionId: item.promocionId,
            cantidad: item.cantidad,
            precioUnitario: item.precioFinal,
            esCortesia: item.esCortesia,
          ),
        )
        .toList();

    int ventaId = await _ventaRepo.registrarVentaCompleta(
      venta,
      detalles,
      historica: esHistorica,
    );

    final ventaRegistrada = Venta(
      id: ventaId,
      fecha: venta.fecha,
      hora: venta.hora,
      subtotal: venta.subtotal,
      total: venta.total,
      metodoPago: venta.metodoPago,
      montoRecibido: venta.montoRecibido,
      vuelto: venta.vuelto,
      nota: venta.nota,
    );

    return await generarBoletaPDF(ventaRegistrada, detalles, carrito);
  }

  Future<String?> generarBoletaPDF(
    Venta venta,
    List<DetalleVenta> detalles, [
    List<CartItem>? carrito,
  ]) async {
    final configRepo = ConfiguracionRepository();
    final nombreNegocio =
        await configRepo.getConfig('nombre_negocio') ?? 'KIMI PIZZA';
    final identificacion = await configRepo.getConfig('ruc_dni') ?? '';
    final direccion = await configRepo.getConfig('direccion_negocio') ?? '';
    final telefono = await configRepo.getConfig('telefono_negocio') ?? '';
    final mensajeTicket = await configRepo.getConfig('mensaje_ticket') ?? '';
    final logoRuta = await configRepo.getConfig('logo_ruta');
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    if (logoRuta != null && logoRuta.trim().isNotEmpty) {
      final logoFile = File(logoRuta.trim());
      if (await logoFile.exists()) {
        try {
          logo = pw.MemoryImage(await logoFile.readAsBytes());
        } catch (_) {
          // Si la imagen configurada no puede leerse, se conserva el encabezado.
        }
      }
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final boletasDir = Directory('${docsDir.path}/boletas');
    if (!await boletasDir.exists()) {
      await boletasDir.create(recursive: true);
    }

    final ticketNum = 'B001-${(venta.id ?? 1).toString().padLeft(6, '0')}';
    final fechaHoraStr = '${venta.fecha} ${venta.hora}';

    final colorPrimary = PdfColor.fromHex('#D62828');
    final colorText = PdfColor.fromHex('#1F2937');
    final colorMuted = PdfColor.fromHex('#6B7280');
    final colorLine = PdfColor.fromHex('#E5E7EB');
    final colorLight = PdfColor.fromHex('#F3F4F6');
    final igvIncluido = double.parse(
      (venta.total * 18 / 118).toStringAsFixed(2),
    );
    final baseImponible = venta.total - igvIncluido;
    final filas = <List<String>>[
      for (int i = 0; i < detalles.length; i++)
        [
          '${detalles[i].cantidad}',
          carrito != null && i < carrito.length
              ? (carrito[i].esPromocion
                    ? PdfHelper.sanitize(
                        'PROMO: ${carrito[i].nombrePromocion ?? 'Combo'}',
                      )
                    : PdfHelper.sanitize(
                        '${((carrito[i].variante?.nombreVariante.toLowerCase().contains('vaso') ?? false)) ? '${detalles[i].cantidad} vaso(s) de ${carrito[i].producto?.nombre ?? 'Bebida'}' : '${carrito[i].producto?.nombre ?? 'Producto'} - ${carrito[i].variante?.nombreVariante ?? ''}'}${carrito[i].esCortesia ? ' (CORTESIA)' : ''}',
                      ))
              : '${detalles[i].promocionId != null ? 'Promocion Combo' : 'Producto #${detalles[i].varianteId ?? (i + 1)}'}${detalles[i].esCortesia ? ' (CORTESIA)' : ''}',
          'S/ ${detalles[i].precioUnitario.toStringAsFixed(2)}',
          'S/ ${(detalles[i].cantidad * detalles[i].precioUnitario).toStringAsFixed(2)}',
        ],
    ];
    final esCortesia = venta.total <= 0 ||
        venta.metodoPago.toLowerCase().contains('cortes');
    final esEfectivo =
        !esCortesia && venta.metodoPago.toLowerCase().contains('efectivo');
    final pagoRecibido = venta.montoRecibido;
    final vuelto = venta.vuelto ?? 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Divider(thickness: 0.7, color: colorLine),
            pw.SizedBox(height: 5),
            pw.Text(
              PdfHelper.sanitize(
                mensajeTicket.trim().isNotEmpty
                    ? mensajeTicket.trim()
                    : 'Gracias por su preferencia. Vuelva pronto.',
              ),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: colorText,
              ),
            ),
            pw.Text(
              'Representacion impresa de la Boleta de Venta Electronica',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8, color: colorMuted),
            ),
            pw.Text(
              'Kimi Pizza POS - Sistema de Gestion Comercial',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 7.5, color: colorMuted),
            ),
          ],
        ),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                if (logo != null)
                  pw.Container(
                    width: 54,
                    height: 54,
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: colorLine),
                    ),
                    child: pw.ClipOval(
                      child: pw.Image(logo, fit: pw.BoxFit.cover),
                    ),
                  ),
                if (logo != null) pw.SizedBox(height: 6),
                pw.Text(
                  PdfHelper.sanitize(nombreNegocio),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 21,
                    fontWeight: pw.FontWeight.bold,
                    color: colorPrimary,
                  ),
                ),
                pw.SizedBox(height: 5),
                if (identificacion.trim().isNotEmpty)
                  pw.Text(
                    'RUC / DNI: ${PdfHelper.sanitize(identificacion.trim())}',
                    style: pw.TextStyle(fontSize: 9, color: colorMuted),
                  ),
                if (direccion.trim().isNotEmpty)
                  pw.Text(
                    PdfHelper.sanitize(direccion.trim()),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9, color: colorMuted),
                  ),
                if (telefono.trim().isNotEmpty)
                  pw.Text(
                    'Telf: ${PdfHelper.sanitize(telefono.trim())}',
                    style: pw.TextStyle(fontSize: 9, color: colorMuted),
                  ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: pw.BoxDecoration(
                    color: colorLight,
                    border: pw.Border.all(color: colorLine),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'BOLETA DE VENTA ELECTRONICA: $ticketNum',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: colorLine),
                bottom: pw.BorderSide(color: colorLine),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfReceiptMeta(
                        'FECHA EMISION',
                        fechaHoraStr,
                        colorText,
                        colorMuted,
                      ),
                      pw.SizedBox(height: 5),
                      _pdfReceiptMeta(
                        'MONEDA',
                        'SOLES (S/)',
                        colorText,
                        colorMuted,
                      ),
                    ],
                  ),
                ),
                pw.Container(width: 1, height: 48, color: colorLine),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'METODO DE PAGO: ',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: colorText,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: pw.BoxDecoration(
                              color: colorLight,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              PdfHelper.sanitize(
                                esCortesia
                                    ? 'CORTESIA'
                                    : venta.metodoPago.toUpperCase(),
                              ),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: colorText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (esEfectivo) ...[
                        pw.SizedBox(height: 5),
                        _pdfReceiptMeta(
                          'PAGO CON',
                          'S/ ${(pagoRecibido ?? venta.total).toStringAsFixed(2)}',
                          colorText,
                          colorMuted,
                        ),
                        pw.SizedBox(height: 3),
                        _pdfReceiptMeta(
                          'VUELTO',
                          'S/ ${vuelto.toStringAsFixed(2)}',
                          colorPrimary,
                          colorMuted,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: colorLine, width: 0.55),
              bottom: pw.BorderSide(color: colorLine, width: 0.7),
            ),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: colorPrimary),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 9, color: colorText),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 7,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.65),
              1: const pw.FlexColumnWidth(4.0),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(1.1),
            },
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: ['CANT.', 'DESCRIPCION', 'P. UNIT.', 'TOTAL'],
            data: filas,
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _pdfReceiptTotalRow(
                    'Op. Gravada:',
                    'S/ ${baseImponible.toStringAsFixed(2)}',
                    colorMuted,
                  ),
                  pw.SizedBox(height: 5),
                  _pdfReceiptTotalRow(
                    'I.G.V. (18% incluido):',
                    'S/ ${igvIncluido.toStringAsFixed(2)}',
                    colorMuted,
                  ),
                  if (venta.descuento > 0) ...[
                    pw.SizedBox(height: 5),
                    _pdfReceiptTotalRow(
                      'Descuento:',
                      '- S/ ${venta.descuento.toStringAsFixed(2)}',
                      colorPrimary,
                    ),
                  ],
                  pw.SizedBox(height: 9),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: colorPrimary,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL A PAGAR',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'S/ ${venta.total.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (venta.nota != null && venta.nota!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'OBSERVACION: ${PdfHelper.sanitize(venta.nota!.trim())}',
              style: pw.TextStyle(fontSize: 9, color: colorMuted),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: 74,
                height: 74,
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: colorLine),
                ),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'KIMI-BOLETA|$ticketNum|VENTA:${venta.id ?? 0}',
                  drawText: false,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CONSULTA INTERNA',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: colorMuted,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data:
                          'CODE:${(venta.id ?? 0).toString().padLeft(10, '0')}',
                      width: 190,
                      height: 36,
                      drawText: false,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'CODE:${(venta.id ?? 0).toString().padLeft(10, '0')}',
                      style: pw.TextStyle(fontSize: 8, color: colorText),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'QR de referencia local; no es una validacion de SUNAT.',
                      style: pw.TextStyle(fontSize: 7, color: colorMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final file = File(
      '${boletasDir.path}/boleta_${venta.id ?? DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<List<Map<String, dynamic>>> getHistorialVentas() async {
    return await _ventaRepo.getHistorialVentas();
  }

  Future<void> anularVenta({
    required int ventaId,
    required String motivo,
    int? usuarioId,
  }) =>
      _ventaRepo.anularVenta(
        ventaId: ventaId,
        motivo: motivo,
        usuarioId: usuarioId,
      );

  Future<void> actualizarMetodoPagoVenta({
    required int ventaId,
    required String nuevoMetodo,
    int? usuarioId,
  }) =>
      _ventaRepo.actualizarMetodoPagoVenta(
        ventaId: ventaId,
        nuevoMetodo: nuevoMetodo,
        usuarioId: usuarioId,
      );

  Future<Map<String, dynamic>?> getVentaConDetalles(int ventaId) =>
      _ventaRepo.getVentaConDetalles(ventaId);

  Future<String?> obtenerORecrearBoletaPDF(int ventaId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File('${docsDir.path}/boletas/boleta_$ventaId.pdf');
    if (await file.exists()) {
      return file.path;
    }

    final data = await _ventaRepo.getVentaConDetalles(ventaId);
    if (data == null) return null;
    final vMap = data['venta'] as Map<String, dynamic>;
    final dList = data['detalles'] as List<Map<String, dynamic>>;

    final venta = Venta(
      id: vMap['id'] as int?,
      fecha: vMap['fecha'] as String,
      hora: vMap['hora'] as String,
      metodoPago: vMap['metodo_pago'] as String,
      montoRecibido: (vMap['monto_recibido'] as num?)?.toDouble(),
      vuelto: (vMap['vuelto'] as num?)?.toDouble(),
      subtotal: (vMap['subtotal'] as num).toDouble(),
      descuento: (vMap['descuento'] as num?)?.toDouble() ?? 0.0,
      total: (vMap['total'] as num).toDouble(),
      nota: vMap['nota'] as String?,
      promocionId: vMap['promocion_id'] as int?,
    );

    final detalles = dList
        .map(
          (d) => DetalleVenta(
            id: d['id'] as int?,
            ventaId: ventaId,
            varianteId: d['variante_id'] as int?,
            promocionId: d['promocion_id'] as int?,
            cantidad: (d['cantidad'] as num).toInt(),
            precioUnitario: (d['precio_unitario'] as num).toDouble(),
            descuento: (d['descuento'] as num?)?.toDouble() ?? 0.0,
            esCortesia: (d['es_cortesia'] as num?)?.toInt() == 1,
          ),
        )
        .toList();

    return await generarBoletaPDF(venta, detalles);
  }
}

pw.Widget _pdfReceiptMeta(
  String label,
  String value,
  PdfColor valueColor,
  PdfColor labelColor,
) {
  return pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
        pw.TextSpan(
          text: PdfHelper.sanitize(value),
          style: pw.TextStyle(fontSize: 9, color: labelColor),
        ),
      ],
    ),
  );
}

pw.Widget _pdfReceiptTotalRow(String label, String amount, PdfColor color) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
      pw.Text(
        amount,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}
