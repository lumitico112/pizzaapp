import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';
import 'package:intl/intl.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'package:pizzaapp/screens/preparacion/widgets/gestion_sobrantes_modal.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF1F2937);
  static const _muted = Color(0xFF6B7280);
  static const _cream = Color(0xFFFBF9F5);
  static const _green = Color(0xFF059669);
  static const _purple = Color(0xFF7C3AED);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _generandoArqueo = false;

  String _formatCycleStart(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd/MM/yyyy · HH:mm').format(date);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CajaController>().loadDatosCaja();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _abrirCajaDialog() {
    final cajaController = context.read<CajaController>();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return _AbrirCajaDialog(controller: cajaController);
      },
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _reabrirCajaDialog(SesionCaja sesion) async {
    final motivoCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    String formatearFechaHora(String isoString) {
      final dt = DateTime.tryParse(isoString);
      if (dt == null) return isoString;
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final anio = dt.year.toString();
      final hora12 =
          dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final horaStr = hora12.toString().padLeft(2, '0');
      final minStr = dt.minute.toString().padLeft(2, '0');
      final periodo = dt.hour >= 12 ? 'p. m.' : 'a. m.';
      return '$dia/$mes/$anio a las $horaStr:$minStr $periodo';
    }

    final fechaTexto = formatearFechaHora(sesion.fechaApertura);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool obscurePassword = true;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado del Modal
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEBE3),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFFD62828),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Reapertura excepcional',
                              style: GoogleFonts.poppins(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Texto Informativo con Fecha Formateada
                      Text(
                        'Se reabrirá el ciclo iniciado el $fechaTexto. La autorización y el motivo quedarán registrados.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo 1: Motivo obligatorio
                      SizedBox(
                        height: 52,
                        child: TextField(
                          controller: motivoCtrl,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2937),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Motivo obligatorio',
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                            prefixIcon: const Icon(
                              Icons.assignment_late_outlined,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFD62828),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Campo 2: Contraseña de administradora
                      SizedBox(
                        height: 52,
                        child: TextField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2937),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Contraseña de administradora',
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                            prefixIcon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF6B7280),
                                size: 20,
                              ),
                              onPressed: () => setDialogState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFD62828),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Fila de Botones Inferiores (Actions Row)
                      Row(
                        children: [
                          // Botón Cancelar (Izquierda)
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Botón Autorizar y reabrir (Derecha)
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6A00),
                                    Color(0xFFD62828),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF6A00,
                                    ).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  if (motivoCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Indica el motivo de la reapertura.',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }
                                  if (passwordCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ingresa la contraseña de administradora.',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(ctx, true);
                                },
                                child: Text(
                                  'Autorizar y reabrir',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
          },
        );
      },
    );
    if (!mounted || confirmado != true) return;
    try {
      await context.read<CajaController>().reabrirCaja(
        sesion.id!,
        motivoCtrl.text,
        passwordCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se reabrió el ciclo de caja y quedó auditado.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _descargarArqueo(SesionCaja sesion) async {
    if (_generandoArqueo) return;
    setState(() => _generandoArqueo = true);
    try {
      final pdfPath = await context.read<CajaController>().generarArqueoPDF(
        sesion,
      );
      if (!mounted || pdfPath == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Arqueo PDF generado.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ver PDF',
            onPressed: () => OpenFilex.open(pdfPath),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoArqueo = false);
    }
  }

  void _registrarMovimientoDialog(String tipo) {
    final cajaController = context.read<CajaController>();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return _MovimientoManualDialog(
          tipo: tipo,
          controller: cajaController,
        );
      },
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _cerrarCajaDialog(SesionCaja sesion, CashCloseSummary resumen) {
    final efectivoRealCtrl = TextEditingController(text: '0');
    final transferenciasRealesCtrl = TextEditingController(text: '0');
    final notaCtrl = TextEditingController();
    var cerrando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final real = double.tryParse(efectivoRealCtrl.text) ?? 0;
          final transferencias =
              double.tryParse(transferenciasRealesCtrl.text) ?? 0;
          final difEfectivo = real - resumen.efectivoEsperado;
          final difTransferencias =
              transferencias - resumen.transferenciasEsperadas;
          final dif = difEfectivo + difTransferencias;
          final colorDif = dif.abs() < 0.005
              ? AppColors.success
              : (dif > 0 ? AppColors.warning : AppColors.error);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cerrar Caja',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _closeMetric(
                          'Ventas efectivo',
                          resumen.ventasEfectivo,
                          _green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _closeMetric(
                          'Ventas Yape/Plin',
                          resumen.ventasTransferencias,
                          _purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _closeMetric(
                          'Balance esperado',
                          resumen.efectivoEsperado +
                              resumen.transferenciasEsperadas,
                          _ink,
                          emphasize: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _summaryChip('Inicio efectivo', sesion.montoApertura),
                      _summaryChip(
                        'Inicio Yape/Plin',
                        sesion.transferenciasApertura,
                      ),
                      _summaryChip(
                        'Efectivo esperado',
                        resumen.efectivoEsperado,
                      ),
                      _summaryChip(
                        'Yape/Plin esperado',
                        resumen.transferenciasEsperadas,
                      ),
                      _summaryChip('Gastos del ciclo', resumen.gastosDelCiclo),
                      _summaryChip('Salidas de esta caja', resumen.gastos),
                    ],
                  ),
                  if (resumen.ventasPorProducto.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Ventas por producto',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...resumen.ventasPorProducto.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} · ${item.variantName}${item.courtesyQuantity > 0 ? '  (${item.courtesyQuantity} cortesía)' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _ink,
                                ),
                              ),
                            ),
                            Text(
                              '${item.quantity} ud.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(item.total),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (resumen.preparadosRestantes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Producto preparado disponible',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...resumen.preparadosRestantes.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} · ${item.variantName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _ink,
                                ),
                              ),
                            ),
                            Text(
                              '${item.quantity} ud.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final changed = await GestionSobrantesModal.show(
                          ctx,
                          esCierreDeCiclo: true,
                        );
                        if (changed && mounted) {
                          await context.read<CajaController>().loadDatosCaja();
                          if (ctx.mounted) {
                            setStateDialog(() {
                              final updated = context
                                  .read<CajaController>()
                                  .resumenActual;
                              if (updated != null) {
                                resumen = updated;
                              }
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Gestionar sobrantes y mermas'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Efectivo Real Contado',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: efectivoRealCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'S/  ',
                      hintText: '0.00',
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    onChanged: (v) => setStateDialog(() {}),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Yape / Plin Real Contado',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: transferenciasRealesCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'S/  ',
                      hintText: '0.00',
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    onChanged: (v) => setStateDialog(() {}),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Nota (Opcional)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notaCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'Escribe una observación si hubo algún descuadre...',
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorDif.withValues(alpha: .08),
                      border: Border.all(
                        color: colorDif.withValues(alpha: .24),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: colorDif),
                            const SizedBox(width: 8),
                            Text(
                              'Diferencia: S/ ${dif.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorDif,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Efectivo: S/ ${difEfectivo.toStringAsFixed(2)} · Yape/Plin: S/ ${difTransferencias.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: colorDif),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: cerrando
                        ? null
                        : () async {
                            if (real < 0 || transferencias < 0) return;
                            setStateDialog(() => cerrando = true);
                            try {
                              final cerrada = await context
                                  .read<CajaController>()
                                  .cerrarCaja(
                                    real,
                                    transferencias,
                                    notaCtrl.text,
                                  );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (!mounted) return;
                              final pdfPath = await context
                                  .read<CajaController>()
                                  .generarArqueoPDF(cerrada);
                              if (pdfPath != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Caja cerrada con éxito',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'Ver PDF',
                                      onPressed: () {
                                        OpenFilex.open(pdfPath);
                                      },
                                    ),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) {
                                setStateDialog(() => cerrando = false);
                              }
                            }
                          },
                    child: Text(
                      cerrando ? 'CERRANDO…' : 'CONFIRMAR CIERRE DE CAJA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CajaController>();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: Semantics(
            button: true,
            label: 'Volver a la pantalla anterior',
            child: Material(
              color: Colors.transparent,
              child: Tooltip(
                message: 'Volver',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _ink,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Gestión de Caja',
          style: GoogleFonts.poppins(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ctrl.isLoading
            ? const AppLoadingState(message: 'Cargando...')
            : (ctrl.yaEstaCerrado || ctrl.sesionActual == null)
            ? _buildCajaCerradaView(ctrl)
            : _buildCajaAbierta(ctrl.sesionActual!, ctrl.resumenActual),
      ),
    );
  }

  Widget _buildCajaCerradaView(CajaController ctrl) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 36),

              // Gráfico Central con respiración / flotación
              _buildCajaCerradaIlustracion(),

              const SizedBox(height: 28),

              // Texto de Estado
              Text(
                'La caja se encuentra cerrada.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia un nuevo ciclo de cobro para comenzar a registrar ventas y operaciones.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: _muted,
                  height: 1.4,
                ),
              ),

              if (ctrl.ultimaSesionCerrada != null) ...[
                const SizedBox(height: 20),
                _buildUltimoCierreCard(ctrl),
              ],

              const SizedBox(height: 24),

              Semantics(
                button: true,
                label: 'Abrir nuevo ciclo de caja',
                onTap: _abrirCajaDialog,
                child: ExcludeSemantics(
                  child: _InteractiveScaleButton(
                  onTap: _abrirCajaDialog,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6A00), Color(0xFFD62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD62828).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_open_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Abrir nuevo ciclo',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ),
              ),

              if (ctrl.puedeAutorizarReapertura &&
                  ctrl.ultimaSesionCerrada != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _reabrirCajaDialog(ctrl.ultimaSesionCerrada!),
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: Text(
                      'Reabrir excepcionalmente el último ciclo',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltimoCierreCard(CajaController ctrl) {
    final sesion = ctrl.ultimaSesionCerrada!;
    final resumen = ctrl.resumenUltimoCierre;
    final original =
        resumen?.totalEsperado ??
        (sesion.totalEsperado > 0
            ? sesion.totalEsperado
            : sesion.totalEfectivoSistema + sesion.totalYapePlin);
    final ajuste = resumen?.ajusteHistorico.total ?? 0;
    final ajustado = resumen?.totalEsperadoAjustado ?? original;
    final contado = sesion.efectivoContado + sesion.transferenciasContadas;
    final diferencia =
        resumen?.diferenciaAjustada(
          efectivo: sesion.efectivoContado,
          transferencias: sesion.transferenciasContadas,
        ) ??
        sesion.diferencia;
    final colorDiferencia = diferencia.abs() < 0.005
        ? _green
        : (diferencia > 0 ? AppColors.warning : AppColors.error);
    final cantidadAjustes = resumen?.ventasHistoricas ?? 0;
    final cierre = sesion.fechaCierre == null
        ? 'Sin fecha de cierre'
        : _formatCycleStart(sesion.fechaCierre!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Último cierre · #${sesion.id.toString().padLeft(4, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Apertura: ${_formatCycleStart(sesion.fechaApertura)}\nCierre: $cierre',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _closeMetric('Cierre original', original, _ink),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _closeMetric(
                  'Ajuste histórico',
                  ajuste,
                  ajuste > 0 ? const Color(0xFFD97706) : _muted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _closeMetric(
                  'Total ajustado',
                  ajustado,
                  _ink,
                  emphasize: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _closeMetric('Contado', contado, _ink)),
              const SizedBox(width: 6),
              Expanded(
                child: _closeMetric(
                  'Diferencia',
                  diferencia,
                  colorDiferencia,
                  emphasize: true,
                ),
              ),
            ],
          ),
          if (cantidadAjustes > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '$cantidadAjustes venta${cantidadAjustes == 1 ? '' : 's'} histórica${cantidadAjustes == 1 ? '' : 's'} incluida${cantidadAjustes == 1 ? '' : 's'} como ajuste. El cierre original no se modificó.',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: const Color(0xFF92400E),
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _generandoArqueo
                  ? null
                  : () => _descargarArqueo(sesion),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(
                _generandoArqueo
                    ? 'Generando arqueo…'
                    : 'Descargar arqueo PDF',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaCerradaIlustracion() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEBE3)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6A00).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD8C8),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD62828).withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.point_of_sale_rounded,
                  size: 36,
                  color: Color(0xFFFF6A00),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD62828),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD62828).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCajaAbierta(SesionCaja sesion, CashCloseSummary? resumen) {
    final resumenCaja =
        resumen ??
        const CashCloseSummary(
          efectivoEsperado: 0,
          transferenciasEsperadas: 0,
          gastos: 0,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _CajaFadeInUp(
                  delayMs: 0,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFFA7F3D0),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF059669),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Caja Abierta',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF065F46),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ciclo operativo desde ${_formatCycleStart(sesion.fechaApertura)}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4B5563),
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Métrica Principal (Hero)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000)
                                    .withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFF059669),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Efectivo esperado',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'S/ ${resumenCaja.efectivoEsperado.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF1F2937),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Grid de Sub-métricas (2 columnas, separación 10px)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.15,
                          children: [
                            _subMetricCard(
                              icon: Icons.payments_outlined,
                              label: 'Inicio efectivo',
                              amount: sesion.montoApertura,
                              valueColor: const Color(0xFF059669),
                              iconColor: const Color(0xFF059669),
                            ),
                            _subMetricCard(
                              icon: Icons.qr_code_2_rounded,
                              label: 'Inicio Yape/Plin',
                              amount: sesion.transferenciasApertura,
                              valueColor: const Color(0xFF7C3AED),
                              iconColor: const Color(0xFF7C3AED),
                            ),
                            _subMetricCard(
                              icon: Icons.trending_up_rounded,
                              label: 'Ventas en efectivo',
                              amount: resumenCaja.ventasEfectivo,
                              valueColor: const Color(0xFF059669),
                              iconColor: const Color(0xFF059669),
                            ),
                            _subMetricCard(
                              icon: Icons.phonelink_ring_outlined,
                              label: 'Ventas Yape/Plin',
                              amount: resumenCaja.ventasTransferencias,
                              valueColor: const Color(0xFF7C3AED),
                              iconColor: const Color(0xFF7C3AED),
                            ),
                            _subMetricCard(
                              icon: Icons.call_made_rounded,
                              label: 'Salidas de caja',
                              amount: resumenCaja.gastos,
                              valueColor: const Color(0xFFDC2626),
                              iconColor: const Color(0xFFDC2626),
                            ),
                            _subMetricCard(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Gastos del ciclo',
                              amount: resumenCaja.gastosDelCiclo,
                              valueColor: const Color(0xFFDC2626),
                              iconColor: const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Yape/Plin esperado (Ancho completo abajo)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000)
                                    .withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 18,
                                color: Color(0xFF1F2937),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Yape/Plin esperado',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              Text(
                                'S/ ${resumenCaja.transferenciasEsperadas.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Fila Entrada / Salida (Row con 12px de separación)
                _CajaFadeInUp(
                  delayMs: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: _operationGradientButton(
                          label: 'Entrada',
                          icon: Icons.south_west_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6A00), Color(0xFFEA580C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: const Color(0xFFFF6A00),
                          onTap: () => _registrarMovimientoDialog('entrada'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _operationGradientButton(
                          label: 'Salida / Gasto',
                          icon: Icons.north_east_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD62828), Color(0xFFB91C1C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: const Color(0xFFD62828),
                          onTap: () => _registrarMovimientoDialog('salida'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Botón Inferior ("CERRAR CAJA")
          _CajaFadeInUp(
            delayMs: 160,
            child: Semantics(
              button: true,
              label: 'Cerrar caja actual',
              onTap: () => _cerrarCajaDialog(sesion, resumenCaja),
              child: ExcludeSemantics(
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB91C1C).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _cerrarCajaDialog(sesion, resumenCaja),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'CERRAR CAJA',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subMetricCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color valueColor,
    required Color iconColor,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'S/ ${amount.toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _operationGradientButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 8),
                Text(
                  label,
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
  );

  Widget _closeMetric(
    String label,
    double amount,
    Color color, {
    bool emphasize = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: _muted),
        ),
        const SizedBox(height: 4),
        Text(
          'S/ ${amount.toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: emphasize ? 13 : 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _summaryChip(String label, double amount) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$label · S/ ${amount.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 11, color: _muted),
    ),
  );
}

class _InteractiveScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveScaleButton({required this.onTap, required this.child});

  @override
  State<_InteractiveScaleButton> createState() => _InteractiveScaleButtonState();
}

class _InteractiveScaleButtonState extends State<_InteractiveScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

class _AbrirCajaDialog extends StatefulWidget {
  final CajaController controller;

  const _AbrirCajaDialog({required this.controller});

  @override
  State<_AbrirCajaDialog> createState() => _AbrirCajaDialogState();
}

class _AbrirCajaDialogState extends State<_AbrirCajaDialog> {
  final _efectivoCtrl = TextEditingController(text: '0');
  final _transferenciasCtrl = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void dispose() {
    _efectivoCtrl.dispose();
    _transferenciasCtrl.dispose();
    super.dispose();
  }

  double? _parseSaldo(String value) {
    if (value.trim().isEmpty) return 0;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _abrir() async {
    FocusScope.of(context).unfocus();
    final efectivo = _parseSaldo(_efectivoCtrl.text);
    final digital = _parseSaldo(_transferenciasCtrl.text);
    if (efectivo == null ||
        digital == null ||
        !efectivo.isFinite ||
        !digital.isFinite ||
        efectivo < 0 ||
        digital < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa saldos válidos, iguales o mayores a cero.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.controller.abrirCaja(efectivo, digital);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado del Modal
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBE3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_open_outlined,
                    color: Color(0xFFD62828),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Abrir Caja',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo 1: Efectivo disponible
            Text(
              'Efectivo disponible',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              child: TextField(
                controller: _efectivoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  prefixText: 'S/ ',
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6A00),
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Campo 2: Saldo disponible en Yape/Plin
            Text(
              'Saldo disponible en Yape/Plin',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              child: TextField(
                controller: _transferenciasCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.qr_code_2_outlined,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  prefixText: 'S/ ',
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6A00),
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Texto de Advertencia
            Text(
              'Estos saldos se calculan por separado durante el cierre.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 20),

            // Fila de Botones de Acción
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _saving ? null : _abrir,
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6A00), Color(0xFFD62828)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD62828)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Abrir',
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CajaFadeInUp extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _CajaFadeInUp({required this.child, this.delayMs = 0});

  @override
  State<_CajaFadeInUp> createState() => _CajaFadeInUpState();
}

class _CajaFadeInUpState extends State<_CajaFadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _MovimientoManualDialog extends StatefulWidget {
  final String tipo;
  final CajaController controller;

  const _MovimientoManualDialog({
    required this.tipo,
    required this.controller,
  });

  @override
  State<_MovimientoManualDialog> createState() =>
      _MovimientoManualDialogState();
}

class _MovimientoManualDialogState extends State<_MovimientoManualDialog> {
  final _descCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  String _metodoPago = 'efectivo';
  bool _guardando = false;

  bool get _isEntrada => widget.tipo == 'entrada';

  @override
  void dispose() {
    _descCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto =
        double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final desc = _descCtrl.text.trim();

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa una descripción o motivo.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido mayor a cero.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await widget.controller.registrarMovimientoManual(
        widget.tipo,
        desc,
        monto,
        _metodoPago,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEntrada
                  ? 'Entrada registrada exitosamente.'
                  : 'Salida / Gasto registrado exitosamente.',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEntrada = _isEntrada;
    final primaryColor =
        isEntrada ? const Color(0xFFFF6A00) : const Color(0xFFD62828);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isEntrada
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isEntrada
                          ? Icons.add_card_rounded
                          : Icons.request_quote_outlined,
                      color: isEntrada
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEntrada
                              ? 'Entrada Manual'
                              : 'Salida Manual / Gasto',
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEntrada
                              ? 'Registra un ingreso de dinero adicional a la caja.'
                              : 'El monto se descontará del saldo esperado del turno.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF6B7280),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Campo 1: Descripción
              TextFormField(
                controller: _descCtrl,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: isEntrada
                      ? 'Descripción'
                      : 'Descripción o motivo del gasto',
                  hintText: isEntrada ? 'ej. Sencillo adicional' : null,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                  prefixIcon: Icon(
                    isEntrada
                        ? Icons.description_outlined
                        : Icons.edit_note_rounded,
                    size: 20,
                    color: const Color(0xFF6B7280),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Campo 2: Monto
              TextFormField(
                controller: _montoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Monto',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                  prefixIcon: Icon(
                    isEntrada
                        ? Icons.attach_money_rounded
                        : Icons.money_off_csred_rounded,
                    size: 20,
                    color: isEntrada
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                  prefixText: 'S/ ',
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Campo 3: Medio de pago
              DropdownButtonFormField<String>(
                initialValue: _metodoPago,
                isExpanded: true,
                isDense: true,
                dropdownColor: Colors.white,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Medio de pago',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                  prefixIcon: Icon(
                    isEntrada
                        ? Icons.account_balance_wallet_outlined
                        : Icons.payments_outlined,
                    size: 20,
                    color: isEntrada
                        ? const Color(0xFFEA580C)
                        : const Color(0xFFDC2626),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'efectivo',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Efectivo',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'yape/plin',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yape / Plin',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _metodoPago = val);
                },
              ),
              const SizedBox(height: 22),

              // Botones de Acción
              Row(
                children: [
                  // Botón "Cancelar"
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _guardando
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Botón "Guardar"
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: isEntrada
                              ? const [Color(0xFFFF6A00), Color(0xFFD62828)]
                              : const [Color(0xFFD62828), Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isEntrada
                                    ? const Color(0xFFFF6A00)
                                    : const Color(0xFFD62828))
                                .withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _guardando ? null : _guardar,
                          child: Center(
                            child: _guardando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Guardar',
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
