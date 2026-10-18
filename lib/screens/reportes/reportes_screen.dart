import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import 'package:pizzaapp/controllers/reporte_controller.dart';
import 'package:pizzaapp/core/utils/formatters.dart';

/// Pantalla rediseñada de Reportes Analíticos bajo Material Design 3.
/// Incorpora la paleta de la marca (#FF6A00, #D62828, #10B981, #FBF9F5),
/// selector de periodos en scroll horizontal con chips estilo píldora,
/// cuadrícula de KPIs financieros con iconos y estados semánticos,
/// ranking de productos más vendidos y botón flotante de exportación PDF.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  // Paleta de colores corporativa
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _successGreen = Color(0xFF059669);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _warningAmber = Color(0xFFD97706);
  static const Color _infoBlue = Color(0xFF2563EB);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  String _filtroSeleccionado = 'Hoy';
  final List<String> _filtros = [
    'Hoy',
    'Ayer',
    'Esta semana',
    'Este mes',
    'Personalizada',
  ];

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isFabPressed = false;

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
      inicio = DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 1),
      );
      fin = inicio;
    } else if (filtro == 'Esta semana') {
      inicio = now.subtract(Duration(days: now.weekday - 1));
      inicio = DateTime(inicio.year, inicio.month, inicio.day);
      fin = DateTime(now.year, now.month, now.day);
    } else if (filtro == 'Este mes') {
      inicio = DateTime(now.year, now.month, 1);
      fin = DateTime(now.year, now.month + 1, 0);
    } else if (filtro == 'Personalizada') {
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
        return; // Usuario canceló
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

  String _corregirNombre(String raw) {
    return raw.replaceAll(RegExp(r'hawalana', caseSensitive: false), 'Hawaiiana');
  }

  Future<void> _exportarPDF() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Generando reporte en PDF...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final ctrl = context.read<ReporteController>();
    final path = await ctrl.generarPDF();
    if (path != null && path.isNotEmpty) {
      await OpenFilex.open(path);
    } else if (mounted && ctrl.error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${ctrl.error}'),
          backgroundColor: _errorRed,
        ),
      );
    }
  }

  Widget _buildKpiCard({
    required String title,
    required double amount,
    required Color iconColor,
    required Color bgColor,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(amount),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
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
          'Reportes Analíticos',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Filtros de Rango (Chips Horizontales)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filtros.map((f) {
                  final isSelected = _filtroSeleccionado == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _aplicarFiltro(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [_primaryOrange, _secondaryRed],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? null
                              : Border.all(color: _cardBorder, width: 1),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        _primaryOrange.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              f,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Texto de Rango Activo
            if (_fechaInicio != null && _fechaFin != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Rango: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 18),

            // Contenido dinámico del reporte
            Consumer<ReporteController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_primaryOrange),
                      ),
                    ),
                  );
                }

                if (controller.error != null) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: _errorRed,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Error: ${controller.error}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final reporte = controller.reporte;
                if (reporte == null) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Text(
                      'No hay datos disponibles para este rango.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _textMuted,
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Cuadrícula de KPIs Financieros
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        _buildKpiCard(
                          title: 'Ingresos Totales',
                          amount: reporte.totalIngresos,
                          iconColor: _successGreen,
                          bgColor: const Color(0xFFECFDF5),
                          valueColor: _successGreen,
                          icon: Icons.trending_up_rounded,
                        ),
                        _buildKpiCard(
                          title: 'Total Gastos / Salidas',
                          amount: reporte.totalGastos,
                          iconColor: _errorRed,
                          bgColor: const Color(0xFFFEF2F2),
                          valueColor: _errorRed,
                          icon: Icons.trending_down_rounded,
                        ),
                        _buildKpiCard(
                          title: 'Costo de Mercadería',
                          amount: reporte.costoMercaderia,
                          iconColor: _warningAmber,
                          bgColor: const Color(0xFFFEF3C7),
                          valueColor: _textDark,
                          icon: Icons.inventory_2_outlined,
                        ),
                        _buildKpiCard(
                          title: 'Beneficio Neto',
                          amount: reporte.beneficioNeto,
                          iconColor: _infoBlue,
                          bgColor: const Color(0xFFEFF6FF),
                          valueColor: reporte.beneficioNeto >= 0
                              ? _successGreen
                              : _errorRed,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Sección "Productos Más Vendidos"
                    Text(
                      'Productos Más Vendidos',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (reporte.productosVendidos.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 32,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No hay productos vendidos en este periodo.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reporte.productosVendidos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final producto = reporte.productosVendidos[index];
                          final nombreCorregido =
                              _corregirNombre(producto.nombre);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _cardBorder, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Posición en ranking
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_primaryOrange, _secondaryRed],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Información del Producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombreCorregido,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${producto.cantidad} ${producto.cantidad == 1 ? "unidad" : "unidades"}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Total Recaudado
                                Text(
                                  CurrencyFormatter.format(producto.total),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _successGreen,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      // 5. Botón de Exportación (PDF Flotante / Inferior)
      floatingActionButton: SafeArea(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isFabPressed = true),
          onTapUp: (_) => setState(() => _isFabPressed = false),
          onTapCancel: () => setState(() => _isFabPressed = false),
          child: AnimatedScale(
            scale: _isFabPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryOrange, _secondaryRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryOrange.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _exportarPDF,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Exportar PDF',
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
      ),
    );
  }
}
