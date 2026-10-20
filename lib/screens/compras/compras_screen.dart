import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/purchases/domain/entities/compra_ocasional.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/compras_controller.dart';
import 'package:pizzaapp/models/compra.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';

import 'compra_form_screen.dart';
import 'compra_ocasional_form_screen.dart';
import 'por_pagar_screen.dart';
import 'widgets/nueva_compra_sheet.dart';

import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/por_pagar_controller.dart';

enum _FiltroCompras { hoy, semana, mes, historial }

typedef _HistorialCompra = ({
  String fecha,
  Compra? compra,
  CompraOcasional? ocasional,
});

/// Pantalla rediseñada de Compras y Gastos bajo Material Design 3.
/// Paleta cálida (#FF6A00, #D62828, #1F2937, #FBF9F5), filtros dobles estilizados,
/// barra de resumen con píldora verde menta y tarjetas enriquecidas de movimientos.
class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  // Paleta de colores de la marca
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _greenEmerald = Color(0xFF059669);
  static const Color _mintBg = Color(0xFFECFDF5);
  static const Color _mintBorder = Color(0xFFA7F3D0);
  static const Color _infoBlue = Color(0xFF2563EB);
  static const Color _infoBg = Color(0xFFEFF6FF);
  static const Color _infoBorder = Color(0xFFBFDBFE);

  _FiltroCompras _filtro = _FiltroCompras.hoy;
  bool _mostrarGastos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComprasController>().loadHistorial();
    });
  }

  bool _fechaEnPeriodo(String fechaStr) {
    final hoy = AppDateUtils.todayStart;
    final semana = AppDateUtils.weekStart;
    final mes = AppDateUtils.monthStart;
    final fecha = DateTime.tryParse(fechaStr) ?? DateTime(2000);
    return switch (_filtro) {
      _FiltroCompras.hoy => !fecha.isBefore(hoy),
      _FiltroCompras.semana => !fecha.isBefore(semana),
      _FiltroCompras.mes => !fecha.isBefore(mes),
      _FiltroCompras.historial => true,
    };
  }

  List<Compra> _filtrarCompras(List<Compra> todas) {
    return todas.where((c) => _fechaEnPeriodo(c.fecha)).toList();
  }

  List<CompraOcasional> _filtrarOcasionales(List<CompraOcasional> todas) {
    return todas.where((c) => _fechaEnPeriodo(c.fecha)).toList();
  }

  List<Map<String, dynamic>> _filtrarGastos(List<Map<String, dynamic>> todos) {
    return todos
        .where((gasto) => _fechaEnPeriodo(gasto['fecha'] as String? ?? ''))
        .toList();
  }

  List<_HistorialCompra> _combinarHistorial(
    List<Compra> compras,
    List<CompraOcasional> ocasionales,
  ) {
    final items = <_HistorialCompra>[
      for (final compra in compras)
        (fecha: compra.fecha, compra: compra, ocasional: null),
      for (final ocasional in ocasionales)
        (fecha: ocasional.fecha, compra: null, ocasional: ocasional),
    ];
    items.sort((a, b) => b.fecha.compareTo(a.fecha));
    return items;
  }

  String _resumenCompras(int insumos, int ocasionales) {
    if (ocasionales == 0) return '$insumos compra(s)';
    if (insumos == 0) return '$ocasionales ocasional(es)';
    return '$insumos insumo(s) · $ocasionales ocasional(es)';
  }

  String _cantidadOcasional(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> _refrescarModulos({bool recargarCompras = true}) async {
    if (recargarCompras) {
      await context.read<ComprasController>().loadHistorial();
    }
    if (!mounted) return;
    context.read<InsumoController>().loadInsumos();
    context.read<CajaController>().loadDatosCaja();
    context.read<DashboardController>().refreshDashboard();
    context.read<PorPagarController>().loadCuentas();
  }

  void _mostrarSnack(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: error ? const Color(0xFFDC2626) : _greenEmerald,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _abrirNuevaCompra() async {
    final tipo = await showNuevaCompraSheet(context);
    if (!mounted || tipo == null) return false;

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => tipo == TipoNuevaCompra.ocasional
            ? const CompraOcasionalFormScreen()
            : const CompraFormScreen(),
      ),
    );

    if (ok == true && mounted) {
      await _refrescarModulos();
      _mostrarSnack(
        tipo == TipoNuevaCompra.ocasional
            ? 'Compra ocasional registrada.'
            : 'Compra registrada y stock actualizado.',
      );
      return true;
    }
    return false;
  }

  String _formatFecha(String fechaStr) {
    final dt = DateTime.tryParse(fechaStr);
    if (dt == null) return fechaStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildGastoCard(Map<String, dynamic> gasto) {
    final activo = gasto['activo_fijo_nombre'] as String?;
    final categoria = gasto['categoria'] as String? ?? 'Gasto';
    final descripcion = gasto['descripcion'] as String?;
    final fecha = gasto['fecha'] as String? ?? '';
    final monto = (gasto['monto'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: _textDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono descriptivo a la izquierda
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _secondaryRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Centro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activo == null ? categoria : 'Activo fijo · $activo',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (descripcion != null && descripcion.isNotEmpty)
                      descripcion,
                    categoria,
                    _formatFecha(fecha),
                  ].join(' · '),
                  style: GoogleFonts.poppins(fontSize: 12, color: _textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Derecha: Monto y Eliminar
          Text(
            'S/ ${monto.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _secondaryRed,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: descripcion != null && descripcion.isNotEmpty
                ? 'Eliminar gasto: $descripcion'
                : 'Eliminar gasto registrado',
            onTap: () => _confirmarEliminarGasto(gasto),
            child: ExcludeSemantics(
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Material(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _confirmarEliminarGasto(gasto),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Center(
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                        ),
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

  Widget _buildFiltrosPeriodo() {
    const labels = {
      _FiltroCompras.hoy: 'Hoy',
      _FiltroCompras.semana: 'Esta semana',
      _FiltroCompras.mes: 'Este mes',
      _FiltroCompras.historial: 'Historial',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: _FiltroCompras.values.map((f) {
          final isSelected = f == _filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _filtro = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFEBE3) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _secondaryRed : _cardBorder,
                    width: isSelected ? 1.2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[f]!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? _secondaryRed : _textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSegmentedCategorySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _mostrarGastos = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: !_mostrarGastos ? _greenEmerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: !_mostrarGastos
                        ? [
                            BoxShadow(
                              color: _greenEmerald.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: !_mostrarGastos ? Colors.white : _textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Compras',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_mostrarGastos ? Colors.white : _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _mostrarGastos = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _mostrarGastos ? _secondaryRed : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: _mostrarGastos
                        ? [
                            BoxShadow(
                              color: _secondaryRed.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        size: 18,
                        color: _mostrarGastos ? Colors.white : _textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Gastos',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _mostrarGastos ? Colors.white : _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompraCard(Compra c) {
    final costoTotal = c.cantidad * c.costoUnitario;
    final esPorPagar =
        c.motivo.toLowerCase().contains('por pagar') ||
        c.motivo.toLowerCase().contains('adelanto') ||
        (c.esPorPagar == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: _textDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Izquierda: Contenedor 44x44
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: esPorPagar ? const Color(0xFFFFFBEB) : _mintBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              esPorPagar
                  ? Icons.schedule_outlined
                  : Icons.check_circle_outline_rounded,
              color: esPorPagar
                  ? const Color(0xFFD97706)
                  : const Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Centro: Insumo y datos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.insumoNombre,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${c.cantidad.toStringAsFixed(2)} ${c.unidadMedida} · ${_formatFecha(c.fecha)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (c.proveedor != null && c.proveedor!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Proveedor: ${c.proveedor}',
                    style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (c.motivo.isNotEmpty &&
                    !c.motivo.toLowerCase().contains('compra de')) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Nota: ${c.motivo}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF2563EB),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Derecha: Monto y Botón Editar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'S/ ${costoTotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _greenEmerald,
                ),
              ),
              if (esPorPagar) ...[
                const SizedBox(height: 2),
                Text(
                  'Por pagar',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompraFormScreen(compra: c),
                  ),
                );
                if (updated == true && mounted) {
                  context.read<ComprasController>().loadHistorial();
                  context.read<InsumoController>().loadInsumos();
                  context.read<CajaController>().loadDatosCaja();
                  context.read<DashboardController>().refreshDashboard();
                  context.read<PorPagarController>().loadCuentas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Compra corregida y sincronizada',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: _greenEmerald,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _confirmarEliminarCompra(c),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompraOcasionalCard(CompraOcasional c) {
    final categoria = c.categoria.trim().isEmpty ? 'Otros' : c.categoria;
    final unidad = c.unidadMedida?.trim();
    final detalleCantidad = [
      _cantidadOcasional(c.cantidad),
      if (unidad != null && unidad.isNotEmpty) unidad,
      _formatFecha(c.fecha),
    ].join(' · ');
    final proveedor = c.proveedor?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _infoBorder.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: _infoBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _infoBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _infoBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.descripcion,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _infoBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _infoBorder),
                      ),
                      child: Text(
                        'COMPRA OCASIONAL',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: _infoBlue,
                        ),
                      ),
                    ),
                    Text(
                      categoria,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  detalleCantidad,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (proveedor != null && proveedor.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Proveedor: $proveedor',
                    style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${c.costoTotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _infoBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c.esPorPagar ? 'Por pagar' : 'Contado',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: c.esPorPagar ? const Color(0xFFD97706) : _greenEmerald,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: 'Editar compra ocasional: ${c.descripcion}',
                    child: Material(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _editarCompraOcasional(c),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    button: true,
                    label: 'Eliminar compra ocasional: ${c.descripcion}',
                    child: Material(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _confirmarEliminarCompraOcasional(c),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFDC2626),
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
        ],
      ),
    );
  }

  Future<void> _editarCompraOcasional(CompraOcasional c) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CompraOcasionalFormScreen(compra: c)),
    );
    if (updated == true && mounted) {
      await _refrescarModulos();
      _mostrarSnack('Compra ocasional actualizada.');
    }
  }

  Future<void> _confirmarEliminarCompraOcasional(CompraOcasional c) async {
    final compraId = c.id;
    if (compraId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eliminar compra ocasional',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas eliminar "${c.descripcion}" por '
              'S/ ${c.costoTotal.toStringAsFixed(2)}?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _infoBorder),
              ),
              child: Text(
                'Esta compra no modificó el inventario. Se eliminarán el '
                'gasto, los movimientos de caja y la cuenta por pagar '
                'vinculados.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: _infoBlue,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sí, eliminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final controller = context.read<ComprasController>();
    final ok = await controller.eliminarCompraOcasional(compraId);
    if (!mounted) return;
    if (!ok) {
      _mostrarSnack(
        controller.error ?? 'No se pudo eliminar la compra ocasional.',
        error: true,
      );
      return;
    }

    await _refrescarModulos(recargarCompras: false);
    _mostrarSnack('Compra ocasional eliminada. El stock no cambió.');
  }

  Future<void> _confirmarEliminarCompra(Compra c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eliminar compra',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar la compra de ${c.insumoNombre}?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esta acción realizará:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Reversión de stock: -${c.cantidad.toStringAsFixed(2)} ${c.unidadMedida}\n'
                    '• Anulación de egresos de caja y gastos vinculados\n'
                    '• Eliminación de cuentas por pagar asociadas',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF7C2D12),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sí, eliminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await context.read<ComprasController>().eliminarCompra(c.id);
      if (!mounted) return;
      context.read<InsumoController>().loadInsumos();
      context.read<CajaController>().loadDatosCaja();
      context.read<DashboardController>().refreshDashboard();
      context.read<PorPagarController>().loadCuentas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compra eliminada y stock revertido',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _confirmarEliminarGasto(Map<String, dynamic> gasto) async {
    final gastoId = gasto['id'] as int?;
    if (gastoId == null) return;
    final descripcion = gasto['descripcion'] as String? ?? 'Gasto';
    final monto = (gasto['monto'] as num?)?.toDouble() ?? 0;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eliminar gasto',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas eliminar este registro de gasto de S/ ${monto.toStringAsFixed(2)}?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descripcion,
              style: GoogleFonts.poppins(fontSize: 12, color: _textMuted),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Text(
                'Si este gasto proviene de una compra de insumos, se revertirá también el stock y los movimientos de caja asociados.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF7C2D12),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sí, eliminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await context.read<ComprasController>().eliminarGasto(gastoId);
      if (!mounted) return;
      context.read<InsumoController>().loadInsumos();
      context.read<CajaController>().loadDatosCaja();
      context.read<DashboardController>().refreshDashboard();
      context.read<PorPagarController>().loadCuentas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gasto eliminado y conciliado',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar gasto: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComprasController>(
      builder: (context, ctrl, _) {
        final comprasFiltradas = _filtrarCompras(ctrl.historial);
        final ocasionalesFiltradas = _filtrarOcasionales(
          ctrl.comprasOcasionales,
        );
        final totalInsumos = comprasFiltradas.fold(
          0.0,
          (sum, c) => sum + (c.cantidad * c.costoUnitario),
        );
        final totalOcasionales = ocasionalesFiltradas.fold(
          0.0,
          (sum, c) => sum + c.costoTotal,
        );
        final historialCompras = _combinarHistorial(
          comprasFiltradas,
          ocasionalesFiltradas,
        );
        final gastosFiltrados = _filtrarGastos(ctrl.gastos);
        final totalGastosFiltrado = gastosFiltrados.fold<double>(
          0,
          (sum, gasto) => sum + ((gasto['monto'] as num?)?.toDouble() ?? 0),
        );

        final cantidadItems = _mostrarGastos
            ? '${gastosFiltrados.length} gasto(s)'
            : _resumenCompras(
                comprasFiltradas.length,
                ocasionalesFiltradas.length,
              );
        final totalMontoStr = _mostrarGastos
            ? 'Total: S/ ${totalGastosFiltrado.toStringAsFixed(2)}'
            : 'Total: S/ ${(totalInsumos + totalOcasionales).toStringAsFixed(2)}';

        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            leading: Center(
              child: Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Compras y gastos',
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Cuentas por pagar',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PorPagarScreen()),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Actualizar',
                    onPressed: ctrl.loadHistorial,
                  ),
                ),
              ),
            ],
          ),
          body: ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
                  ),
                )
              : Column(
                  children: [
                    // Filtros de periodo
                    _buildFiltrosPeriodo(),
                    const SizedBox(height: 6),

                    // Selector Compras vs Gastos
                    _buildSegmentedCategorySelector(),
                    const SizedBox(height: 8),

                    // Barra de resumen
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: Text(
                              cantidadItems,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _textMuted,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _mintBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _mintBorder),
                            ),
                            child: Text(
                              totalMontoStr,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _mostrarGastos
                                    ? _secondaryRed
                                    : _greenEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Listado de compras o gastos
                    Expanded(
                      child: _mostrarGastos
                          ? gastosFiltrados.isEmpty
                                ? _buildEmptyState(
                                    message: 'No hay gastos en este período',
                                    icon: Icons.receipt_long_outlined,
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      4,
                                      18,
                                      88,
                                    ),
                                    itemCount: gastosFiltrados.length,
                                    itemBuilder: (_, i) =>
                                        _buildGastoCard(gastosFiltrados[i]),
                                  )
                          : historialCompras.isEmpty
                          ? _buildEmptyState(
                              message: 'No hay compras en este período',
                              icon: Icons.shopping_bag_outlined,
                              buttonLabel: 'Registrar Compra',
                              onAction: _abrirNuevaCompra,
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 88),
                              itemCount: historialCompras.length,
                              itemBuilder: (_, i) {
                                final item = historialCompras[i];
                                final ocasional = item.ocasional;
                                if (ocasional != null) {
                                  return _buildCompraOcasionalCard(ocasional);
                                }
                                return _buildCompraCard(item.compra!);
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: _mostrarGastos
              ? null
              : Container(
                  margin: const EdgeInsets.only(bottom: 6, right: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryOrange, _secondaryRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _secondaryRed.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _abrirNuevaCompra,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nueva Compra',
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
      },
    );
  }

  Widget _buildEmptyState({
    required String message,
    required IconData icon,
    String? buttonLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1ED),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryOrange.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 38, color: _secondaryRed),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  buttonLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
