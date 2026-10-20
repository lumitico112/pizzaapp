import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/services/pos_service.dart';

class PosProductGrid extends StatelessWidget {
  final PosController controller;
  final Function(PosItem) onItemTapped;
  final List<Promocion> promociones;
  final Function(Promocion)? onPromoTapped;

  const PosProductGrid({
    super.key,
    required this.controller,
    required this.onItemTapped,
    this.promociones = const [],
    this.onPromoTapped,
  });

  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _priceGreen = Color(0xFF10B981);
  static const Color _borderColor = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD62828)),
      );
    }

    final catId = controller.categoriaSeleccionada;
    final showPromos = catId == null || catId == -1;
    final visiblePromos = showPromos ? promociones : const <Promocion>[];
    final items = catId == -1 ? const <PosItem>[] : controller.posItems;
    final totalCount = visiblePromos.length + items.length;

    if (totalCount == 0) {
      final isPromoTab = catId == -1;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isPromoTab
                    ? Icons.local_offer_outlined
                    : Icons.restaurant_menu_rounded,
                size: 44,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPromoTab
                  ? 'No hay promociones activas en este momento'
                  : 'No hay productos en esta categoría',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.74,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: totalCount,
      itemBuilder: (ctx, i) {
        if (i < visiblePromos.length) {
          final promo = visiblePromos[i];
          return _buildPromoCard(promo, i);
        }

        final item = items[i - visiblePromos.length];
        final imagePath = item.variante.imagen ?? item.producto.fotoRuta;
        final tipoPrep = item.producto.tipoPreparacion.toLowerCase();
        final hasStockBadge =
            !controller.esVentaHistorica && (tipoPrep == 'anticipado' || tipoPrep == 'ambos');
        final stock = item.variante.stock;
        final inStock = controller.esVentaHistorica || stock > 0 || tipoPrep == 'ambos';
        final nombreProducto = controller.nombreVenta(item.producto, item.variante);
        final nombreVariante = item.variante.nombreVariante;

        return _FadeInUpItem(
          index: i,
          child: Material(
            color: _cardBg,
            borderRadius: BorderRadius.circular(18),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onItemTapped(item),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F2937).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Área de imagen con esquinas superiores redondeadas e insignia
                    Expanded(
                      flex: 55,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: Container(
                                color: const Color(0xFFF8FAFC),
                                child: imagePath != null &&
                                        File(imagePath).existsSync()
                                    ? Image.file(
                                        File(imagePath),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: const Color(0xFFFFF7ED),
                                        child: Center(
                                          child: Icon(
                                            Icons.local_pizza_rounded,
                                            size: 46,
                                            color: const Color(0xFFFF6A00)
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          // Insignia o marcador del tipo de masa / preparación
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tipoPrep == 'anticipado'
                                    ? 'Pre-hecho'
                                    : tipoPrep == 'ambos'
                                        ? 'Stock + Momento'
                                        : 'Al momento',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Detalles del Producto
                    Expanded(
                      flex: 45,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre
                            Text(
                              nombreProducto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 1),
                            // Presentación
                            Text(
                              nombreVariante,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                                color: _textMuted,
                              ),
                            ),
                            const Spacer(),
                            // Fila de precio y stock
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'S/. ${item.variante.precioVenta.toStringAsFixed(2)}',
                                    maxLines: 1,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _priceGreen,
                                    ),
                                  ),
                                ),
                                if (hasStockBadge)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: inStock
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: inStock
                                            ? const Color(0xFFA7F3D0)
                                            : const Color(0xFFFECACA),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'Stk: $stock',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: inStock
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoCard(Promocion promo, int index) {
    final imagePath = promo.imagenRuta;
    final descripcion = controller.descripcionPromocion(promo);
    final promoStock = controller.stockDisponiblePromocion(promo);
    final hasStockBadge = !controller.esVentaHistorica && promoStock != null;
    final inStock =
        controller.esVentaHistorica || promoStock == null || promoStock > 0;

    return _FadeInUpItem(
      index: index,
      child: Material(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPromoTapped != null ? () => onPromoTapped!(promo) : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F2937).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 55,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: Container(
                            color: const Color(0xFFF8FAFC),
                            child: imagePath != null &&
                                    File(imagePath).existsSync()
                                ? Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: const Color(0xFFFFF7ED),
                                    child: Center(
                                      child: Icon(
                                        Icons.local_offer_rounded,
                                        size: 46,
                                        color: const Color(0xFFFF6A00)
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD62828), Color(0xFFFF6A00)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Promoción',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 45,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textMuted,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'S/. ${promo.precio.toStringAsFixed(2)}',
                                maxLines: 1,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _priceGreen,
                                ),
                              ),
                            ),
                            if (hasStockBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: inStock
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: inStock
                                        ? const Color(0xFFA7F3D0)
                                        : const Color(0xFFFECACA),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'Stk: $promoStock',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: inStock
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
}

class _FadeInUpItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _FadeInUpItem({required this.index, required this.child});

  @override
  State<_FadeInUpItem> createState() => _FadeInUpItemState();
}

class _FadeInUpItemState extends State<_FadeInUpItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final delayMs = (widget.index * 30).clamp(0, 300);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
