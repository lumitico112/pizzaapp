import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizzaapp/core/utils/pdf_helper.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';

class CajaService {
  final CajaRepository _repository;
  final AuthService? _authService;

  CajaService(this._repository, [this._authService]);

  bool get puedeAutorizarReapertura =>
      _authService?.currentUser?.rol == 'admin';

  Future<SesionCaja?> getSesionActiva() async {
    return await _repository.getSesionActiva();
  }

  Future<SesionCaja?> getUltimaSesionCerrada() =>
      _repository.getUltimaSesionCerrada();

  Future<void> reabrirCaja(int sesionId, String motivo, String password) async {
    if (motivo.trim().isEmpty) {
      throw Exception('Indica el motivo de la reapertura.');
    }
    final auth = _authService;
    if (auth == null) {
      throw Exception('No está disponible la autorización administrativa.');
    }
    final userId = await auth.authorizeAdminOperation(password);
    await _repository.reabrirSesion(
      sesionId: sesionId,
      motivo: motivo,
      usuarioId: userId,
    );
  }

  Future<CashCloseSummary?> getResumenActual() async {
    final session = await getSesionActiva();
    if (session == null) return null;
    return _repository.resumenSesion(session);
  }

  Future<void> abrirCaja(
    double montoApertura,
    double transferenciasApertura,
  ) async {
    if (!montoApertura.isFinite || montoApertura < 0) {
      throw Exception('El efectivo inicial no puede ser negativo.');
    }
    if (!transferenciasApertura.isFinite || transferenciasApertura < 0) {
      throw Exception('El saldo inicial de Yape/Plin no puede ser negativo.');
    }
    final activa = await getSesionActiva();
    if (activa != null) {
      throw Exception('Ya hay una sesiÃ³n de caja abierta.');
    }
    final hoyIso = DateTime.now().toIso8601String();

    final nuevaSesion = SesionCaja(
      fechaApertura: hoyIso,
      montoApertura: montoApertura,
      transferenciasApertura: transferenciasApertura,
      estado: 'abierta',
      usuarioAperturaId: _authService?.currentUser?.id,
    );

    final apertura = montoApertura > 0
        ? MovimientoCaja(
            sesionCajaId: 0,
            tipo: 'apertura',
            metodoPago: 'efectivo',
            monto: montoApertura,
            descripcion: 'Apertura de caja',
            fecha: hoyIso,
          )
        : null;
    await _repository.abrirSesion(
      nuevaSesion,
      apertura,
      userId: _authService?.currentUser?.id,
    );
  }

  Future<void> registrarMovimiento(
    int sesionId,
    String tipo,
    String descripcion,
    double monto,
    String metodoPago,
  ) async {
    final mPagoLower = metodoPago.toLowerCase().trim();
    if (!['efectivo', 'yape', 'plin', 'yape/plin', 'transferencia'].contains(mPagoLower)) {
      throw Exception('Selecciona un medio de pago válido.');
    }
    final hoyIso = DateTime.now().toIso8601String();
    await _repository.registrarMovimientoManual(
      MovimientoCaja(
        sesionCajaId: sesionId,
        tipo: tipo,
        monto: monto,
        descripcion: descripcion,
        metodoPago: metodoPago,
        fecha: hoyIso,
      ),
      userId: _authService?.currentUser?.id,
    );
  }

  Future<SesionCaja> cerrarCaja(
    double efectivoContado,
    double transferenciasContadas,
    String nota,
  ) async {
    if (efectivoContado < 0 || transferenciasContadas < 0) {
      throw Exception('Los importes arqueados no pueden ser negativos.');
    }
    final activa = await getSesionActiva();
    if (activa == null) {
      throw Exception('No hay ninguna sesiÃ³n de caja abierta.');
    }

    return _repository.cerrarSesion(
      sesionId: activa.id!,
      efectivoContado: efectivoContado,
      transferenciasContadas: transferenciasContadas,
      nota: nota,
      usuarioId: _authService?.currentUser?.id,
    );
  }

