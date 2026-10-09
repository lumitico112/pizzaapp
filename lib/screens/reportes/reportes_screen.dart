import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import 'package:pizzaapp/controllers/reporte_controller.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String _filtroSeleccionado = 'Hoy';
  final List<String> _filtros = [
    'Hoy',
    'Ayer',
    'Esta Semana',
    'Este Mes',
    'Personalizado'
  ];

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarFiltro('Hoy');
    });
  }

  Future<void> _aplicarFiltro(String filtro) async {
    final now = DateTime.now();
    DateTime inicio = now;
    DateTime fin = now;

    if (filtro == 'Hoy') {
      inicio = DateTime(now.year, now.month, now.day);
      fin = inicio;
    } else if (filtro == 'Ayer') {
      inicio = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      fin = inicio;
    } else if (filtro == 'Esta Semana') {
      inicio = now.subtract(Duration(days: now.weekday - 1));
      inicio = DateTime(inicio.year, inicio.month, inicio.day);
      fin = DateTime(now.year, now.month, now.day);
    } else if (filtro == 'Este Mes') {
      inicio = DateTime(now.year, now.month, 1);
      fin = DateTime(now.year, now.month + 1, 0);
    } else if (filtro == 'Personalizado') {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: _fechaInicio != null && _fechaFin != null
            ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
            : null,
      );
      if (picked != null) {
        inicio = picked.start;
        fin = picked.end;
      } else {
        return; // Usuario cancelÃ³
      }
    }

    setState(() {
      _filtroSeleccionado = filtro;
      _fechaInicio = inicio;
      _fechaFin = fin;
    });

    if (mounted) {
      context.read<ReporteController>().cargarReporte(inicio, fin);
    }
  }

  Widget _buildMetricCard(String title, double amount, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes AnalÃ­ticos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ctrl = context.read<ReporteController>();
          final path = await ctrl.generarPDF();
          if (path != null && path.isNotEmpty) {
            await OpenFilex.open(path);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            width: double.infinity,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: _filtros.map((f) {
                final isSelected = _filtroSeleccionado == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _aplicarFiltro(f);
                    }
                  },
                );
              }).toList(),
            ),
          ),

          if (_fechaInicio != null && _fechaFin != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rango: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

          Expanded(
            child: Consumer<ReporteController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.error != null) {
                  return Center(child: Text('Error: ${controller.error}'));
                }

                // Asumimos que controller.reporte expone el modelo ReporteData
                // Si aÃºn no estÃ¡, el backend lo proveerÃ¡.
                final reporte = controller.reporte;
                if (reporte == null) {
                  return const Center(
                      child: Text('No hay datos disponibles para este rango.'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.5,
                        children: [
                          _buildMetricCard('Ingresos Totales',
                              reporte.totalIngresos, AppColors.success),
                          _buildMetricCard('Total Gastos / Salidas',
                              reporte.totalGastos, AppColors.error),
                          _buildMetricCard('Costo de MercaderÃ­a',
                              reporte.costoMercaderia, AppColors.warning),
                          _buildMetricCard(
                              'Beneficio Neto',
                              reporte.beneficioNeto,
                              reporte.beneficioNeto >= 0
                                  ? AppColors.success
                                  : AppColors.error),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Productos MÃ¡s Vendidos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (reporte.productosVendidos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text('No hay productos vendidos en este periodo.',
                              style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reporte.productosVendidos.length,
                          itemBuilder: (context, index) {
                            final producto = reporte.productosVendidos[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(producto.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text('${producto.cantidad} unidades'),
                                trailing: Text(
                                  CurrencyFormatter.format(producto.total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

