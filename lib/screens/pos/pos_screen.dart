import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/controllers/promocion_controller.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_cart_summary.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_product_grid.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_category_filter.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_historial_boletas_sheet.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_item_detail_sheet.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_cobro_sheet.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_venta_exitosa_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late final PosController _posController;
  DateTime? _fechaVentaAnterior;

  @override
  void initState() {
    super.initState();
    _posController = context.read<PosController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _posController.loadInitialData();
    });
  }

  @override
  void dispose() {
    _posController.setFechaVentaPersonalizada(null);
    if (_posController.carrito.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_posController.carrito.isNotEmpty) {
          _posController.limpiarCarrito();
        }
      });
    }
    super.dispose();
  }

  void _showVentasAnterioresModal() {
    DateTime? fechaSeleccionada = _fechaVentaAnterior;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Ventas Anteriores'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleccione la fecha para registrar ventas retroactivas:',
                ),
                const SizedBox(height: 16),
                AppDatePicker(
                  label: 'Fecha Venta',
                  selectedDate: fechaSeleccionada ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  onDateChanged: (d) {
                    setDialogState(() => fechaSeleccionada = d);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () {
                  if (fechaSeleccionada != null &&
                      fechaSeleccionada!.isAfter(DateTime.now())) {
                    return;
                  }
                  setState(() => _fechaVentaAnterior = fechaSeleccionada);
                  _posController.setFechaVentaPersonalizada(fechaSeleccionada);
                  Navigator.pop(ctx);
                },
                child: const Text('Aplicar Fecha'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onPosItemTapped(PosItem item) async {
    final controller = context.read<PosController>();
    final continuarAlCobro = await PosItemDetailSheet.show(
      context: context,
      item: item,
      controller: controller,
    );

    if (continuarAlCobro == true && mounted) {
      _showCobroModal();
    }
  }

  Future<void> _onPromocionTapped(Promocion promo) async {
    final controller = context.read<PosController>();
    final continuarAlCobro = await PosItemDetailSheet.showPromo(
      context: context,
      promo: promo,
      controller: controller,
    );

    if (continuarAlCobro == true && mounted) {
      _showCobroModal();
    }
  }

  Future<void> _showCobroModal() async {
    final controller = context.read<PosController>();
    if (controller.carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
      return;
    }

    final cobroResult = await PosCobroSheet.show(
      context: context,
      controller: controller,
      fechaVentaAnterior: _fechaVentaAnterior,
    );

    if (cobroResult != null && mounted) {
      PosVentaExitosaDialog.show(
        context: context,
        pdfPath: cobroResult.pdfPath,
        total: cobroResult.total,
        metodoPago: cobroResult.metodoPago,
        ticketNum: cobroResult.ticketNum,
      );
    }
  }

  void _showHistorialBoletasModal() {
    final controller = context.read<PosController>();
    PosHistorialBoletasSheet.show(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PosController>(
      builder: (context, controller, child) {
        final promoController = context.watch<PromocionController>();
        final promosValidas = controller.promociones
            .where(promoController.isPromocionValidaAhora)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF9F5),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Center(
              child: Material(
                color: Colors.transparent,
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
                      color: Color(0xFF1F2937),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Ventas (POS)',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.history,
                  color: Color(0xFF1F2937),
                  size: 24,
                ),
                tooltip: 'Historial de Boletas',
                onPressed: _showHistorialBoletasModal,
              ),
              IconButton(
                icon: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF1F2937),
                  size: 24,
                ),
                tooltip: 'Pre-preparación',
                onPressed: () {
                  controller.limpiarCarrito();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegistroPreparacionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            bottom: true,
            child: controller.isLoading && controller.posItems.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD62828)),
                  )
                : Container(
                    color: const Color(0xFFFBF9F5),
                    child: Column(
                      children: [
                        _buildHistoricalSalesControl(),

                        // Filtro Categorias
                        PosCategoryFilter(controller: controller),

                        // Grid de Productos y Promociones
                        Expanded(
                          child: PosProductGrid(
                            controller: controller,
                            onItemTapped: _onPosItemTapped,
                            promociones: promosValidas,
                            onPromoTapped: _onPromocionTapped,
                          ),
                        ),

                        // Resumen de Carrito Fijo Abajo
                        PosCartSummary(
                          controller: controller,
                          onCobrar: _showCobroModal,
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHistoricalSalesControl() {
    final selectedDate = _fechaVentaAnterior;
    final isHistorical =
        selectedDate != null &&
        DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        ).isBefore(AppDateUtils.todayStart);

    if (selectedDate == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showVentasAnterioresModal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD62828).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFFD62828),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Registrar ventas anteriores',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD62828),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Material(
        color: isHistorical ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          child: Row(
            children: [
              Icon(
                isHistorical ? Icons.history_rounded : Icons.today_rounded,
                color: isHistorical
                    ? const Color(0xFFD97706)
                    : const Color(0xFF1E4630),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${isHistorical ? 'Venta histórica' : 'Fecha de venta'} · ${AppDateUtils.formatDisplay(selectedDate)}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1F2937),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cambiar fecha',
                visualDensity: VisualDensity.compact,
                onPressed: _showVentasAnterioresModal,
                icon: const Icon(
                  Icons.edit_calendar_outlined,
                  size: 18,
                  color: Color(0xFF4B5563),
                ),
              ),
              IconButton(
                tooltip: 'Volver a ventas de hoy',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() => _fechaVentaAnterior = null);
                  _posController.setFechaVentaPersonalizada(null);
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
