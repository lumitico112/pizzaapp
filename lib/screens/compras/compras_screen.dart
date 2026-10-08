import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/compras_controller.dart';
import 'package:pizzaapp/models/compra.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'compra_form_screen.dart';
import 'por_pagar_screen.dart';

enum _FiltroCompras { hoy, semana, mes, historial }

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  _FiltroCompras _filtro = _FiltroCompras.hoy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComprasController>().loadHistorial();
    });
  }

  List<Compra> _filtrarCompras(List<Compra> todas) {
    final hoy = AppDateUtils.todayStart;
    final semana = AppDateUtils.weekStart;
    final mes = AppDateUtils.monthStart;
    return todas.where((c) {
      final fecha = DateTime.tryParse(c.fecha) ?? DateTime(2000);
      return switch (_filtro) {
        _FiltroCompras.hoy => !fecha.isBefore(hoy),
        _FiltroCompras.semana => !fecha.isBefore(semana),
        _FiltroCompras.mes => !fecha.isBefore(mes),
        _FiltroCompras.historial => true,
      };
    }).toList();
  }

  Widget _buildFiltros() {
    const labels = {
      _FiltroCompras.hoy: 'Hoy',
      _FiltroCompras.semana: 'Esta semana',
      _FiltroCompras.mes: 'Este mes',
      _FiltroCompras.historial: 'Historial',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: _FiltroCompras.values.map((f) {
          final selected = f == _filtro;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(labels[f]!),
              selected: selected,
              onSelected: (_) => setState(() => _filtro = f),
              selectedColor: AppColors.primaryDark.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: AppColors.primaryDark,
              side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.cardBorder),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompraCard(Compra c) {
    final costoTotal = c.cantidad * c.costoUnitario;
    final esPorPagar = c.motivo.toLowerCase().contains('por pagar') || c.motivo.toLowerCase().contains('adelanto');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: esPorPagar ? AppColors.warningLight : AppColors.successLight,
          child: Icon(
            esPorPagar ? Icons.schedule_outlined : Icons.check_circle_outline,
            color: esPorPagar ? AppColors.warning : AppColors.success,
          ),
        ),
        title: Text(c.insumoNombre, style: AppTextStyles.labelBold, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.cantidad.toStringAsFixed(2)} ${c.unidadMedida}  •  ${AppDateUtils.formatDisplay(DateTime.tryParse(c.fecha) ?? DateTime.now())}',
                style: AppTextStyles.caption),
            if (c.motivo.isNotEmpty)
              Text('Nota: ${c.motivo}', style: AppTextStyles.caption.copyWith(color: AppColors.info), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(CurrencyFormatter.format(costoTotal), style: AppTextStyles.currencyMedium),
            if (esPorPagar)
              Text('Por pagar', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComprasController>(
      builder: (_, ctrl, __) {
        final comprasFiltradas = _filtrarCompras(ctrl.historial);
        final totalFiltrado = comprasFiltradas.fold(0.0, (sum, c) => sum + (c.cantidad * c.costoUnitario));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Compras'),
            backgroundColor: AppColors.primaryDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'Por pagar',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PorPagarScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: ctrl.loadHistorial,
              ),
            ],
          ),
          body: ctrl.isLoading
              ? const AppLoadingState(message: 'Cargando compras...')
              : Column(
                  children: [
                    _buildFiltros(),
                    if (comprasFiltradas.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${comprasFiltradas.length} compra(s)', style: AppTextStyles.bodySmall),
                            Text('Total: ${CurrencyFormatter.format(totalFiltrado)}', style: AppTextStyles.currencyMedium),
                          ],
                        ),
                      ),
                    Expanded(
                      child: comprasFiltradas.isEmpty
                          ? AppEmptyState(
                              message: 'No hay compras en este período.',
                              icon: Icons.shopping_cart_outlined,
                              actionLabel: 'Registrar compra',
                              onAction: () async {
                                final ok = await Navigator.push<bool>(
                                  context, MaterialPageRoute(builder: (_) => const CompraFormScreen()));
                                if (ok == true && mounted) ctrl.loadHistorial();
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: comprasFiltradas.length,
                              itemBuilder: (_, i) => _buildCompraCard(comprasFiltradas[i]),
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primaryDark,
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context, MaterialPageRoute(builder: (_) => const CompraFormScreen()));
              if (ok == true && mounted) ctrl.loadHistorial();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva Compra'),
          ),
        );
      },
    );
  }
}
