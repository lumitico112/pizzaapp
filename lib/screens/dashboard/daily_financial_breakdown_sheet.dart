import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'package:pizzaapp/services/dashboard_service.dart';

class DailyFinancialBreakdownSheet extends StatefulWidget {
  const DailyFinancialBreakdownSheet({super.key});

  @override
  State<DailyFinancialBreakdownSheet> createState() =>
      _DailyFinancialBreakdownSheetState();
}

class _DailyFinancialBreakdownSheetState
    extends State<DailyFinancialBreakdownSheet> {
  String _filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .9,
      child: Material(
        color: const Color(0xFFFBF9F5),
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Consumer<DashboardController>(
            builder: (context, controller, _) {
              final summary = controller.summary;
              final movements = summary.movimientos.where((movement) {
                if (_filter == 'Ventas') return movement.esVenta;
                if (_filter == 'Gastos') return !movement.esVenta;
                return true;
              }).toList();
              final totalUnidades = summary.productos.fold<int>(
                0,
                (sum, product) => sum + product.cantidad,
              );
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6D0C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen del Día',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(DateTime.now())} · Última act. ${DateFormat('HH:mm').format(summary.actualizacion)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const _LiveIndicator(),
                            IconButton(
                              tooltip: 'Cerrar',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF6B7280),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Ventas',
                                amount: summary.ventas,
                                detail:
                                    '${summary.cantidadVentas} ${summary.cantidadVentas == 1 ? 'venta' : 'ventas'}',
                                color: const Color(0xFF15803D),
                                background: const Color(0xFFDCFCE7),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: _MetricCard(
                                label: 'Gastos',
                                amount: summary.gastos,
                                detail:
                                    '${summary.cantidadGastos} ${summary.cantidadGastos == 1 ? 'movimiento' : 'movimientos'}',
                                color: const Color(0xFFB91C1C),
                                background: const Color(0xFFFEE2E2),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: _MetricCard(
                                label: 'Balance',
                                amount: summary.ganancia,
                                detail: 'Ventas − gastos',
                                color: const Color(0xFFC2410C),
                                background: const Color(0xFFFFEDD5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final filter in [
                                'Todos',
                                'Ventas',
                                'Gastos',
                                'Productos',
                              ]) ...[
                                if (filter != 'Todos') const SizedBox(width: 8),
                                ChoiceChip(
                                  showCheckmark: true,
                                  avatar: filter == 'Productos'
                                      ? const Icon(
                                          Icons.local_pizza_outlined,
                                          size: 14,
                                        )
                                      : null,
                                  label: Text(filter),
                                  selected: _filter == filter,
                                  onSelected: (_) =>
                                      setState(() => _filter = filter),
                                  visualDensity: VisualDensity.compact,
                                  selectedColor: const Color(0xFFFFEBE3),
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _filter == filter
                                        ? const Color(0xFFD62828)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _filter == 'Productos'
                          ? _ProductsTable(
                              key: const ValueKey('productos'),
                              productos: summary.productos,
                              totalUnidades: totalUnidades,
                              totalVentas: summary.ventas,
                            )
                          : movements.isEmpty
                          ? Center(
                              key: ValueKey('empty-$_filter'),
                              child: Text(
                                'Aún no hay movimientos para mostrar.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            )
                          : ListView.separated(
                              key: ValueKey('movements-$_filter'),
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              itemCount: movements.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: Color(0xFFE5E7EB),
                              ),
                              itemBuilder: (context, index) => _MovementTile(
                                movement: movements[index],
                                recent: index == 0,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.detail,
    required this.color,
    required this.background,
  });

  final String label;
  final double amount;
  final String detail;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 83),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            CurrencyFormatter.format(amount),
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 8.5, color: color),
        ),
      ],
    ),
  );
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement, required this.recent});

  final DashboardMovement movement;
  final bool recent;

  @override
  Widget build(BuildContext context) {
    final color = movement.esVenta
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final background = movement.esVenta
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2);
    final clock = DateFormat('h:mm').format(movement.fecha);
    final period = movement.fecha.hour < 12 ? 'a. m.' : 'p. m.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: background,
            child: Icon(
              movement.esVenta
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        movement.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (recent) ...[
                      const SizedBox(width: 6),
                      const _RecentBadge(),
                    ],
                  ],
                ),
                Text(
                  '${movement.referencia} · $clock $period${movement.metodoPago == null || movement.metodoPago!.isEmpty ? '' : ' · ${_paymentMethodLabel(movement.metodoPago!)}'}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${movement.esVenta ? '+' : '-'} ${CurrencyFormatter.format(movement.monto)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String _paymentMethodLabel(String value) {
  switch (value.toLowerCase()) {
    case 'efectivo':
      return 'Efectivo';
    case 'yape':
      return 'Yape';
    case 'plin':
      return 'Plin';
    case 'mixto':
      return 'Mixto';
    case 'tarjeta':
      return 'Tarjeta';
    default:
      return value;
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({
    super.key,
    required this.productos,
    required this.totalUnidades,
    required this.totalVentas,
  });

  final List<DashboardProductSales> productos;
  final int totalUnidades;
  final double totalVentas;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('products-table-card'),
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: const _ProductTableRow(
              product: 'PRODUCTO',
              quantity: 'CANT.',
              total: 'TOTAL',
              isHeader: true,
            ),
          ),
          Expanded(
            child: productos.isEmpty
                ? Center(
                    child: Text(
                      'Aún no hay productos vendidos hoy.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: productos.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: Color(0xFFF3F4F6),
                    ),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: _ProductTableRow(
                        product: productos[index].nombre,
                        quantity: productos[index].cantidad.toString(),
                        total: CurrencyFormatter.format(productos[index].total),
                      ),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 60,
                  child: Text(
                    'Total unidades: $totalUnidades',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                Expanded(
                  flex: 40,
                  child: Text(
                    CurrencyFormatter.format(totalVentas),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTableRow extends StatelessWidget {
  const _ProductTableRow({
    required this.product,
    required this.quantity,
    required this.total,
    this.isHeader = false,
  });

  final String product;
  final String quantity;
  final String total;
  final bool isHeader;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 60,
        child: Text(
          product,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: isHeader ? 11 : 13,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
            color: isHeader ? const Color(0xFF6B7280) : const Color(0xFF1F2937),
          ),
        ),
      ),
      Expanded(
        flex: 15,
        child: Center(
          child: isHeader
              ? Text(
                  quantity,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBE3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quantity,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD62828),
                    ),
                  ),
                ),
        ),
      ),
      Expanded(
        flex: 25,
        child: Text(
          total,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: isHeader ? 11 : 13,
            fontWeight: FontWeight.bold,
            color: isHeader ? const Color(0xFF6B7280) : const Color(0xFF059669),
          ),
        ),
      ),
    ],
  );
}

class _RecentBadge extends StatelessWidget {
  const _RecentBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDD5),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      'Reciente',
      style: GoogleFonts.poppins(
        fontSize: 8,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFC2410C),
      ),
    ),
  );
}

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFDCFCE7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: .35, end: 1).animate(_pulse),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'En tiempo real',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF15803D),
          ),
        ),
      ],
    ),
  );
}
