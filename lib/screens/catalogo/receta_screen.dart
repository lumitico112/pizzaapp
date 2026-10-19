import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/receta.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/receta_controller.dart';

/// Metadatos visuales y categoría contextual para cada insumo
class _InsumoVisualMeta {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String categoryName;

  const _InsumoVisualMeta({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.categoryName,
  });
}

/// Pantalla rediseñada de Ficha Técnica / Receta de Producto bajo Material Design 3,
/// paleta cálida (naranja #FF6A00, rojo #D62828, crema #FBF9F5),
/// selector moderno de variante de 52px, desglose modular de ingredientes con
/// iconografía descriptiva por categoría, badges de cantidad y FAB animado con degradado.
class RecetaScreen extends StatefulWidget {
  final Producto producto;
  const RecetaScreen({super.key, required this.producto});

  @override
  State<RecetaScreen> createState() => _RecetaScreenState();
}

class _RecetaScreenState extends State<RecetaScreen> {
  // Constantes de estilo y paleta Kimi Pizza
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textPlaceholder = Color(0xFF9CA3AF);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  VarianteProducto? _varianteSeleccionada;
  List<VarianteProducto> _variantes = [];
  List<RecetaItem> _recetaHeredada = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
      _loadVariantes();
    });
  }

  Future<void> _loadVariantes() async {
    final vars = await context.read<ProductoController>().obtenerVariantes(
          widget.producto.id!,
        );
    if (vars.isNotEmpty && mounted) {
      setState(() => _variantes = vars);
      await _seleccionarVariante(vars.first);
    }
  }

  Future<void> _seleccionarVariante(VarianteProducto variant) async {
    setState(() {
      _varianteSeleccionada = variant;
      _recetaHeredada = [];
    });
    final controller = context.read<RecetaController>();
    if (variant.varianteBaseId != null) {
      await controller.loadReceta(variant.varianteBaseId!);
      if (!mounted) return;
      _recetaHeredada = List<RecetaItem>.from(controller.recetaActual);
    }
    await controller.loadReceta(variant.id!);
    if (mounted) setState(() {});
  }

  /// Retorna icono descriptivo, color y nombre de categoría para el insumo
  _InsumoVisualMeta _getInsumoMeta(String nombre) {
    final n = nombre.toLowerCase().trim();

    // Masa / Harina (Fondo amarillo/ocre pastel)
    if (n.contains('harina') ||
        n.contains('masa') ||
        n.contains('premezcla') ||
        n.contains('levadura')) {
      return const _InsumoVisualMeta(
        icon: Icons.bakery_dining_outlined,
        iconColor: Color(0xFFD97706),
        bgColor: Color(0xFFFEF3C7),
        categoryName: 'Masas y Harinas',
      );
    }

    // Salsa de tomate (Fondo rojo/rosa pastel)
    if (n.contains('salsa') ||
        n.contains('tomate') ||
        n.contains('pasta de tomate') ||
        n.contains('ketchup')) {
      return const _InsumoVisualMeta(
        icon: Icons.soup_kitchen_outlined,
        iconColor: Color(0xFFDC2626),
        bgColor: Color(0xFFFEE2E2),
        categoryName: 'Salsas',
      );
    }

    // Queso Mozzarella / Lácteos (Fondo amarillo pastel)
    if (n.contains('queso') ||
        n.contains('mozzarella') ||
        n.contains('parmesano') ||
        n.contains('lacteo') ||
        n.contains('leche')) {
      return const _InsumoVisualMeta(
        icon: Icons.widgets_outlined,
        iconColor: Color(0xFFCA8A04),
        bgColor: Color(0xFFFEF9C3),
        categoryName: 'Lácteos',
      );
    }

    // Jamón / Carnes / Embutidos (Fondo rosa/rojo pastel)
    if (n.contains('jamon') ||
        n.contains('jamón') ||
        n.contains('carne') ||
        n.contains('pollo') ||
        n.contains('tocino') ||
        n.contains('pepperoni') ||
        n.contains('chorizo') ||
        n.contains('salchicha')) {
      return const _InsumoVisualMeta(
        icon: Icons.restaurant_menu_outlined,
        iconColor: Color(0xFFE11D48),
        bgColor: Color(0xFFFFE4E6),
        categoryName: 'Carnes y Embutidos',
      );
    }

    // Orégano / Especias / Condimentos (Fondo verde pastel)
    if (n.contains('oregano') ||
        n.contains('orégano') ||
        n.contains('albahaca') ||
        n.contains('pimienta') ||
        n.contains('sal') ||
        n.contains('especi') ||
        n.contains('aceite')) {
      return const _InsumoVisualMeta(
        icon: Icons.eco_outlined,
        iconColor: Color(0xFF16A34A),
        bgColor: Color(0xFFDCFCE7),
        categoryName: 'Especias y Condimentos',
      );
    }

    // Vegetales / Champiñones / Piña
    if (n.contains('champi') ||
        n.contains('piña') ||
        n.contains('aceituna') ||
        n.contains('cebolla') ||
        n.contains('pimiento')) {
      return const _InsumoVisualMeta(
        icon: Icons.local_florist_outlined,
        iconColor: Color(0xFF059669),
        bgColor: Color(0xFFD1FAE5),
        categoryName: 'Vegetales y Frutas',
      );
    }

    // Caja de entrega / Empaque (Fondo crema/marrón pastel)
    if (n.contains('caja') ||
        n.contains('bolsa') ||
        n.contains('empaque') ||
        n.contains('vaso') ||
        n.contains('servilleta')) {
      return const _InsumoVisualMeta(
        icon: Icons.inventory_2_outlined,
        iconColor: Color(0xFFEA580C),
        bgColor: Color(0xFFFFEDD5),
        categoryName: 'Empaque y Presentación',
      );
    }

    // Fallback general
    return const _InsumoVisualMeta(
      icon: Icons.lunch_dining_outlined,
      iconColor: Color(0xFFFF6A00),
      bgColor: Color(0xFFFFF7ED),
      categoryName: 'Ingrediente General',
    );
  }

  void _abrirModalAdd({RecetaItem? itemAEditar}) {
    if (_varianteSeleccionada == null) return;

    final insumos = context
        .read<InsumoController>()
        .insumos
        .where((i) => i.activo == 1)
        .toList();

    int? insumoSelec = itemAEditar?.insumoId;
    String? unidadReceta = itemAEditar?.unidadMedida;
    final cantidadCtrl = TextEditingController(
      text: itemAEditar != null ? itemAEditar.cantidad.toString() : '',
    );

    if (insumoSelec != null && unidadReceta == null) {
      final insumo = insumos.firstWhere((i) => i.id == insumoSelec);
      unidadReceta = _unidadesReceta(insumo.unidadMedida).first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBE3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.soup_kitchen_outlined,
                    color: _accentOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    itemAEditar == null
                        ? 'Agregar Insumo'
                        : 'Modificar Insumo',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insumo / Ingrediente',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: insumoSelec,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Selecciona un insumo...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _textPlaceholder,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _accentOrange,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _accentOrange),
                      ),
                    ),
                    items: insumos
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.id,
                            child: Text(
                              '${i.nombre} (${i.unidadMedida})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: itemAEditar != null
                        ? null // Si edita, no cambia el insumo, solo la cantidad/unidad
                        : (val) => setDialogState(() {
                              insumoSelec = val;
                              final unit = insumos
                                  .firstWhere((i) => i.id == val)
                                  .unidadMedida;
                              unidadReceta = _unidadesReceta(unit).first;
                            }),
                  ),
                  const SizedBox(height: 14),
                  if (insumoSelec != null) ...[
                    Text(
                      'Unidad para la Receta',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey(insumoSelec),
                      initialValue: unidadReceta,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _accentOrange),
                        ),
                      ),
                      items: _unidadesReceta(
                        insumos
                            .firstWhere((i) => i.id == insumoSelec)
                            .unidadMedida,
                      )
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => unidadReceta = value),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    'Cantidad Requerida',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: cantidadCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej: 150',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _textPlaceholder,
                      ),
                      suffixText: unidadReceta ?? '',
                      suffixStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _accentOrange,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _accentOrange),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (insumoSelec == null ||
                      cantidadCtrl.text.trim().isEmpty ||
                      unidadReceta == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Selecciona el insumo e ingresa una cantidad mayor a 0.',
                        ),
                        backgroundColor: _primaryRed,
                      ),
                    );
                    return;
                  }
                  final recetaController = context.read<RecetaController>();
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  final success = await recetaController.agregarInsumo(
                    varianteId: _varianteSeleccionada!.id!,
                    insumoId: insumoSelec!,
                    cantidadText: cantidadCtrl.text.trim().replaceAll(',', '.'),
                    unidadMedida: unidadReceta!,
                  );
                  if (success && ctx.mounted) {
                    nav.pop();
                  } else if (!success && mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          recetaController.error ??
                              'No se pudo guardar el insumo en la receta.',
                        ),
                        backgroundColor: _primaryRed,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentOrange,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  itemAEditar == null ? 'Agregar Insumo' : 'Actualizar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> _unidadesReceta(String unidadStock) {
    switch (unidadStock.toLowerCase()) {
      case 'kg':
      case 'kilogramos':
        return ['gr', 'Kg'];
      case 'gr':
      case 'g':
        return ['gr', 'Kg'];
      case 'litros':
      case 'l':
        return ['ml', 'Litros'];
      case 'ml':
        return ['ml', 'Litros'];
      case 'paquetes':
        return ['Unidades', 'Paquetes'];
      default:
        return ['Unidades'];
    }
  }

  String _formatearCantidad(double cantidad, String unidad) {
    final formatted = cantidad % 1 == 0
        ? cantidad.toInt().toString()
        : cantidad.toStringAsFixed(2);
    return '$formatted $unidad';
  }

  /// Tarjeta moderna para cada ingrediente / insumo de la receta (56px a 64px)
  Widget _buildIngredienteCard({
    required RecetaItem item,
    required bool esHeredado,
    required VoidCallback? onDelete,
    required VoidCallback? onEdit,
  }) {
    final meta = _getInsumoMeta(item.insumoNombre ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: esHeredado ? null : onEdit,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 1. Icono / Ilustración Visual (Izquierda): 36px × 36px, radio 10px
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: meta.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      meta.icon,
                      color: meta.iconColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Texto e Identificación (Centro)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.insumoNombre ?? 'Insumo',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (esHeredado) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link_rounded,
                                    size: 10,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Base',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta.categoryName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Cantidad Requerida (Derecha): Píldora suave
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: esHeredado
                        ? const Color(0xFFF3F4F6)
                        : const Color(0xFFFFF1ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatearCantidad(item.cantidad, item.unidadMedida),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: esHeredado ? _textDark : _accentOrange,
                    ),
                  ),
                ),

                // Acciones rápidas (si es propio de esta variante)
                if (!esHeredado && onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    splashRadius: 18,
                    onPressed: onDelete,
                    tooltip: 'Eliminar ingrediente',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recetaCtrl = context.watch<RecetaController>();

    final totalItems =
        _recetaHeredada.length + recetaCtrl.recetaActual.length;

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _bgScreen,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _textDark,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Volver',
        ),
        title: Text(
          'Receta: ${widget.producto.nombre}',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // 3. SELECTOR DE VARIANTE (SECCIÓN SUPERIOR)
            // ----------------------------------------------------
            if (_variantes.isNotEmpty) ...[
              Text(
                'Variante',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _varianteSeleccionada?.id,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: Colors.white,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textPlaceholder,
                        size: 22,
                      ),
                    ),
                    items: _variantes
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_pizza_outlined,
                                    color: _accentOrange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    v.nombreVariante,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                    ),
                                  ),
                                  if (v.precioVenta > 0) ...[
                                    const Spacer(),
                                    Text(
                                      'S/ ${v.precioVenta.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      _seleccionarVariante(
                        _variantes.firstWhere((v) => v.id == id),
                      );
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ----------------------------------------------------
            // 4. DESGLOSE DE INSUMOS / INGREDIENTES
            // ----------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Insumos e Ingredientes',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($totalItems requeridos)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
                const Spacer(),
                if (recetaCtrl.costoTotalEstimado > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      'Costo: S/ ${recetaCtrl.costoTotalEstimado.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Contenido dinámico con desvanecimiento de datos al cambiar variante
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: recetaCtrl.isLoading
                  ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_accentOrange),
                        ),
                      ),
                    )
                  : totalItems == 0
                      ? Container(
                          key: const ValueKey('empty'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBE3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.soup_kitchen_outlined,
                                    size: 38,
                                    color: _accentOrange,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Sin insumos en la receta',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Agrega los ingredientes necesarios para esta porción para calcular costos y descontar inventario en cada venta.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _textMuted,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: _abrirModalAdd,
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: Text(
                                    'Agregar primer insumo',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentOrange,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          key: ValueKey('list_${_varianteSeleccionada?.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Receta heredada del producto base (si aplica)
                            if (_recetaHeredada.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFBAE6FD),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFF0284C7),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Receta base heredada (solo lectura, stock compartido).',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF0369A1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ..._recetaHeredada.map(
                                (item) => _buildIngredienteCard(
                                  item: item,
                                  esHeredado: true,
                                  onDelete: null,
                                  onEdit: null,
                                ),
                              ),
                              if (recetaCtrl.recetaActual.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Ingredientes Adicionales de esta Variante',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],

                            // Insumos propios de esta variante
                            ...recetaCtrl.recetaActual.map(
                              (item) => _buildIngredienteCard(
                                item: item,
                                esHeredado: false,
                                onDelete: () => recetaCtrl.eliminarInsumo(
                                  _varianteSeleccionada!.id!,
                                  item.id!,
                                ),
                                onEdit: () => _abrirModalAdd(itemAEditar: item),
                              ),
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 80), // Margen para el FAB inferior
          ],
        ),
      ),

      // ----------------------------------------------------
      // 5. BOTÓN FLOTANTE DE ACCIÓN (FAB ANIMADO)
      // ----------------------------------------------------
      floatingActionButton: _AnimatedFab(
        onPressed: _abrirModalAdd,
      ),
    );
  }
}

/// Botón Flotante (FAB) animado de 56x56 con degradado, sombra difusa y rotación sutil al pulsar
class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedFab({required this.onPressed});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.elasticOut,
    );
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedRotation(
            turns: _isPressed ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFD62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
