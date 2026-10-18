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
  static const _orange = Color(0xFFEA580C);
  static const _purple = Color(0xFF7C3AED);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  String _formatCycleStart(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd/MM/yyyy HH:mm').format(date);
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

  void _registrarMovimientoDialog(String tipo) {
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var metodoPago = 'efectivo';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(
            tipo == 'entrada' ? 'Entrada Manual' : 'Salida Manual / Gasto',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: metodoPago,
                decoration: const InputDecoration(
                  labelText: 'Medio de pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'efectivo',
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 18, color: Color(0xFF059669)),
                        SizedBox(width: 8),
                        Text('Efectivo'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'yape/plin',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF7C3AED)),
                        SizedBox(width: 8),
                        Text('Yape / Plin'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setDialog(() => metodoPago = value ?? 'efectivo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(montoCtrl.text) ?? 0;
                if (val > 0 && descCtrl.text.isNotEmpty) {
                  await context
                      .read<CajaController>()
                      .registrarMovimientoManual(
                        tipo,
                        descCtrl.text,
                        val,
                        metodoPago,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
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
                      Icons.arrow_back,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F8F0), Color(0xFFD1F2E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: _green,
                            size: 23,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Caja Abierta',
                            style: TextStyle(
                              color: _green,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ciclo operativo desde ${_formatCycleStart(sesion.fechaApertura)}',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Efectivo esperado',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'S/ ${resumenCaja.efectivoEsperado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 9,
                        crossAxisSpacing: 9,
                        childAspectRatio: 2.45,
                        children: [
                          _metricCard(
                            'Inicio efectivo',
                            sesion.montoApertura,
                            _green,
                          ),
                          _metricCard(
                            'Inicio Yape/Plin',
                            sesion.transferenciasApertura,
                            _purple,
                          ),
                          _metricCard(
                            'Ventas en efectivo',
                            resumenCaja.ventasEfectivo,
                            _green,
                          ),
                          _metricCard(
                            'Ventas Yape/Plin',
                            resumenCaja.ventasTransferencias,
                            _purple,
                          ),
                          _metricCard(
                            'Salidas de caja',
                            resumenCaja.gastos,
                            const Color(0xFFEF4444),
                          ),
                          _metricCard(
                            'Gastos del ciclo',
                            resumenCaja.gastosDelCiclo,
                            const Color(0xFFEF4444),
                          ),
                          _metricCard(
                            'Yape/Plin esperado',
                            resumenCaja.transferenciasEsperadas,
                            _ink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _operationButton(
                        label: 'Entrada',
                        icon: Icons.arrow_downward_rounded,
                        color: _orange,
                        onTap: () => _registrarMovimientoDialog('entrada'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _operationButton(
                        label: 'Salida / Gasto',
                        icon: Icons.arrow_upward_rounded,
                        color: const Color(0xFFDC2626),
                        onTap: () => _registrarMovimientoDialog('salida'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Cerrar caja actual',
            onTap: () => _cerrarCajaDialog(sesion, resumenCaja),
            child: ExcludeSemantics(
              child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD62828), Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30B91C1C),
                      blurRadius: 13,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _cerrarCajaDialog(sesion, resumenCaja),
                  child: const Text(
                    'CERRAR CAJA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  Widget _metricCard(String label, double amount, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .88),
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
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          'S/ ${amount.toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  Widget _operationButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 19),
          label: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
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
