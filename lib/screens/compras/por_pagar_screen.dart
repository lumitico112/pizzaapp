import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/por_pagar_controller.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'package:pizzaapp/models/cuenta_por_pagar.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/compras_controller.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';

/// Pantalla rediseñada de Cuentas por Pagar bajo Material Design 3.
/// Incorpora la paleta de la marca (#FF6A00, #D62828, #10B981, #FBF9F5),
/// tarjetas con acentos laterales, bloque de métricas con progreso visual,
/// banner de próxima cuota y modal de abono con BackdropFilter.
// Paleta de colores corporativa
const Color _primaryOrange = Color(0xFFFF6A00);
const Color _secondaryRed = Color(0xFFD62828);
const Color _successGreen = Color(0xFF10B981);
const Color _successDark = Color(0xFF059669);
const Color _textDark = Color(0xFF1F2937);
const Color _textMuted = Color(0xFF6B7280);
const Color _bgScreen = Color(0xFFFBF9F5);
const Color _cardBorder = Color(0xFFE5E7EB);

class PorPagarScreen extends StatefulWidget {
  const PorPagarScreen({super.key});

  @override
  State<PorPagarScreen> createState() => _PorPagarScreenState();
}

class _PorPagarScreenState extends State<PorPagarScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PorPagarController>().loadCuentas();
    });
  }

  void _verFactura(String ruta) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Factura',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _cardBorder)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comprobante / Factura',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _textMuted,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: InteractiveViewer(child: Image.file(File(ruta))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _verHistorialPagos(int cuentaId) async {
    final pagos = await context.read<PorPagarController>().historialPagos(
      cuentaId,
    );
    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'HistorialPagos',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: Color(0xFF2563EB),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Historial de Pagos',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
                        child: pagos.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'Aún no hay abonos registrados para esta cuenta.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _textMuted,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: pagos.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(color: _cardBorder, height: 1),
                                itemBuilder: (context, index) {
                                  final payment = pagos[index];
                                  final amount =
                                      (payment['monto'] as num).toDouble();
                                  final metodo =
                                      (payment['metodo_pago'] as String?) ??
                                      'efectivo';
                                  final fecha = DateFormatter.formatFechaHora(
                                    payment['fecha'] as String,
                                  );
                                  final nota = payment['nota'] as String?;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.payments_outlined,
                                            size: 18,
                                            color: _successDark,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                CurrencyFormatter.format(
                                                  amount,
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: _successDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$fecha · ${metodo.toUpperCase()}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w400,
                                                  color: _textMuted,
                                                ),
                                              ),
                                              if (nota != null &&
                                                  nota.trim().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  nota,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xFF4B5563,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: _cardBorder),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cerrar',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmarPago(CuentaPorPagar cuenta) async {
    final result = await showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PagarCuota',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: _ModalPagarCuotaDialog(cuenta: cuenta),
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    final abono = result['abono'] as double;
    final metodoPago = result['metodoPago'] as String;
    final nota = result['nota'] as String;

    final success = await context.read<PorPagarController>().pagarCuenta(
          cuenta.id,
          abono,
          metodoPago: metodoPago,
          nota: nota.isNotEmpty ? nota : null,
        );

    if (!mounted) return;

    if (success) {
      context.read<ComprasController>().loadHistorial();
      context.read<CajaController>().loadDatosCaja();
      context.read<DashboardController>().refreshDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abono registrado en Gastos y Caja exitosamente'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PorPagarController>().error ??
                'Error al procesar pago',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cuentas por Pagar',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_secondaryRed, _primaryOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: Consumer<PorPagarController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
              ),
            );
          }

          if (controller.cuentas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: _successDark,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No hay cuentas por pagar',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Todas las compras y créditos a proveedores están al día.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: controller.cuentas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final c = controller.cuentas[index];
              return _StaggeredCuentaCard(
                key: ValueKey(c.id),
                cuenta: c,
                index: index,
                onVerHistorial: () => _verHistorialPagos(c.id),
                onVerFactura: c.facturaRuta != null
                    ? () => _verFactura(c.facturaRuta!)
                    : null,
                onPagar: () => _confirmarPago(c),
              );
            },
          );
        },
      ),
    );
  }
}