  Future<String?> generarArqueoPDF(SesionCaja sesion) async {
    // 1. Repositorio de configuración y datos de negocio
    final configRepo = ConfiguracionRepository();
    final nombreNegocio =
        await configRepo.getConfig('nombre_negocio') ?? 'KIMI PIZZA';
    final identificacion = await configRepo.getConfig('ruc_dni') ?? '';
    final direccion = await configRepo.getConfig('direccion_negocio') ?? '';
    final telefono = await configRepo.getConfig('telefono_negocio') ?? '';
    final logoRuta = await configRepo.getConfig('logo_ruta');

    pw.MemoryImage? logoImage;
    if (logoRuta != null && logoRuta.trim().isNotEmpty) {
      final logoFile = File(logoRuta.trim());
      if (await logoFile.exists()) {
        try {
          logoImage = pw.MemoryImage(await logoFile.readAsBytes());
        } catch (_) {}
      }
    }

    // 2. Movimientos y resumen financiero del ciclo
    final movimientos = await _repository.getMovimientos(sesion.id!);
    final summary = await _repository.resumenSesion(sesion);

    // 3. Resolución del Cajero(a)
    String cajeroNombre = 'ADMINISTRADOR';
    final userId = sesion.usuarioCierreId ??
        sesion.usuarioAperturaId ??
        _authService?.currentUser?.id;
    if (userId != null) {
      try {
        final nombre = await _repository.getNombreUsuario(userId);
        if (nombre != null) {
          cajeroNombre = nombre;
        }
      } catch (_) {}
    } else if (_authService?.currentUser?.nombre != null) {
      cajeroNombre = _authService!.currentUser!.nombre;
    }
    cajeroNombre = PdfHelper.sanitize(cajeroNombre.toUpperCase());

    // 4. Detalle de productos por venta para la columna DETALLE / CONCEPTO
    Map<int, String> itemsPorVenta = {};
    try {
      itemsPorVenta = await _repository.getItemsPorVenta(sesion.id!);
    } catch (_) {}

    // 5. Fechas y duración del turno
    DateTime? aperturaDt;
    try {
      aperturaDt = DateTime.parse(sesion.fechaApertura);
    } catch (_) {}

    DateTime? cierreDt;
    if (sesion.fechaCierre != null && sesion.fechaCierre!.isNotEmpty) {
      try {
        cierreDt = DateTime.parse(sesion.fechaCierre!);
      } catch (_) {}
    }

    String formatFechaHora(DateTime? dt) {
      if (dt == null) return 'En curso / Sin cerrar';
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final h12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final h = h12.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'p. m.' : 'a. m.';
      return '$d/$m/$y · $h:$min $ampm';
    }

    String formatHora(String iso) {
      try {
        final dt = DateTime.parse(iso);
        final h12 =
            dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final h = h12.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'p. m.' : 'a. m.';
        return '$h:$min $ampm';
      } catch (_) {
        return iso.contains('T') ? iso.split('T')[1].substring(0, 5) : iso;
      }
    }

    String duracionTurno = '-';
    if (aperturaDt != null) {
      final fin = cierreDt ?? DateTime.now();
      final diff = fin.difference(aperturaDt);
      duracionTurno = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }

    // 6. Colores corporativos
    final colorTerracotta = PdfColor.fromHex('#D62828');
    final colorText = PdfColor.fromHex('#1F2937');
    final colorMuted = PdfColor.fromHex('#6B7280');
    final colorBorder = PdfColor.fromHex('#E5E7EB');
    final colorBgCard = PdfColor.fromHex('#F9FAFB');
    final colorGreen = PdfColor.fromHex('#059669');
    final colorRed = PdfColor.fromHex('#DC2626');
    final colorAmber = PdfColor.fromHex('#D97706');
    final colorHeaderBoxBg = PdfColor.fromHex('#FFF5F2');
    final colorTotalRow = PdfColor.fromHex('#F3F4F6');

    // 7. Conciliación y cálculos por método (fuente única: CashCloseSummary — C-11)
    final apertEfectivo = sesion.montoApertura;
    final apertDigital = sesion.transferenciasApertura;

    final ventasEfectivo = summary.entradasEfectivo;
    final ventasDigital = summary.entradasTransferencias;
    final salidasEfectivo = summary.salidasEfectivo;
    final salidasDigital = summary.salidasTransferencias;

    final totalVentas = ventasEfectivo + ventasDigital;
    final totalGastos = summary.gastos;
    final fondoInicialTotal = apertEfectivo + apertDigital;

    final difTotal = sesion.diferencia;
    String badgeDiffText = 'CAJA CUADRADA';
    PdfColor badgeDiffColor = colorGreen;
    if (difTotal < 0) {
      badgeDiffText = 'FALTANTE';
      badgeDiffColor = colorRed;
    } else if (difTotal > 0) {
      badgeDiffText = 'SOBRANTE';
      badgeDiffColor = colorAmber;
    }

    pw.Widget cell(
      String text, {
      bool isBold = false,
      PdfColor? color,
      pw.TextAlign align = pw.TextAlign.left,
      double fontSize = 8,
      pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    }) {
      return pw.Padding(
        padding: padding,
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? colorText,
          ),
        ),
      );
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 44,
                            height: 44,
                            margin: const pw.EdgeInsets.only(right: 10),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        ] else ...[
                          pw.Container(
                            width: 42,
                            height: 42,
                            margin: const pw.EdgeInsets.only(right: 10),
                            decoration: pw.BoxDecoration(
                              color: colorTerracotta,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'KP',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                PdfHelper.sanitize(nombreNegocio),
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: colorTerracotta,
                                ),
                              ),
                              if (identificacion.trim().isNotEmpty) ...[
                                pw.Text(
                                  'RUC: ${PdfHelper.sanitize(identificacion)}',
                                  style: pw.TextStyle(fontSize: 8.5, color: colorMuted),
                                ),
                              ],
                              if (direccion.trim().isNotEmpty || telefono.trim().isNotEmpty) ...[
                                pw.Text(
                                  '${PdfHelper.sanitize(direccion)}${telefono.trim().isNotEmpty ? ' · Tel: $telefono' : ''}',
                                  style: pw.TextStyle(fontSize: 8.5, color: colorMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: colorHeaderBoxBg,
                      border: pw.Border.all(color: colorTerracotta, width: 1.2),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'REPORTE DE ARQUEO DE CAJA',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: colorTerracotta,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'Ciclo: #${sesion.id.toString().padLeft(4, '0')}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: colorText,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: sesion.estado.toLowerCase() == 'cerrada' ? colorRed : colorGreen,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                sesion.estado.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: colorBorder, width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${PdfHelper.sanitize(nombreNegocio)} - Reporte de Arqueo #${sesion.id.toString().padLeft(4, '0')}',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: colorTerracotta),
                  ),
                  pw.Text(
                    sesion.estado.toUpperCase(),
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: colorMuted),
                  ),
                ],
              ),
            );
          }
        },
        footer: (pw.Context context) {
          final ahora = DateTime.now();
          final genStr = formatFechaHora(ahora);
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: colorBorder, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generado: $genStr',
                  style: pw.TextStyle(fontSize: 7.5, color: colorMuted),
                ),
                pw.Text(
                  'Auditoría Interna de Caja · Confidencial',
                  style: pw.TextStyle(fontSize: 7.5, color: colorMuted),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: colorText),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Tarjeta de Información del Turno (Grid 2 columnas)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: colorBgCard,
                border: pw.Border.all(color: colorBorder, width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('FECHA Y HORA DE APERTURA', formatFechaHora(aperturaDt), colorMuted, colorText),
                        pw.SizedBox(height: 4),
                        _buildInfoItem('DURACIÓN DEL TURNO', duracionTurno, colorMuted, colorText),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('FECHA Y HORA DE CIERRE', formatFechaHora(cierreDt), colorMuted, colorText),
                        pw.SizedBox(height: 4),
                        _buildInfoItem('RESPONSABLE / CAJERO(A)', cajeroNombre, colorMuted, colorText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2. Resumen Ejecutivo en 4 Tarjetas (KPIs Superiores)
            pw.Row(
              children: [
                _buildKpiCard('FONDO INICIAL TOTAL', 'S/ ${fondoInicialTotal.toStringAsFixed(2)}', 'Apertura Efec. + Digital', colorText, colorBgCard, colorBorder, colorMuted),
                pw.SizedBox(width: 6),
                _buildKpiCard('TOTAL VENTAS / ING.', '+ S/ ${totalVentas.toStringAsFixed(2)}', 'Cobrado en el turno', colorGreen, colorBgCard, colorBorder, colorMuted),
                pw.SizedBox(width: 6),
                _buildKpiCard('TOTAL SALIDAS / GASTOS', '- S/ ${totalGastos.toStringAsFixed(2)}', 'Compras y egresos', colorRed, colorBgCard, colorBorder, colorMuted),
                pw.SizedBox(width: 6),
                _buildKpiCard('BALANCE ESPERADO', 'S/ ${sesion.totalEsperado.toStringAsFixed(2)}', 'Saldo teórico en caja', colorTerracotta, colorHeaderBoxBg, colorTerracotta, colorMuted),
              ],
            ),
            pw.SizedBox(height: 12),

            // 3. Tabla de Conciliación y Cuadre por Método de Pago
            pw.Text(
              'CONCILIACION Y CUADRE POR METODO DE PAGO',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: colorTerracotta,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(1.4),
                3: pw.FlexColumnWidth(1.4),
                4: pw.FlexColumnWidth(1.4),
                5: pw.FlexColumnWidth(1.4),
                6: pw.FlexColumnWidth(1.5),
              },
              border: pw.TableBorder.all(color: colorBorder, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: colorTotalRow),
                  children: [
                    cell('METODO DE PAGO', isBold: true, color: colorText),
                    cell('INICIAL', isBold: true, align: pw.TextAlign.right, color: colorText),
                    cell('(+) VENTAS', isBold: true, align: pw.TextAlign.right, color: colorGreen),
                    cell('(-) SALIDAS', isBold: true, align: pw.TextAlign.right, color: colorRed),
                    cell('ESPERADO', isBold: true, align: pw.TextAlign.right, color: colorText),
                    cell('DECLARADO', isBold: true, align: pw.TextAlign.right, color: colorText),
                    cell('DIFERENCIA', isBold: true, align: pw.TextAlign.right, color: colorText),
                  ],
                ),
                pw.TableRow(
                  children: [
                    cell('Efectivo en Caja'),
                    cell('S/ ${apertEfectivo.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    cell('S/ ${ventasEfectivo.toStringAsFixed(2)}', align: pw.TextAlign.right, color: colorGreen),
                    cell('S/ ${salidasEfectivo.toStringAsFixed(2)}', align: pw.TextAlign.right, color: colorRed),
                    cell('S/ ${sesion.totalEfectivoSistema.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    cell('S/ ${sesion.efectivoContado.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    cell(
                      '${sesion.diferenciaEfectivo >= 0 ? '+' : ''} S/ ${sesion.diferenciaEfectivo.toStringAsFixed(2)}',
                      align: pw.TextAlign.right,
                      isBold: true,
                      color: sesion.diferenciaEfectivo < 0 ? colorRed : (sesion.diferenciaEfectivo > 0 ? colorAmber : colorGreen),
                    ),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: colorBgCard),
                  children: [
                    cell('Digital (Yape / Plin)'),
                    cell('S/ ${apertDigital.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    cell('S/ ${ventasDigital.toStringAsFixed(2)}', align: pw.TextAlign.right, color: colorGreen),
                    cell('S/ ${salidasDigital.toStringAsFixed(2)}', align: pw.TextAlign.right, color: colorRed),
                    cell('S/ ${sesion.totalYapePlin.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    cell('S/ ${sesion.transferenciasContadas.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    cell(
                      '${sesion.diferenciaTransferencia >= 0 ? '+' : ''} S/ ${sesion.diferenciaTransferencia.toStringAsFixed(2)}',
                      align: pw.TextAlign.right,
                      isBold: true,
                      color: sesion.diferenciaTransferencia < 0 ? colorRed : (sesion.diferenciaTransferencia > 0 ? colorAmber : colorGreen),
                    ),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: colorTotalRow),
                  children: [
                    cell('TOTAL CONCILIACION', isBold: true, color: colorText),
                    cell('S/ ${fondoInicialTotal.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    cell('S/ ${(ventasEfectivo + ventasDigital).toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true, color: colorGreen),
                    cell('S/ ${(salidasEfectivo + salidasDigital).toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true, color: colorRed),
                    cell('S/ ${sesion.totalEsperado.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    cell('S/ ${(sesion.efectivoContado + sesion.transferenciasContadas).toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            '${difTotal >= 0 ? '+' : ''} S/ ${difTotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: badgeDiffColor,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: pw.BoxDecoration(
                              color: badgeDiffColor,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            child: pw.Text(
                              badgeDiffText,
                              style: pw.TextStyle(
                                fontSize: 6.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (sesion.nota != null && sesion.nota!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: colorBgCard,
                  border: pw.Border.all(color: colorBorder, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Observaciones del cierre: ',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorText),
                      ),
                      pw.TextSpan(
                        text: PdfHelper.sanitize(sesion.nota!.trim()),
                        style: pw.TextStyle(fontSize: 8, color: colorMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 12),

            // 4. Tabla Detallada de Movimientos del Ciclo
            pw.Text(
              'DETALLE DE MOVIMIENTOS DEL CICLO (${movimientos.length})',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: colorTerracotta,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(1.4),
                3: pw.FlexColumnWidth(4.2),
                4: pw.FlexColumnWidth(1.8),
              },
              border: pw.TableBorder.all(color: colorBorder, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: colorTerracotta),
                  children: [
                    cell('HORA', isBold: true, color: PdfColors.white, align: pw.TextAlign.center),
                    cell('TIPO', isBold: true, color: PdfColors.white, align: pw.TextAlign.center),
                    cell('METODO', isBold: true, color: PdfColors.white, align: pw.TextAlign.center),
                    cell('DETALLE / CONCEPTO', isBold: true, color: PdfColors.white),
                    cell('MONTO', isBold: true, color: PdfColors.white, align: pw.TextAlign.right),
                  ],
                ),
                if (movimientos.isEmpty)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text('Sin movimientos registrados en este ciclo.', style: pw.TextStyle(fontSize: 8, color: colorMuted)),
                      ),
                      pw.Container(),
                      pw.Container(),
                      pw.Container(),
                      pw.Container(),
                    ],
                  )
                else
                  for (int i = 0; i < movimientos.length; i++)
                    _buildMovimientoRow(
                      movimientos[i],
                      i,
                      formatHora,
                      itemsPorVenta,
                      colorBorder,
                      colorBgCard,
                      colorText,
                      colorMuted,
                      colorGreen,
                      colorRed,
                    ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 5. Resumen de Productos Vendidos
            if (summary.ventasPorProducto.isNotEmpty) ...[
              pw.Text(
                'RESUMEN DE PRODUCTOS VENDIDOS EN EL TURNO',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: colorTerracotta,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(6.0),
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(2.0),
                },
                border: pw.TableBorder.all(color: colorBorder, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: colorTotalRow),
                    children: [
                      cell('PRODUCTO / VARIEDAD', isBold: true, color: colorText),
                      cell('CANTIDAD', isBold: true, align: pw.TextAlign.center, color: colorText),
                      cell('TOTAL S/', isBold: true, align: pw.TextAlign.right, color: colorText),
                    ],
                  ),
                  for (int idx = 0; idx < summary.ventasPorProducto.length; idx++) ...[
                    _buildProductRow(
                      summary.ventasPorProducto[idx],
                      idx,
                      colorBgCard,
                      colorText,
                      colorMuted,
                    ),
                  ],
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: colorTotalRow),
                    children: [
                      cell('TOTAL UNIDADES Y RECAUDACION', isBold: true, color: colorText),
                      cell(
                        '${summary.ventasPorProducto.fold<int>(0, (s, p) => s + p.quantity)} uds.',
                        isBold: true,
                        align: pw.TextAlign.center,
                        color: colorText,
                      ),
                      cell(
                        'S/ ${summary.ventasPorProducto.fold<double>(0.0, (s, p) => s + p.total).toStringAsFixed(2)}',
                        isBold: true,
                        align: pw.TextAlign.right,
                        color: colorGreen,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
            ],

            // 6. Firmas de Conformidad
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 170,
                        height: 1,
                        color: colorText,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Cajero(a) / Entregante',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: colorText),
                      ),
                      pw.Text(
                        cajeroNombre,
                        style: pw.TextStyle(fontSize: 7.5, color: colorMuted),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 170,
                        height: 1,
                        color: colorText,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Administración / Verificado',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: colorText),
                      ),
                      pw.Text(
                        'Firma / Sello Conforme',
                        style: pw.TextStyle(fontSize: 7.5, color: colorMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/arqueo_caja_${sesion.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildInfoItem(
    String label,
    String value,
    PdfColor labelColor,
    PdfColor valueColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: labelColor,
          ),
        ),
        pw.SizedBox(height: 1.5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildKpiCard(
    String label,
    String value,
    String subtitle,
    PdfColor valueColor,
    PdfColor bgColor,
    PdfColor borderColor,
    PdfColor subtitleColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: pw.BoxDecoration(
          color: bgColor,
          border: pw.Border.all(color: borderColor, width: 0.8),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 6.5,
                fontWeight: pw.FontWeight.bold,
                color: subtitleColor,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
            pw.SizedBox(height: 1.5),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontSize: 6.5,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _buildMovimientoRow(
    MovimientoCaja m,
    int index,
    String Function(String) formatHora,
    Map<int, String> itemsPorVenta,
    PdfColor colorBorder,
    PdfColor colorBgCard,
    PdfColor colorText,
    PdfColor colorMuted,
    PdfColor colorGreen,
    PdfColor colorRed,
  ) {
    final isEven = index % 2 == 0;
    final rowBg = isEven ? PdfColors.white : colorBgCard;

    final horaStr = formatHora(m.fecha);

    final tipoRaw = m.tipo.toLowerCase().trim();
    String tipoStr = tipoRaw.toUpperCase();
    if (tipoRaw == 'apertura') {
      tipoStr = 'APERTURA';
    } else if (tipoRaw == 'venta') {
      tipoStr = 'VENTA';
    } else if (tipoRaw == 'salida' || tipoRaw == 'gasto') {
      tipoStr = 'GASTO';
    } else if (tipoRaw == 'compra') {
      tipoStr = 'COMPRA';
    } else if (tipoRaw == 'entrada') {
      tipoStr = 'ENTRADA';
    }

    final metodoRaw = (m.metodoPago ?? 'efectivo').toLowerCase().trim();
    String metodoStr = 'Efectivo';
    if (metodoRaw == 'yape') {
      metodoStr = 'Yape';
    } else if (metodoRaw == 'plin') {
      metodoStr = 'Plin';
    } else if (metodoRaw == 'transferencia' || metodoRaw == 'yape/plin') {
      metodoStr = 'Yape/Plin';
    }

    String detalleStr = '';
    if (tipoRaw == 'apertura') {
      detalleStr = 'Apertura de caja / Fondo inicial';
    } else if (tipoRaw == 'venta') {
      final desc = m.descripcion ?? '';
      final match = RegExp(r'(\d+)').firstMatch(desc);
      final ventaId = match != null ? int.tryParse(match.group(1)!) : null;
      final items = (ventaId != null ? itemsPorVenta[ventaId] : null);
      if (items != null && items.isNotEmpty) {
        detalleStr = 'Venta #$ventaId: $items';
      } else if (desc.isNotEmpty) {
        detalleStr = desc;
      } else {
        detalleStr = 'Venta de productos';
      }
    } else if (tipoRaw == 'salida' || tipoRaw == 'gasto' || tipoRaw == 'compra') {
      final desc = m.descripcion ?? '';
      if (desc.toLowerCase().startsWith('gasto') ||
          desc.toLowerCase().startsWith('compra') ||
          desc.toLowerCase().startsWith('salida')) {
        detalleStr = desc;
      } else {
        detalleStr = tipoRaw == 'compra' ? 'Compra: $desc' : 'Gasto: $desc';
      }
    } else if (tipoRaw == 'entrada') {
      final desc = m.descripcion ?? '';
      detalleStr = desc.toLowerCase().startsWith('ingreso') ||
              desc.toLowerCase().startsWith('entrada')
          ? desc
          : 'Ingreso: $desc';
    } else {
      detalleStr = m.descripcion ?? '-';
    }
    detalleStr = PdfHelper.sanitize(detalleStr);

    String montoStr = 'S/ ${m.monto.toStringAsFixed(2)}';
    PdfColor montoColor = colorText;
    if (tipoRaw == 'venta' || tipoRaw == 'entrada') {
      montoStr = '+ S/ ${m.monto.toStringAsFixed(2)}';
      montoColor = colorGreen;
    } else if (tipoRaw == 'salida' || tipoRaw == 'gasto' || tipoRaw == 'compra') {
      montoStr = '- S/ ${m.monto.toStringAsFixed(2)}';
      montoColor = colorRed;
    }

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: rowBg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            horaStr,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, color: colorMuted),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            tipoStr,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: colorText,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            metodoStr,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, color: colorText),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            detalleStr,
            style: pw.TextStyle(fontSize: 7.5, color: colorText),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Text(
            montoStr,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: montoColor,
            ),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildProductRow(
    CashProductSale item,
    int index,
    PdfColor colorBgCard,
    PdfColor colorText,
    PdfColor colorMuted,
  ) {
    final isEven = index % 2 == 0;
    final rowBg = isEven ? PdfColors.white : colorBgCard;
    final prodName = (item.variantName.isNotEmpty && item.variantName != item.productName)
        ? '${item.productName} - ${item.variantName}'
        : item.productName;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: rowBg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
          child: pw.Text(
            PdfHelper.sanitize(prodName),
            style: pw.TextStyle(fontSize: 7.5, color: colorText),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
          child: pw.Text(
            '${item.quantity}${item.courtesyQuantity > 0 ? ' (+${item.courtesyQuantity} cort.)' : ''}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: colorText),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
          child: pw.Text(
            'S/ ${item.total.toStringAsFixed(2)}',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: colorText),
          ),
        ),
      ],
    );
  }
}
