import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/screens/insumos/insumo_form_screen.dart';
import 'package:pizzaapp/screens/compras/compras_screen.dart';
import 'package:pizzaapp/features/inventory/domain/services/stock_level_policy.dart';

/// Pantalla rediseñada de Inventario de Insumos bajo Material Design 3,
/// con paleta cálida y funcional (verde bosque #1E4630 / #2E6F40, crema #FBF9F5, rojo #EF4444),
/// tarjetas de 100-108px con indicador vertical de estado, animación FadeInUp y FAB extendido moderno.
class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  // Paleta de colores para inventario
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _appBarGreen = Color(0xFF1E4630);
  static const Color _accentGreen = Color(0xFF2E6F40);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _amberAlert = Color(0xFFF59E0B);
  static const Color _redAlert = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _imageBg = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
    });
  }

  void _abrirFormulario({Insumo? insumo}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InsumoFormScreen(insumoAEditar: insumo),
      ),
    );
    if (result == true && mounted) {
      context.read<InsumoController>().loadInsumos();
    }
  }

  Future<void> _confirmarSeAcabo(Insumo insumo) async {
    if (insumo.stockActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El stock de "${insumo.nombre}" ya es 0.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _appBarGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Se acabó el insumo?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'El sistema registra ${insumo.stockActual.toStringAsFixed(2)} ${insumo.unidadMedida} de "${insumo.nombre}".\n\n¿Deseas ajustar el stock a 0 ahora?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: _textMuted,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _redAlert,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sí, ajustar a 0',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<InsumoController>();
    final success = await controller.ajustarStock(
      insumoId: insumo.id!,
      cantidadText: (-insumo.stockActual).toString(),
      motivo: 'Se acabó (Ajuste a 0)',
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock de "${insumo.nombre}" ajustado a 0',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _amberAlert,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.error ?? 'Error al ajustar stock',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _redAlert,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Retorna color para la barra vertical de acento izquierda
  Color _accentBarColor(Insumo insumo) {
    switch (StockLevelPolicy.classify(
      current: insumo.stockActual,
      minimum: insumo.stockMinimo,
    )) {
      case StockLevel.empty:
        return _redAlert;
      case StockLevel.low:
        return _amberAlert;
      case StockLevel.available:
        return _emeraldGreen;
    }
  }

  /// Retorna datos del badge de estado
  (String, Color, Color) _stockBadgeInfo(Insumo insumo) {
    switch (StockLevelPolicy.classify(
      current: insumo.stockActual,
      minimum: insumo.stockMinimo,
    )) {
      case StockLevel.empty:
        return ('Sin stock', const Color(0xFFFEF2F2), const Color(0xFFDC2626));
      case StockLevel.low:
        return ('Stock bajo', const Color(0xFFFEF3C7), const Color(0xFFD97706));
      case StockLevel.available:
        return ('En stock', const Color(0xFFECFDF5), const Color(0xFF059669));
    }
  }

  /// Tarjeta moderna de insumo (100px a 108px) con indicador de estado a la izquierda
  Widget _buildInsumoCard(Insumo insumo, int index) {
    final barColor = _accentBarColor(insumo);
    final (badgeLabel, badgeBg, badgeText) = _stockBadgeInfo(insumo);
    final hasPhoto = insumo.fotoRuta != null && insumo.fotoRuta!.trim().isNotEmpty;
    final esSinStock = insumo.stockActual <= 0;

    return _FadeInUpItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: _ScaleCard(
          onTap: () => _abrirFormulario(insumo: insumo),
          child: Container(
            constraints: const BoxConstraints(minHeight: 102),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Indicador de Estado Izquierdo: Barra vertical de 4px
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 4,
                    child: Container(color: barColor),
                  ),

                  // Contenido interno con efecto de pulsación InkWell
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _abrirFormulario(insumo: insumo),
                      splashColor: _accentGreen.withValues(alpha: 0.08),
                      highlightColor: _accentGreen.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Miniatura / Imagen (Izquierda): 64px × 64px, radio 12px
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: _imageBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF3F4F6)),
                                image: hasPhoto
                                    ? DecorationImage(
                                        image: FileImage(File(insumo.fotoRuta!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: !hasPhoto
                                  ? const Center(
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: _accentGreen,
                                        size: 28,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // 2. Información Detallada (Centro)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Título del Insumo en Poppins Bold 16sp
                                  Text(
                                    insumo.nombre,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),

                                  // Línea 1 (Categoría): en color verde bosque/salvia
                                  Text(
                                    insumo.tipoInsumo,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _accentGreen,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // Línea 2 (Stock actual) con cifra en rojo si no hay existencias
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 13,
                                        color: esSinStock ? const Color(0xFFDC2626) : _textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Stock: ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${insumo.stockActual.toStringAsFixed(2)} ${insumo.unidadMedida}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: esSinStock ? const Color(0xFFDC2626) : _textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Línea 3 (Stock Mínimo)
                                  Text(
                                    'Mínimo: ${insumo.stockMinimo.toStringAsFixed(2)} ${insumo.unidadMedida}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.normal,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 3. Estados y Acciones (Derecha)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Badge de estado
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Botón de menú de tres puntos (36px padding táctil)
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: _textMuted,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    onSelected: (val) {
                                      switch (val) {
                                        case 'edit':
                                          _abrirFormulario(insumo: insumo);
                                          break;
                                        case 'comprar':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const ComprasScreen(),
                                            ),
                                          );
                                          break;
                                        case 'cero':
                                          _confirmarSeAcabo(insumo);
                                          break;
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: Color(0xFF2563EB),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Editar insumo',
                                              style: GoogleFonts.poppins(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'comprar',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.shopping_cart_outlined,
                                              size: 18,
                                              color: _accentGreen,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Comprar',
                                              style: GoogleFonts.poppins(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'cero',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.remove_circle_outline,
                                              size: 18,
                                              color: Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Se acabó (Ajustar a 0)',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: const Color(0xFFD97706),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InsumoController>(
      builder: (context, ctrl, child) {
        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: _appBarGreen,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Volver',
            ),
            title: Text(
              'Inventario de Insumos',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Actualizar',
                onPressed: ctrl.loadInsumos,
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_accentGreen),
                  ),
                )
              : ctrl.insumos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2ECE6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 44,
                                color: _accentGreen,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No hay insumos registrados',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Agrega ingredientes, empaques y suministros para controlar el stock de tu negocio.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _textMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _abrirFormulario(),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                'Nuevo Insumo',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentGreen,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: _accentGreen,
                      onRefresh: () async {
                        await ctrl.loadInsumos();
                      },
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
                        itemCount: ctrl.insumos.length,
                        itemBuilder: (_, i) =>
                            _buildInsumoCard(ctrl.insumos[i], i),
                      ),
                    ),

          // Botón Flotante de Acción (FAB)
          floatingActionButton: _ScaleFab(
            onPressed: () => _abrirFormulario(),
          ),
        );
      },
    );
  }
}

/// Floating Action Button moderno con texto e icono integrado
class _ScaleFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _ScaleFab({required this.onPressed});

  @override
  State<_ScaleFab> createState() => _ScaleFabState();
}

class _ScaleFabState extends State<_ScaleFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const fabColor = Color(0xFF1E4630);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: fabColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: fabColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Nuevo Insumo',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget envoltorio para animación en cascada suave (FadeInUp) con desfase de 50ms
class _FadeInUpItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _FadeInUpItem({required this.index, required this.child});

  @override
  State<_FadeInUpItem> createState() => _FadeInUpItemState();
}

class _FadeInUpItemState extends State<_FadeInUpItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));

    final delay = Duration(milliseconds: (widget.index * 50).clamp(0, 500));
    Future.delayed(delay, () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

/// Microinteracción táctil con escalado a 0.98x al pulsar la tarjeta
class _ScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleCard({required this.child, required this.onTap});

  @override
  State<_ScaleCard> createState() => _ScaleCardState();
}

class _ScaleCardState extends State<_ScaleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