/// Tarjeta individual con animación escalonada, acento lateral, métricas y acciones
class _StaggeredCuentaCard extends StatefulWidget {
  final CuentaPorPagar cuenta;
  final int index;
  final VoidCallback onVerHistorial;
  final VoidCallback? onVerFactura;
  final VoidCallback onPagar;

  const _StaggeredCuentaCard({
    super.key,
    required this.cuenta,
    required this.index,
    required this.onVerHistorial,
    this.onVerFactura,
    required this.onPagar,
  });

  @override
  State<_StaggeredCuentaCard> createState() => _StaggeredCuentaCardState();
}

class _StaggeredCuentaCardState extends State<_StaggeredCuentaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cuenta;
    final isActivo = c.activoFijoId != null;
    final esOcasional = c.compraOcasionalId != null;
    final categoriaOcasional = c.compraOcasionalCategoria?.trim();
    final progress = c.costoTotal > 0
        ? (c.montoPagado / c.costoTotal).clamp(0.0, 1.0)
        : 0.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Borde lateral izquierdo de acento (4px)
                Container(
                  width: 4,
                  color: c.pagado
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD62828),
                ),

                // Contenido principal de la tarjeta
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado (Icono + Título + Badge de Estado)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: esOcasional
                                    ? const Color(0xFFEFF6FF)
                                    : isActivo
                                    ? const Color(0xFFFFF1ED)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                esOcasional
                                    ? Icons.receipt_long_outlined
                                    : isActivo
                                    ? Icons.precision_manufacturing_outlined
                                    : Icons.inventory_2_outlined,
                                color: esOcasional
                                    ? const Color(0xFF2563EB)
                                    : isActivo
                                    ? const Color(0xFFD62828)
                                    : const Color(0xFFEA580C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isActivo
                                        ? 'Activo fijo: ${c.insumoNombre}'
                                        : c.insumoNombre,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (esOcasional) ...[
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 3,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFBFDBFE),
                                            ),
                                          ),
                                          child: Text(
                                            'COMPRA OCASIONAL',
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                        if (categoriaOcasional != null &&
                                            categoriaOcasional.isNotEmpty)
                                          Text(
                                            categoriaOcasional,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormatter.formatFecha(c.fecha),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge de Estado (Derecha)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: c.pagado
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c.pagado ? 'PAGADO' : 'PENDIENTE',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: c.pagado
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Bloque de Métricas y Progreso (Gris tenue con 3 columnas)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Total
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(
                                            c.costoTotal,
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Pagado
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Pagado',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(
                                            c.montoPagado,
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF059669),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Saldo
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Saldo',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(
                                            c.saldoPendiente,
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    c.pagado
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFFF6A00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Banner de Próxima Cuota (Solo en Pendientes)
                        if (!c.pagado) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event_repeat_rounded,
                                  size: 18,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Siguiente pago: cuota ${c.cuotaSiguiente} de ${c.cuotas} · ${CurrencyFormatter.format(c.saldoCuotaSiguiente)} por completar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Fila de Acciones Inferior
                        Row(
                          children: [
                            // Botón "Pagos"
                            SizedBox(
                              height: 42,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: Color(0xFF4B5563),
                                ),
                                label: Text(
                                  'Pagos',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                onPressed: widget.onVerHistorial,
                              ),
                            ),
                            if (widget.onVerFactura != null) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 42,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 18,
                                    color: Color(0xFF4B5563),
                                  ),
                                  label: Text(
                                    'Factura',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                  onPressed: widget.onVerFactura,
                                ),
                              ),
                            ],
                            if (!c.pagado) ...[
                              const SizedBox(width: 8),
                              // Botón "PAGAR CUOTA / ABONO"
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: widget.onPagar,
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'PAGAR CUOTA / ABONO',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalPagarCuotaDialog extends StatefulWidget {
  final CuentaPorPagar cuenta;

  const _ModalPagarCuotaDialog({required this.cuenta});

  @override
  State<_ModalPagarCuotaDialog> createState() => _ModalPagarCuotaDialogState();
}

class _ModalPagarCuotaDialogState extends State<_ModalPagarCuotaDialog> {
  late final TextEditingController _ctrl;
  late final TextEditingController _noteCtrl;
  String _paymentMethod = 'efectivo';

  @override
  void initState() {
    super.initState();
    final montoSugerido = (widget.cuenta.saldoCuotaSiguiente > 0
            ? widget.cuenta.saldoCuotaSiguiente
            : widget.cuenta.saldoPendiente)
        .toStringAsFixed(2);
    _ctrl = TextEditingController(text: montoSugerido);
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cuenta = widget.cuenta;
    final categoriaOcasional = cuenta.compraOcasionalCategoria?.trim();
    final nombre = cuenta.esCompraOcasional
        ? [
            'Compra ocasional: ${cuenta.insumoNombre}',
            if (categoriaOcasional != null && categoriaOcasional.isNotEmpty)
              categoriaOcasional,
          ].join(' · ')
        : cuenta.activoFijoId != null
        ? 'Activo: ${cuenta.insumoNombre}'
        : cuenta.insumoNombre;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Encabezado y Resumen
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cuenta.esCompraOcasional
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      cuenta.esCompraOcasional
                          ? Icons.receipt_long_outlined
                          : Icons.payments_outlined,
                      color: cuenta.esCompraOcasional
                          ? const Color(0xFF2563EB)
                          : _successDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pagar cuota ${cuenta.cuotaSiguiente} de ${cuenta.cuotas}',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Tarjeta de Saldos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saldo total pendiente:',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: _textMuted,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            cuenta.saldoPendiente,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cuota ${cuenta.cuotaSiguiente}/${cuenta.cuotas} por completar:',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: _textMuted,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            cuenta.saldoCuotaSiguiente,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Campo: Monto a abonar
              Text(
                'Monto para esta cuota (puedes abonar más o menos)',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: _successDark,
                    size: 20,
                  ),
                  prefixText: 'S/ ',
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _successDark,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _successGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Campo: Método de pago
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: InputDecoration(
                  labelText: 'Método de pago',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _successDark,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _successGreen,
                      width: 1.5,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'efectivo',
                    child: Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: _successDark,
                        ),
                        SizedBox(width: 8),
                        Text('Efectivo'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'yape',
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: Color(0xFF7C3AED),
                        ),
                        SizedBox(width: 8),
                        Text('Yape'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'plin',
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                        SizedBox(width: 8),
                        Text('Plin'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _paymentMethod = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              // 5. Campo: Nota (opcional)
              TextFormField(
                controller: _noteCtrl,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: _textDark,
                ),
                decoration: InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Nota (opcional)',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF6B7280),
                    size: 22,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _successGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 6. Botones de Acción Inferiores
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: _cardBorder,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_successGreen, _successDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _successGreen.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final abono = double.tryParse(
                                  _ctrl.text.replaceAll(',', '.'),
                                ) ??
                                0;
                            if (abono <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'El abono debe ser mayor a cero.',
                                  ),
                                  backgroundColor: Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }
                            if (abono > cuenta.saldoPendiente + 0.000001) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'El abono supera el saldo pendiente.',
                                  ),
                                  backgroundColor: Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context, {
                              'abono': abono,
                              'metodoPago': _paymentMethod,
                              'nota': _noteCtrl.text.trim(),
                            });
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Confirmar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
