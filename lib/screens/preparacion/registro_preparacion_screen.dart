import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/preparation/presentation/controllers/preparacion_controller.dart';
import 'package:pizzaapp/features/waste/presentation/controllers/merma_controller.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/models/preparacion.dart';
import 'package:pizzaapp/app/app_router.dart';
import 'package:pizzaapp/screens/preparacion/widgets/gestion_sobrantes_modal.dart';

// Paleta de colores corporativa Material 3
const Color _primaryOrange = Color(0xFFFF6A00);
const Color _secondaryRed = Color(0xFFD62828);
const Color _accentOrange = Color(0xFFEA580C);
const Color _successDark = Color(0xFF059669);
const Color _textDark = Color(0xFF1F2937);
const Color _textMuted = Color(0xFF6B7280);
const Color _bgScreen = Color(0xFFFBF9F5);
const Color _cardBorder = Color(0xFFE5E7EB);

class RegistroPreparacionScreen extends StatefulWidget {
  final Map<int, int>? prefilledData;
  const RegistroPreparacionScreen({super.key, this.prefilledData});

  @override
  State<RegistroPreparacionScreen> createState() =>
      _RegistroPreparacionScreenState();
}

class _RegistroPreparacionScreenState extends State<RegistroPreparacionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notaGlobalCtrl = TextEditingController();
  final Map<int, TextEditingController> _cantidadesCtrls = {};
  final Map<int, TextEditingController> _notasCtrls = {};
  final Map<int, String> _nombresVariantes = {};
  final Map<int, int> _stockVariantes = {};
  final Set<int> _variantesDerivadas = {};
  final Map<int, int> _sobrantesAPreparacion = {};
  final Map<int, int> _sobrantesAMerma = {};
  final Map<int, int> _unidadesTrasladadas = {};
  bool _editaPreparacionHoy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool mostrarModalSobrantes = true}) async {
    final controller = context.read<PreparacionController>();
    if (!await controller.hayCajaActiva()) {
      if (!mounted) return;
      final irACaja = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Abre la caja primero',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _textDark,
            ),
          ),
          content: Text(
            'Necesitas una sesión de caja abierta antes de registrar la preparación del día.',
            style: GoogleFonts.poppins(fontSize: 13.5, color: _textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Volver',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _secondaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Ir a caja',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (irACaja == true) {
        await AppRouter.push<Object?>(context, AppRoutes.caja);
      }
      if (!mounted) return;
      final active = await controller.hayCajaActiva();
      if (!mounted) return;
      if (!active) {
        Navigator.maybePop(context);
        return;
      }
    }

    await controller.loadHistorial();
    await controller.loadProductosParaPreparacion();

    for (final ctrl in _cantidadesCtrls.values) {
      ctrl.dispose();
    }
    for (final ctrl in _notasCtrls.values) {
      ctrl.dispose();
    }
    _cantidadesCtrls.clear();
    _notasCtrls.clear();
    _nombresVariantes.clear();
    _stockVariantes.clear();
    _variantesDerivadas.clear();

    for (var prod in controller.productosPreHechos) {
      final vars = await controller.obtenerVariantesPorProducto(prod.id!);
      for (var v in vars) {
        final initialStock = v.varianteBaseId == null ? v.stock : 0;
        _cantidadesCtrls[v.id!] = TextEditingController(
          text: (widget.prefilledData?[v.id!] ?? initialStock).toString(),
        );
        _notasCtrls[v.id!] = TextEditingController();
        _nombresVariantes[v.id!] = '${prod.nombre} - ${v.nombreVariante}';
        _stockVariantes[v.id!] = v.stock;
        if (v.varianteBaseId != null) _variantesDerivadas.add(v.id!);
        if (v.varianteBaseId == null && initialStock > 0) {
          _unidadesTrasladadas[v.id!] = initialStock;
        }
      }
    }
    final today = controller.preparacionHoy;
    if (today != null) {
      _editaPreparacionHoy = true;
      _notaGlobalCtrl.text = today['nota']?.toString() ?? '';
      for (final item in (today['items'] as List<dynamic>? ?? const [])) {
        final row = Map<String, dynamic>.from(item as Map);
        final variantId = row['variante_id'] as int;
        if (_cantidadesCtrls.containsKey(variantId)) {
          _cantidadesCtrls[variantId]!.text =
              '${row['cantidad_preparada'] ?? 0}';
          _notasCtrls[variantId]!.text = row['notas']?.toString() ?? '';
        }
      }
    } else {
      _editaPreparacionHoy = false;
    }
    if (mounted) setState(() {});
    if (mostrarModalSobrantes) {
      await _mostrarSobrantesDelDiaAnterior(controller);
    }
  }

  Future<void> _mostrarSobrantesDelDiaAnterior(
    PreparacionController controller,
  ) async {
    if (!mounted) return;
    final changed = await GestionSobrantesModal.show(
      context,
      esCierreDeCiclo: false,
      soloNoResueltos: true,
    );
    if (changed && mounted) {
      await _loadData(mostrarModalSobrantes: false);
    }
  }

  Future<void> _abrirGestorSobrantesManual() async {
    if (!mounted) return;
    final changed = await GestionSobrantesModal.show(
      context,
      esCierreDeCiclo: false,
      soloNoResueltos: false,
    );
    if (changed && mounted) {
      await _loadData(mostrarModalSobrantes: false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notaGlobalCtrl.dispose();
    for (var ctrl in _cantidadesCtrls.values) {
      ctrl.dispose();
    }
    for (var ctrl in _notasCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _guardarPreparacion() async {
    final List<Map<String, dynamic>> seleccion = [];

    _cantidadesCtrls.forEach((vid, ctrl) {
      int val = int.tryParse(ctrl.text) ?? 0;
      seleccion.add({
        'varianteId': vid,
        'cantidad': val,
        'notas': _notasCtrls[vid]!.text.trim().isNotEmpty
            ? _notasCtrls[vid]!.text.trim()
            : null,
      });
    });

    if (_editaPreparacionHoy) {
      final stored = <int, int>{};
      for (final raw
          in (context.read<PreparacionController>().preparacionHoy?['items']
                  as List<dynamic>? ??
              const [])) {
        final row = Map<String, dynamic>.from(raw as Map);
        stored[row['variante_id'] as int] =
            (row['cantidad_preparada'] as num?)?.toInt() ?? 0;
      }
      final hasReduction = seleccion.any((item) {
        final current = (item['cantidad'] as num).toInt();
        final previous = stored[item['varianteId']] ?? 0;
        return previous > 0 && current >= 0 && current < previous;
      });
      if (hasReduction) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Confirmar corrección',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: _textDark,
              ),
            ),
            content: Text(
              'La cantidad corregida reducirá el stock y devolverá al inventario los insumos que se descontaron por error. Esto supone que esas unidades adicionales no se llegaron a preparar. Si sí se prepararon, cancela y regístralas como merma.',
              style: GoogleFonts.poppins(fontSize: 13, color: _textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _secondaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'Corregir',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
    }

    if (seleccion.every((item) => item['cantidad'] == 0) &&
        !_editaPreparacionHoy &&
        _sobrantesAPreparacion.isEmpty &&
        _sobrantesAMerma.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cantidades registradas')),
      );
      return;
    }

    final success = await context
        .read<PreparacionController>()
        .registrarPreparacion(
          nota: _notaGlobalCtrl.text.trim(),
          seleccion: seleccion,
          sobrantesAPreparacion: Map<int, int>.from(_sobrantesAPreparacion),
          sobrantesAMerma: Map<int, int>.from(_sobrantesAMerma),
          trasladadosPorVariante: Map<int, int>.from(_unidadesTrasladadas),
        );

    if (success && mounted) {
      context.read<MermaController>().loadMermas();
      context.read<InsumoController>().loadInsumos();
      context.read<CajaController>().loadDatosCaja();
      context.read<DashboardController>().refreshDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editaPreparacionHoy
                ? 'Corrección de preparación guardada'
                : 'Preparación registrada exitosamente',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final err = context.read<PreparacionController>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Error al guardar preparación'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _mostrarNotaDialog(int varianteId, String nombre) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NotaVariante',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1ED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.note_add_outlined,
                              color: _secondaryRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Observación para $nombre',
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notasCtrls[varianteId],
                        maxLines: 3,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: _textDark,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          hintText: 'Ej. Faltante por pedido especial...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _primaryOrange,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _secondaryRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Listo',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
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
    if (mounted) setState(() {});
  }

  Future<void> _entradaAdicional() async {
    if (_nombresVariantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay productos con control de stock preparado para agregar.',
          ),
        ),
      );
      return;
    }
    final prepController = context.read<PreparacionController>();
    final insumoController = context.read<InsumoController>();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AgregarProductoPreparado',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: _ModalAgregarPreparadoDialog(
                nombresVariantes: _nombresVariantes,
                prepController: prepController,
                messenger: messenger,
              ),
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      insumoController.loadInsumos();
      await _refreshVisibleStock();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Entrada sumada al inventario.'),
            backgroundColor: _successDark,
          ),
        );
      }
    }
  }

  Future<void> _refreshVisibleStock() async {
    final controller = context.read<PreparacionController>();
    final updated = <int, int>{};
    for (final product in controller.productosPreHechos) {
      if (product.id == null) continue;
      final variants = await controller.obtenerVariantesPorProducto(
        product.id!,
      );
      for (final variant in variants) {
        if (variant.id != null) updated[variant.id!] = variant.stock;
      }
    }
    if (mounted) setState(() => _stockVariantes.addAll(updated));
  }

  Future<void> _crearReglaTransformacion() async {
    if (_nombresVariantes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesitan al menos 2 variantes para crear una regla.'),
        ),
      );
      return;
    }
    final prepController = context.read<PreparacionController>();
    final insumoController = context.read<InsumoController>();
    final messenger = ScaffoldMessenger.of(context);
    await insumoController.loadInsumos();
    if (!mounted) return;

    final saved = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NuevaReglaTransformacion',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: _ModalNuevaReglaTransformacionDialog(
                nombresVariantes: _nombresVariantes,
                insumos: insumoController.insumos,
                prepController: prepController,
                messenger: messenger,
              ),
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Regla de transformación guardada.'),
          backgroundColor: _successDark,
        ),
      );
    }
  }

  Future<void> _aplicarTransformacion() async {
    final controller = context.read<PreparacionController>();
    final insumoController = context.read<InsumoController>();
    final messenger = ScaffoldMessenger.of(context);
    final rules = await controller.obtenerTransformaciones();
    if (!mounted) return;
    if (rules.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Primero crea una regla de transformación.'),
        ),
      );
      return;
    }

    final transformed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TransformarProductoPreparado',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: _ModalTransformarProductoDialog(
                rules: rules,
                nombresVariantes: _nombresVariantes,
                prepController: controller,
                messenger: messenger,
              ),
            ),
          ),
        );
      },
    );

    if (transformed == true && mounted) {
      insumoController.loadInsumos();
      await _refreshVisibleStock();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Transformación aplicada al inventario.'),
            backgroundColor: _successDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PreparacionController>();
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Registro de Preparación',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            tooltip: 'Más opciones',
            color: Colors.white,
            elevation: 8,
            shadowColor: Colors.black12,
            position: PopupMenuPosition.under,
            popUpAnimationStyle: const AnimationStyle(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _cardBorder),
            ),
            onSelected: (value) {
              if (value == 'entry') _entradaAdicional();
              if (value == 'rule') _crearReglaTransformacion();
              if (value == 'transform') _aplicarTransformacion();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'entry',
                height: 48,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_box_outlined,
                        color: _successDark,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Agregar inventario preparado',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'rule',
                height: 48,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_outlined,
                        color: _accentOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Crear regla de transformación',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'transform',
                height: 48,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: _secondaryRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Transformar producto',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Selector de Pestañas Segmentado ("Preparación Hoy" vs. "Sobrantes / Merma")
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Container(
              height: 54,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: _secondaryRed,
                unselectedLabelColor: const Color(0xFF4B5563),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.blender_outlined, size: 18),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Preparación Hoy',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 18),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Sobrantes / Merma',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFlatPreparacionList(ctrl),
                _buildSobrantesTab(ctrl),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _bgScreen,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_sobrantesAMerma.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Merma en borrador: ${_sobrantesAMerma.values.fold<int>(0, (total, quantity) => total + quantity)} unidad(es). Se aplicará al guardar.',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB45309),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 50,
                  child: TextFormField(
                    controller: _notaGlobalCtrl,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Observación general del día',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: const Icon(
                        Icons.assignment_outlined,
                        color: _secondaryRed,
                        size: 20,
                      ),
                      suffixIcon: const Icon(
                        Icons.edit_outlined,
                        color: _textMuted,
                        size: 19,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _primaryOrange,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_secondaryRed, _primaryOrange],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _secondaryRed.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: ctrl.isLoading ? null : _guardarPreparacion,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ctrl.isLoading)
                              const SizedBox.square(
                                dimension: 19,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            const SizedBox(width: 9),
                            Text(
                              ctrl.isLoading
                                  ? 'Guardando…'
                                  : _editaPreparacionHoy
                                      ? 'Guardar correcciones'
                                      : 'Guardar Preparación',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlatPreparacionList(PreparacionController ctrl) {
    if (ctrl.isLoading && _cantidadesCtrls.isEmpty) {
      return const AppLoadingState(message: 'Cargando...');
    }

    final varIds = _cantidadesCtrls.keys.toList();
    final previousLeftovers = ctrl.sobrantesPendientes.length;

    final totalCount = varIds.length + (previousLeftovers > 0 ? 1 : 0);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      itemCount: totalCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        if (previousLeftovers > 0 && i == 0) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _secondaryRed,
                  size: 20,
                ),
              ),
              title: Text(
                '$previousLeftovers producto(s) con sobrantes pendientes por gestionar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: _textDark,
                ),
              ),
              subtitle: Text(
                'Toca aquí para definir si pasan a la preparación de hoy o van a merma.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _textMuted,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: _secondaryRed,
              ),
              onTap: _abrirGestorSobrantesManual,
            ),
          );
        }

        final itemIndex = i - (previousLeftovers > 0 ? 1 : 0);
        final vid = varIds[itemIndex];
        final stock = _stockVariantes[vid] ?? 0;
        final isDerived = _variantesDerivadas.contains(vid);
        final enabledStock = stock > 0;
        final delayMs = (itemIndex * 40).clamp(0, 400);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + delayMs),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder),
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
                // Izquierda (Expanded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _nombresVariantes[vid] ?? 'Variante',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: _textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: enabledStock
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Stock: $stock',
                          style: GoogleFonts.poppins(
                            color: enabledStock
                                ? const Color(0xFF065F46)
                                : const Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isDerived)
                        Text(
                          'Comparte stock; prepara desde la base.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _mostrarNotaDialog(
                            vid,
                            _nombresVariantes[vid] ?? 'Variante $vid',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.note_add_outlined,
                                  size: 15,
                                  color: _accentOrange,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    _notasCtrls[vid]!.text.trim().isEmpty
                                        ? '+ Nota · Toca para añadir'
                                        : 'Nota agregada · Editar',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: _textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Derecha (Stepper)
                _AnimatedStepper(
                  icon: Icons.remove_rounded,
                  bgColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  enabled: !isDerived,
                  onTap: () => _ajustarCantidad(vid, -1),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 46,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _cantidadesCtrls[vid],
                    enabled: !isDerived,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    style: GoogleFonts.poppins(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _AnimatedStepper(
                  icon: Icons.add_rounded,
                  bgColor: const Color(0xFFD1FAE5),
                  iconColor: _successDark,
                  enabled: !isDerived,
                  onTap: () => _ajustarCantidad(vid, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ajustarCantidad(int varianteId, int delta) {
    final controller = _cantidadesCtrls[varianteId]!;
    final current = int.tryParse(controller.text) ?? 0;
    controller.text = (current + delta).toString();
  }

  Widget _buildSobrantesTab(PreparacionController ctrl) {
    final pending = ctrl.sobrantesPendientes;
    if (pending.isEmpty) {
      return const AppEmptyState(
        message: 'No hay productos preparados con stock disponible.',
        icon: Icons.check_circle_outline,
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: pending.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _abrirGestorSobrantesManual,
              icon: const Icon(Icons.inventory_2_outlined, size: 19),
              label: Text(
                'Abrir gestor de sobrantes y mermas',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        final item = pending[index - 1];
        final stock = (item['stock'] as num?)?.toInt() ?? 0;
        if (stock <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['producto_nombre']} · ${item['nombre_variante']}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock disponible: $stock unid.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _secondaryRed,
                  side: const BorderSide(color: _secondaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _abrirGestorSobrantesManual,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: Text(
                  'Gestionar',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// STEPPER CIRCULAR DE TARJETA DE PRODUCTO
// ============================================================================
class _AnimatedStepper extends StatefulWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool enabled;
  final VoidCallback onTap;

  const _AnimatedStepper({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_AnimatedStepper> createState() => _AnimatedStepperState();
}

class _AnimatedStepperState extends State<_AnimatedStepper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: widget.enabled ? widget.bgColor : const Color(0xFFF3F4F6),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.enabled ? widget.onTap : null,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                widget.icon,
                size: 19,
                color: widget.enabled ? widget.iconColor : Colors.black26,
              ),
            ),
          ),
        ),
      );
}

// ============================================================================
// PROMPT 3: MODAL "AGREGAR PRODUCTO PREPARADO"
// ============================================================================
class _ModalAgregarPreparadoDialog extends StatefulWidget {
  final Map<int, String> nombresVariantes;
  final PreparacionController prepController;
  final ScaffoldMessengerState messenger;

  const _ModalAgregarPreparadoDialog({
    required this.nombresVariantes,
    required this.prepController,
    required this.messenger,
  });

  @override
  State<_ModalAgregarPreparadoDialog> createState() =>
      _ModalAgregarPreparadoDialogState();
}

class _ModalAgregarPreparadoDialogState
    extends State<_ModalAgregarPreparadoDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _reasonCtrl;
  int? _variantId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: '1');
    _reasonCtrl = TextEditingController();
    _variantId = widget.nombresVariantes.keys.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required Widget prefixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: _textMuted,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _primaryOrange,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_outlined,
                      color: _secondaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Agregar producto preparado',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Producto / variante
              DropdownButtonFormField<int>(
                initialValue: _variantId,
                isExpanded: true,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
                decoration: _fieldDecoration(
                  label: 'Producto / variante',
                  prefixIcon: const Icon(
                    Icons.local_pizza_outlined,
                    color: _secondaryRed,
                    size: 20,
                  ),
                ),
                items: widget.nombresVariantes.entries
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(
                          e.value,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _variantId = v),
              ),
              const SizedBox(height: 14),

              // 2. Cantidad que se suma
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
                decoration: _fieldDecoration(
                  label: 'Cantidad que se suma',
                  prefixIcon: const Icon(
                    Icons.plus_one_rounded,
                    color: _successDark,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Motivo
              TextFormField(
                controller: _reasonCtrl,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: _textDark,
                ),
                decoration: _fieldDecoration(
                  label: 'Motivo',
                  hint: 'Motivo (ej. ingreso tardío)',
                  prefixIcon: const Icon(
                    Icons.edit_note_rounded,
                    color: _textMuted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Banner Informativo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se añadirá a las unidades actuales; no reemplaza el stock.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Botones de Acción
              Row(
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context, false);
                          },
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryOrange, _secondaryRed],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _secondaryRed.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isSaving
                              ? null
                              : () async {
                                  final quantity =
                                      int.tryParse(_amountCtrl.text.trim()) ??
                                          0;
                                  if (quantity <= 0 || _variantId == null) {
                                    widget.messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ingresa una cantidad mayor a cero.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => _isSaving = true);
                                  try {
                                    await widget.prepController
                                        .registrarEntradaProductoPreparado(
                                          varianteId: _variantId!,
                                          cantidad: quantity,
                                          motivo: _reasonCtrl.text.trim(),
                                        );
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    if (context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                    widget.messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e
                                              .toString()
                                              .replaceFirst('Exception: ', ''),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Registrar',
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

// ============================================================================
// PROMPT 4: MODAL "NUEVA REGLA DE TRANSFORMACIÓN"
// ============================================================================
class _ModalNuevaReglaTransformacionDialog extends StatefulWidget {
  final Map<int, String> nombresVariantes;
  final List<Insumo> insumos;
  final PreparacionController prepController;
  final ScaffoldMessengerState messenger;

  const _ModalNuevaReglaTransformacionDialog({
    required this.nombresVariantes,
    required this.insumos,
    required this.prepController,
    required this.messenger,
  });

  @override
  State<_ModalNuevaReglaTransformacionDialog> createState() =>
      _ModalNuevaReglaTransformacionDialogState();
}

class _ModalNuevaReglaTransformacionDialogState
    extends State<_ModalNuevaReglaTransformacionDialog> {
  late final TextEditingController _yieldCtrl;
  final Map<int, TextEditingController> _ingredientQuantities = {};
  final Set<int> _selectedIngredientIds = {};
  late List<int> _variants;
  int? _source;
  int? _target;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _yieldCtrl = TextEditingController(text: '1');
    _variants = widget.nombresVariantes.keys.toList();
    _source = _variants.first;
    _target = _variants.firstWhere((id) => id != _source);
    for (final insumo in widget.insumos) {
      if (insumo.id != null) {
        _ingredientQuantities[insumo.id!] = TextEditingController(text: '1');
      }
    }
  }

  @override
  void dispose() {
    _yieldCtrl.dispose();
    for (final ctrl in _ingredientQuantities.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required Widget prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: _textMuted,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _primaryOrange,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_fix_high_rounded,
                      color: _secondaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nueva regla de transformación',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Variante de origen
              DropdownButtonFormField<int>(
                initialValue: _source,
                isExpanded: true,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
                decoration: _fieldDecoration(
                  label: 'Variante de origen',
                  prefixIcon: const Icon(
                    Icons.outbox_rounded,
                    color: _accentOrange,
                    size: 20,
                  ),
                ),
                items: _variants
                    .map(
                      (id) => DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          widget.nombresVariantes[id] ?? 'Variante $id',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _source = v;
                  if (_target == _source) {
                    _target = _variants.firstWhere((id) => id != _source);
                  }
                }),
              ),
              const SizedBox(height: 12),

              // 2. Variante de destino
              DropdownButtonFormField<int>(
                key: ValueKey(_source),
                initialValue: _target,
                isExpanded: true,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
                decoration: _fieldDecoration(
                  label: 'Variante de destino',
                  prefixIcon: const Icon(
                    Icons.move_to_inbox_rounded,
                    color: _successDark,
                    size: 20,
                  ),
                ),
                items: _variants
                    .where((id) => id != _source)
                    .map(
                      (id) => DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          widget.nombresVariantes[id] ?? 'Variante $id',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _target = v),
              ),
              const SizedBox(height: 12),

              // 3. Unidades destino por unidad origen
              TextFormField(
                controller: _yieldCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
                decoration: _fieldDecoration(
                  label: 'Unidades destino por unidad origen',
                  prefixIcon: const Icon(
                    Icons.calculate_outlined,
                    color: _secondaryRed,
                    size: 20,
                  ),
                ),
              ),

              // Sección Insumos adicionales (opcional)
              if (widget.insumos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.layers_outlined,
                      size: 16,
                      color: Color(0xFF374151),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Insumos adicionales (opcional)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...widget.insumos.where((i) => i.id != null).map((i) {
                  final id = i.id!;
                  final isSelected = _selectedIngredientIds.contains(id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _secondaryRed.withValues(alpha: 0.45)
                              : _cardBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selectedIngredientIds.remove(id);
                              } else {
                                _selectedIngredientIds.add(id);
                              }
                            }),
                            child: SizedBox(
                              height: 46,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: _textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${i.nombre} (${i.unidadMedida})',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _textDark,
                                        ),
                                      ),
                                    ),
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: _secondaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      onChanged: (selected) => setState(() {
                                        if (selected == true) {
                                          _selectedIngredientIds.add(id);
                                        } else {
                                          _selectedIngredientIds.remove(id);
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: TextFormField(
                                controller: _ingredientQuantities[id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                                decoration: InputDecoration(
                                  labelText:
                                      'Cantidad de ${i.nombre} (${i.unidadMedida}) por unidad destino',
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: _textMuted,
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: _cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: _primaryOrange,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 8),

              // Nota de Ejemplo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFFD97706),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ejemplo: Americana → Hawaiana. La conversión quita primero la base y descuenta el insumo adicional.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Botones
              Row(
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context, false);
                          },
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryOrange, _secondaryRed],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _secondaryRed.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isSaving
                              ? null
                              : () async {
                                  final output = double.tryParse(
                                        _yieldCtrl.text.replaceAll(',', '.'),
                                      ) ??
                                      0;
                                  final additionalIngredients =
                                      <TransformacionInsumo>[];
                                  var invalidIngredient = false;
                                  for (final ingredient in widget.insumos.where(
                                    (i) => _selectedIngredientIds.contains(i.id),
                                  )) {
                                    final quantity = double.tryParse(
                                          _ingredientQuantities[ingredient.id]
                                                  ?.text
                                                  .replaceAll(',', '.') ??
                                              '',
                                        ) ??
                                        0;
                                    if (quantity <= 0 ||
                                        ingredient.id == null) {
                                      invalidIngredient = true;
                                      break;
                                    }
                                    additionalIngredients.add(
                                      TransformacionInsumo(
                                        insumoId: ingredient.id!,
                                        cantidad: quantity,
                                        unidadMedida: ingredient.unidadMedida,
                                      ),
                                    );
                                  }
                                  if (_source == _target ||
                                      output <= 0 ||
                                      invalidIngredient) {
                                    widget.messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Completa una regla válida.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final rule = Transformacion(
                                    varianteOrigenId: _source!,
                                    varianteDestinoId: _target!,
                                    rendimiento: output,
                                    insumosAdicionales: additionalIngredients,
                                  );
                                  setState(() => _isSaving = true);
                                  try {
                                    await widget.prepController
                                        .crearTransformacion(rule);
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    if (context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                    widget.messenger.showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                          child: Center(
                            child: Text(
                              'Guardar regla',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
      ),
    );
  }
}

// ============================================================================
// PROMPT 5: MODAL "TRANSFORMAR PRODUCTO PREPARADO"
// ============================================================================
class _ModalTransformarProductoDialog extends StatefulWidget {
  final List<Transformacion> rules;
  final Map<int, String> nombresVariantes;
  final PreparacionController prepController;
  final ScaffoldMessengerState messenger;

  const _ModalTransformarProductoDialog({
    required this.rules,
    required this.nombresVariantes,
    required this.prepController,
    required this.messenger,
  });

  @override
  State<_ModalTransformarProductoDialog> createState() =>
      _ModalTransformarProductoDialogState();
}

class _ModalTransformarProductoDialogState
    extends State<_ModalTransformarProductoDialog> {
  late final TextEditingController _amountCtrl;
  Transformacion? _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: '1');
    _selected = widget.rules.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: _secondaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transformar producto preparado',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Selector de Regla
              DropdownButtonFormField<Transformacion>(
                initialValue: _selected,
                isExpanded: true,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
                decoration: InputDecoration(
                  labelText: 'Regla de transformación',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.transform_rounded,
                    color: _secondaryRed,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _primaryOrange,
                      width: 1.5,
                    ),
                  ),
                ),
                items: widget.rules
                    .map(
                      (r) => DropdownMenuItem<Transformacion>(
                        value: r,
                        child: Text(
                          '${widget.nombresVariantes[r.varianteOrigenId] ?? 'Origen'} → ${widget.nombresVariantes[r.varianteDestinoId] ?? 'Destino'}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selected = v),
              ),
              const SizedBox(height: 16),

              // 2. Unidades de origen a transformar
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
                decoration: InputDecoration(
                  labelText: 'Unidades de origen a transformar',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.numbers_rounded,
                    color: _successDark,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _primaryOrange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Botones de Acción Inferiores
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: _cardBorder),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.pop(context, false);
                              },
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryOrange, _secondaryRed],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _secondaryRed.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isSaving
                              ? null
                              : () async {
                                  final qty =
                                      int.tryParse(_amountCtrl.text.trim()) ??
                                          0;
                                  if (qty <= 0 || _selected?.id == null) {
                                    widget.messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ingresa una cantidad válida mayor a cero.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => _isSaving = true);
                                  try {
                                    await widget.prepController
                                        .aplicarTransformacion(
                                          reglaId: _selected!.id!,
                                          cantidadOrigen: qty,
                                        );
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    if (context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                    widget.messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e
                                              .toString()
                                              .replaceFirst('Exception: ', ''),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sync_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Transformar',
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

