import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';

class PosCobroResult {
  final String? pdfPath;
  final double total;
  final String metodoPago;
  final String ticketNum;

  const PosCobroResult({
    required this.pdfPath,
    required this.total,
    required this.metodoPago,
    required this.ticketNum,
  });
}

class PosCobroSheet extends StatefulWidget {
  final PosController controller;
  final DateTime? fechaVentaAnterior;

  const PosCobroSheet({
    super.key,
    required this.controller,
    this.fechaVentaAnterior,
  });

  /// Abre la hoja inferior para procesar el cobro.
  /// Retorna un `PosCobroResult` en caso de éxito, o `null` si se canceló.
  static Future<PosCobroResult?> show({
    required BuildContext context,
    required PosController controller,
    DateTime? fechaVentaAnterior,
  }) {
    return showModalBottomSheet<PosCobroResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => PosCobroSheet(
        controller: controller,
        fechaVentaAnterior: fechaVentaAnterior,
      ),
    );
  }

  @override
  State<PosCobroSheet> createState() => _PosCobroSheetState();
}

class _PosCobroSheetState extends State<PosCobroSheet> {
  String _metodoSeleccionado = 'efectivo';
  final TextEditingController _pagoConCtrl = TextEditingController();
  final TextEditingController _observacionesCtrl = TextEditingController();
  String? _qrRuta;
  bool _isLoadingQr = true;
  bool _isSubmitting = false;
  bool _isButtonPressed = false;

  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _borderGrey = Color(0xFFE5E7EB);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _emeraldDark = Color(0xFF059669);
  static const Color _mintBackground = Color(0xFFECFDF5);
  static const Color _brandOrange = Color(0xFFFF6A00);
  static const Color _brandRed = Color(0xFFD62828);
  static const Color _greyInactive = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _cargarQr();
  }

  @override
  void dispose() {
    _pagoConCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarQr() async {
    try {
      final configRepo = ConfiguracionRepository();
      final ruta = await configRepo.getConfig('qr_ventas_ruta');
      if (mounted) {
        setState(() {
          _qrRuta = ruta;
          _isLoadingQr = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingQr = false);
      }
    }
  }

  double get _montoPagoCon {
    final clean = _pagoConCtrl.text.trim().replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }

  double get _vuelto => _montoPagoCon - widget.controller.granTotal;

  List<double> get _montosRapidos {
    final total = widget.controller.granTotal;
    final montos = <double>[
      total,
      10,
      20,
      50,
      100,
    ].where((monto) => monto >= total).toSet().toList()..sort();
    return montos;
  }

  bool get _esSoloCortesia => widget.controller.granTotal <= 0;

  Future<void> _confirmarCobro() async {
    if (_isSubmitting) return;

    final isEfectivo = _metodoSeleccionado == 'efectivo';
    final pagoCon = _montoPagoCon;
    final vuelto = _vuelto;

    if (!_esSoloCortesia && isEfectivo && pagoCon > 0 && vuelto < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El monto pagado es insuficiente para cubrir el total.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final totalVenta = widget.controller.granTotal;
    final metodoNombre = _esSoloCortesia
        ? 'Cortesía'
        : (isEfectivo ? 'Efectivo' : 'Yape/Plin');

    setState(() => _isSubmitting = true);

    try {
      final resultado = await widget.controller.procesarCobro(
        _esSoloCortesia
            ? 'efectivo'
            : (_metodoSeleccionado == 'yape/plin'
                ? 'yape'
                : _metodoSeleccionado),
        _observacionesCtrl.text.trim(),
        fechaPersonalizada: widget.fechaVentaAnterior == null
            ? null
            : AppDateUtils.formatStorage(widget.fechaVentaAnterior!),
        montoRecibido:
            !_esSoloCortesia && isEfectivo && pagoCon > 0 ? pagoCon : null,
      );

      if (!mounted) return;

      if (resultado != null) {
        // H-07: la venta ya quedó registrada aunque la boleta haya fallado
        // (boletaPendiente); el diálogo de éxito informa que puede
        // reimprimirse desde el historial de boletas.
        final pdfPath = resultado.pdfPath;
        String ticketNum = 'Boleta pendiente';
        if (pdfPath != null && pdfPath.isNotEmpty) {
          ticketNum = 'Boleta #B001-001';
          final match = RegExp(r'boleta_(\d+)').firstMatch(pdfPath);
          if (match != null) {
            ticketNum = 'Boleta #B001-${match.group(1)!.padLeft(3, '0')}';
          }
        }

        Navigator.pop(
          context,
          PosCobroResult(
            pdfPath: (pdfPath == null || pdfPath.isEmpty) ? null : pdfPath,
            total: totalVenta,
            metodoPago: metodoNombre,
            ticketNum: ticketNum,
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        final err = widget.controller.error ?? 'Error al registrar la venta.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err.contains('Null check operator')
                  ? 'Error al procesar cortesía: faltan datos del producto o caja.'
                  : err,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error en PosCobroSheet._confirmarCobro: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        setState(() => _isSubmitting = false);
        final rawMsg = e.toString().replaceAll('Exception: ', '').trim();
        final displayMsg = rawMsg.contains('Null check operator')
            ? 'Error al procesar cortesía: faltan datos del producto o caja.'
            : (rawMsg.isEmpty ? 'Error al procesar la operación.' : rawMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _abrirQrAmpliado(BuildContext ctx) {
    if (_qrRuta == null || _qrRuta!.isEmpty || !File(_qrRuta!).existsSync()) {
      return;
    }

    showDialog(
      context: ctx,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QR de Cobro Yape/Plin',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _textMuted),
                    onPressed: () => Navigator.pop(dialogCtx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.file(File(_qrRuta!), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pellizca para hacer zoom',
                style: GoogleFonts.poppins(fontSize: 12, color: _textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEfectivo = _metodoSeleccionado == 'efectivo';
    final pagoCon = _montoPagoCon;
    final vuelto = _vuelto;
    final esMontoInsuficiente = isEfectivo && pagoCon > 0 && vuelto < 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Manija de arrastre superior
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Encabezado "Procesar Cobro"
              Text(
                'Procesar Cobro',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),

              // Aviso histórico (si aplica)
              if (widget.fechaVentaAnterior != null &&
                  DateTime(
                    widget.fechaVentaAnterior!.year,
                    widget.fechaVentaAnterior!.month,
                    widget.fechaVentaAnterior!.day,
                  ).isBefore(AppDateUtils.todayStart))
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: Color(0xFFD97706),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registro histórico · ${AppDateUtils.formatDisplay(widget.fechaVentaAnterior!)}. No afectará la caja ni inventario de hoy.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF92400E),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Desglose de ítems del carrito
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.controller.carrito.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final c = widget.controller.carrito[index];
                    final nombre = c.esPromocion
                        ? c.nombrePromocion
                        : c.producto == null || c.variante == null
                        ? ''
                        : widget.controller.nombreVenta(
                            c.producto!,
                            c.variante!,
                          );
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${c.cantidad}x $nombre${c.esCortesia ? ' · CORTESÍA' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: c.esCortesia
                                  ? const Color(0xFFD97706)
                                  : _textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'S/ ${c.total.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // 3. Tarjeta del Total a Cobrar (Hero Section)
              Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _mintBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _emeraldGreen, width: 1.5),
                ),
                child: Text(
                  '${_esSoloCortesia ? 'Total de cortesías' : 'Total a cobrar'}: S/ ${widget.controller.granTotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _emeraldDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Estado especial: Solo Cortesía
              if (_esSoloCortesia) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism_outlined,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido 100% de cortesía (S/. 0.00)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Solo se descontará el stock correspondiente.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // 4. Selector de Método de Pago (Segmented Tab Bar)
                Text(
                  'Método de Pago:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Botón Efectivo
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _metodoSeleccionado = 'efectivo'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: isEfectivo
                                ? const LinearGradient(
                                    colors: [_brandOrange, _brandRed],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: isEfectivo ? null : _greyInactive,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isEfectivo
                                ? [
                                    BoxShadow(
                                      color: _brandOrange.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEfectivo
                                    ? Icons.payments
                                    : Icons.payments_outlined,
                                color: isEfectivo
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Efectivo',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: isEfectivo
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isEfectivo
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Botón Yape/Plin
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _metodoSeleccionado = 'yape'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: !isEfectivo
                                ? const LinearGradient(
                                    colors: [_brandOrange, _brandRed],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: !isEfectivo ? null : _greyInactive,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: !isEfectivo
                                ? [
                                    BoxShadow(
                                      color: _brandOrange.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                !isEfectivo
                                    ? Icons.qr_code_2
                                    : Icons.qr_code_2_outlined,
                                color: !isEfectivo
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Yape/Plin',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: !isEfectivo
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: !isEfectivo
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Flujo Dinámico según Método de Pago
                if (isEfectivo) ...[
                  // Campo único de ancho completo para facilitar el toque.
                  SizedBox(
                    height: 56,
                    child: TextField(
                      controller: _pagoConCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          color: _textMuted,
                        ),
                        prefixText: 'S/ ',
                        prefixStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                        labelText: 'Se pagó con (S/)',
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textMuted,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: esMontoInsuficiente
                                ? const Color(0xFFEF4444)
                                : _borderGrey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: esMontoInsuficiente
                                ? const Color(0xFFEF4444)
                                : _brandOrange,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final monto in _montosRapidos) ...[
                                if (_montosRapidos.first != monto)
                                  const SizedBox(width: 5),
                                ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  backgroundColor: const Color(0xFFFFF7ED),
                                  side: const BorderSide(
                                    color: Color(0xFFFED7AA),
                                  ),
                                  label: Text(
                                    monto == widget.controller.granTotal
                                        ? 'Exacto'
                                        : 'S/ ${monto.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFC2410C),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _pagoConCtrl.text = monto.toStringAsFixed(
                                        2,
                                      );
                                      _pagoConCtrl.selection =
                                          TextSelection.collapsed(
                                            offset: _pagoConCtrl.text.length,
                                          );
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        esMontoInsuficiente
                            ? 'Monto insuficiente'
                            : 'Vuelto: S/ ${pagoCon > 0 && vuelto >= 0 ? vuelto.toStringAsFixed(2) : '0.00'}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: esMontoInsuficiente
                              ? const Color(0xFFEF4444)
                              : _emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // VISTA YAPE/PLIN: Tarjeta del Código QR
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingQr
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : (_qrRuta != null &&
                              _qrRuta!.isNotEmpty &&
                              File(_qrRuta!).existsSync())
                        ? GestureDetector(
                            onTap: () => _abrirQrAmpliado(context),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED)
                                            .withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(_qrRuta!),
                                      height: 110,
                                      width: 110,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toque el QR para ampliar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              const Icon(
                                Icons.qr_code_2_rounded,
                                size: 42,
                                color: _brandOrange,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'QR de ventas no configurado.\nConfigúralo en Configuración del Negocio.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFC2410C),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // Campo común: "Observaciones / Notas de venta"
              TextField(
                controller: _observacionesCtrl,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.edit_note_rounded,
                    color: _textMuted,
                    size: 22,
                  ),
                  hintText: _esSoloCortesia
                      ? 'Observaciones (ej. Cortesía olvidada de venta anterior)'
                      : 'Observaciones / Notas de venta',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _brandOrange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 6. Botón de Acción Principal "CONFIRMAR PAGO" (con microinteracción de escala)
              GestureDetector(
                onTapDown: (_) => setState(() => _isButtonPressed = true),
                onTapUp: (_) {
                  setState(() => _isButtonPressed = false);
                  _confirmarCobro();
                },
                onTapCancel: () => setState(() => _isButtonPressed = false),
                child: AnimatedScale(
                  scale: _isButtonPressed ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_emeraldGreen, _emeraldDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _emeraldGreen.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _esSoloCortesia
                                    ? 'CONFIRMAR ENTREGA / CORTESÍA'
                                    : 'CONFIRMAR PAGO',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
