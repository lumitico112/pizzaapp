import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/waste/presentation/controllers/merma_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/screens/preparacion/widgets/gestion_sobrantes_modal.dart';

/// Formulario rediseñado para Registrar Merma bajo Material Design 3.
/// Incluye banner de advertencia moderno, selector segmentado de alta legibilidad,
/// campos con iconografía descriptiva, sufijo dinámico de unidades y
/// botón de acción con degradado cálido y microinteracción táctil.
class MermaFormScreen extends StatefulWidget {
  const MermaFormScreen({super.key});

  @override
  State<MermaFormScreen> createState() => _MermaFormScreenState();
}

class _MermaFormScreenState extends State<MermaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Paleta de colores corporativa
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  bool _esInsumo = true;
  int? _insumoSeleccionado;
  int? _varianteSeleccionada;

  String _tipoSeleccionado = 'dañado';
  final List<Map<String, String>> _tipos = [
    {'value': 'dañado', 'label': 'DAÑADO'},
    {'value': 'vencido', 'label': 'VENCIDO'},
    {'value': 'quemado', 'label': 'QUEMADO'},
    {'value': 'caída', 'label': 'CAÍDA'},
    {'value': 'otro', 'label': 'OTRO'},
  ];

  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
      context.read<PosController>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String? _obtenerUnidadActual(List<Insumo> insumos) {
    if (_esInsumo) {
      if (_insumoSeleccionado == null) return null;
      for (final i in insumos) {
        if (i.id == _insumoSeleccionado) {
          return i.unidadMedida;
        }
      }
      return null;
    } else {
      if (_varianteSeleccionada == null) return null;
      return 'Unid.';
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_esInsumo && _insumoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un insumo para reportar'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (!_esInsumo && _varianteSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un producto preparado para reportar'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final ctrl = context.read<MermaController>();

    // Mapeo defensivo para opciones que en SQLite son compatibles con CHECK(tipo IN ('quemado','vencido','dañado','otro'))
    final tipoDb = _tipoSeleccionado == 'caída' ? 'otro' : _tipoSeleccionado;
    String desc = _descCtrl.text.trim();
    if (_tipoSeleccionado == 'caída') {
      desc = desc.isEmpty ? 'Pérdida por caída' : '[Caída] $desc';
    }

    final res = await ctrl.registrarMerma(
      tipo: tipoDb,
      cantidadText: _cantidadCtrl.text.replaceAll(',', '.'),
      descripcion: desc.isEmpty ? null : desc,
      insumoId: _esInsumo ? _insumoSeleccionado : null,
      varianteId: !_esInsumo ? _varianteSeleccionada : null,
    );

    if (!mounted) return;
    if (res) {
      // Refrescar indicadores del Dashboard
      context.read<DashboardController>().refreshDashboard();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merma registrada y stock descontado exitosamente'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.error ?? 'Error al registrar merma'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required Widget prefixIcon,
    String? hintText,
    String? suffixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      suffixStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _secondaryRed,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _textMuted,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryOrange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insumoCtrl = context.watch<InsumoController>();
    final posCtrl = context.watch<PosController>();
    final mermaCtrl = context.watch<MermaController>();

    final unidadActual = _obtenerUnidadActual(insumoCtrl.insumos);
    final rawProducts = posCtrl.allPosItems.isNotEmpty
        ? posCtrl.allPosItems
        : posCtrl.posItems;
    final productosConStock = rawProducts
        .where(
          (p) =>
              p.variante.varianteBaseId == null &&
              (p.variante.stock > 0 ||
                  p.producto.tipoPreparacion.toLowerCase() != 'momento'),
        )
        .toList()
      ..sort((a, b) => b.variante.stock.compareTo(a.variante.stock));

    int? selectedProductStock;
    if (!_esInsumo && _varianteSeleccionada != null) {
      for (final p in productosConStock) {
        if (p.variante.id == _varianteSeleccionada) {
          selectedProductStock = p.variante.stock;
          break;
        }
      }
    }

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
          'Registrar Merma',
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
      body: (insumoCtrl.isLoading || posCtrl.isLoading)
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Banner de Advertencia Moderno
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Advertencia: Registrar una merma descontará automáticamente el stock.',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF991B1B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Selector Segmentado de Tipo de Merma
                    Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            title: 'Insumos Crudos',
                            icon: Icons.inventory_2_outlined,
                            isSelected: _esInsumo,
                            onTap: () {
                              if (!_esInsumo) {
                                setState(() {
                                  _esInsumo = true;
                                  _varianteSeleccionada = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSegmentButton(
                            title: 'Productos Preparados',
                            icon: Icons.local_pizza_outlined,
                            isSelected: !_esInsumo,
                            onTap: () {
                              if (_esInsumo) {
                                setState(() {
                                  _esInsumo = false;
                                  _insumoSeleccionado = null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (!_esInsumo) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: _secondaryRed,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '¿Quieres repartir stock entre "Para mañana" y "Merma"?',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _secondaryRed,
                                side: const BorderSide(color: _secondaryRed),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final ok = await GestionSobrantesModal.show(
                                  context,
                                  esCierreDeCiclo: false,
                                );
                                if (ok && context.mounted) {
                                  await context
                                      .read<PosController>()
                                      .loadInitialData();
                                  if (!context.mounted) return;
                                  context
                                      .read<DashboardController>()
                                      .refreshDashboard();
                                  Navigator.pop(context, true);
                                }
                              },
                              child: Text(
                                'Gestionar todos',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 3. Selector de Ítem Afectado con transición animada
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _esInsumo
                          ? DropdownButtonFormField<int>(
                              key: const ValueKey('dropdown_insumo'),
                              initialValue: _insumoSeleccionado,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                labelText: 'Insumo Afectado',
                                prefixIcon: const Icon(
                                  Icons.category_outlined,
                                  color: _secondaryRed,
                                  size: 22,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _textMuted,
                              ),
                              items: insumoCtrl.insumos.map((i) {
                                return DropdownMenuItem<int>(
                                  value: i.id,
                                  child: Text(
                                    '${i.nombre} (${i.unidadMedida} · Stock: ${i.stockActual.toStringAsFixed(i.stockActual % 1 == 0 ? 0 : 2)})',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _insumoSeleccionado = val);
                              },
                              validator: (val) {
                                if (_esInsumo && val == null) {
                                  return 'Selecciona un insumo';
                                }
                                return null;
                              },
                            )
                          : DropdownButtonFormField<int>(
                              key: const ValueKey('dropdown_producto'),
                              initialValue: _varianteSeleccionada,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                labelText: 'Producto Afectado',
                                prefixIcon: const Icon(
                                  Icons.local_pizza_outlined,
                                  color: _secondaryRed,
                                  size: 22,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _textMuted,
                              ),
                              items: productosConStock.map((p) {
                                return DropdownMenuItem<int>(
                                  value: p.variante.id,
                                  child: Text(
                                    '${p.producto.nombre} - ${p.variante.nombreVariante} (Stock: ${p.variante.stock} unid.)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: p.variante.stock > 0
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: p.variante.stock > 0
                                          ? _textDark
                                          : _textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _varianteSeleccionada = val);
                              },
                              validator: (val) {
                                if (!_esInsumo && val == null) {
                                  return 'Selecciona un producto preparado';
                                }
                                return null;
                              },
                            ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Fila de Motivo y Cantidad Perdida
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna Izquierda: Motivo
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _tipoSeleccionado,
                            isExpanded: true,
                            decoration: _buildInputDecoration(
                              labelText: 'Motivo',
                              prefixIcon: const Icon(
                                Icons.report_problem_outlined,
                                color: Color(0xFFEA580C),
                                size: 22,
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _textMuted,
                            ),
                            items: _tipos.map((t) {
                              return DropdownMenuItem<String>(
                                value: t['value'],
                                child: Text(
                                  t['label']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _tipoSeleccionado = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Columna Derecha: Cantidad Perdida
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                            decoration: _buildInputDecoration(
                              labelText: 'Cantidad Perdida',
                              suffixText: unidadActual,
                              prefixIcon: const Icon(
                                Icons.exposure_minus_1_rounded,
                                color: Color(0xFFDC2626),
                                size: 22,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              final numVal =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (numVal == null || numVal <= 0) {
                                return 'Inválido (>0)';
                              }
                              if (!_esInsumo && (numVal % 1 != 0)) {
                                return 'Entero (1, 2..)';
                              }
                              if (!_esInsumo && selectedProductStock != null) {
                                if (selectedProductStock <= 0) {
                                  return 'Sin stock (0)';
                                }
                                if (numVal.toInt() > selectedProductStock) {
                                  return 'Máx: $selectedProductStock unid.';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 5. Campo Descripción o Detalle (Opcional)
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _textDark,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Descripción (Opcional)',
                        hintText: 'Descripción o detalle (Opcional)',
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: Color(0xFF6B7280),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 6. Botón de Acción Principal ("REGISTRAR MERMA")
                    SafeArea(
                      top: false,
                      child: GestureDetector(
                        onTapDown: (_) =>
                            setState(() => _isButtonPressed = true),
                        onTapUp: (_) =>
                            setState(() => _isButtonPressed = false),
                        onTapCancel: () =>
                            setState(() => _isButtonPressed = false),
                        child: AnimatedScale(
                          scale: _isButtonPressed ? 0.98 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryOrange, _secondaryRed],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _primaryOrange.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: mermaCtrl.isLoading ? null : _guardar,
                                child: Center(
                                  child: mermaCtrl.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.delete_forever_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'REGISTRAR MERMA',
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Construye los botones del selector segmentado de alta visibilidad
  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_primaryOrange, _secondaryRed],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryOrange.withValues(alpha: 0.25),
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
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
