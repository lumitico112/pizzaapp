import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';

class PosCartSummary extends StatelessWidget {
  final PosController controller;
  final VoidCallback onCobrar;

  const PosCartSummary({
    super.key,
    required this.controller,
    required this.onCobrar,
  });

  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final items = controller.carrito;
    final isEmpty = items.isEmpty;
    final esSoloCortesia = !isEmpty && controller.granTotal <= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila del estado (o desglose si hay ítems)
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBE3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFD62828),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu pedido aparecerá aquí',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 110),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 10,
                  color: Color(0xFFF1F5F9),
                ),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final title = item.esPromocion
                      ? item.nombrePromocion ?? 'Promoción'
                      : '${controller.nombreVenta(item.producto!, item.variante!)} · ${item.variante!.nombreVariante}';
                  final price = item.esPromocion
                      ? item.precioPromocion
                      : item.variante!.precioVenta;

                  return Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${item.cantidad}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: const Color(0xFF1E4630),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                                if (item.esCortesia) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'CORTESÍA',
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              item.esCortesia
                                  ? 'Sin cobro · stock descontado al confirmar'
                                  : 'S/. ${(price ?? 0).toStringAsFixed(2)} c/u',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'S/. ${item.total.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        button: true,
                        label: 'Quitar $title del pedido',
                        child: IconButton(
                          tooltip: 'Quitar del pedido',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => controller.removerDelCarrito(item),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Fila de Acción de Cobro
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esSoloCortesia ? 'Total cortesía' : 'Total del pedido',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'S/. ${controller.granTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: esSoloCortesia
                            ? const Color(0xFF059669)
                            : _textDark,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de Cobro / Confirmar Cortesía
              Semantics(
                button: true,
                enabled: !isEmpty,
                label: esSoloCortesia
                    ? 'Confirmar cortesía'
                    : 'Cobrar total ${controller.granTotal.toStringAsFixed(2)} soles',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isEmpty ? null : onCobrar,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: isEmpty
                            ? null
                            : (esSoloCortesia
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6A00),
                                      Color(0xFFD62828),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )),
                        color: isEmpty ? const Color(0xFFE5E7EB) : null,
                        boxShadow: isEmpty
                            ? null
                            : [
                                BoxShadow(
                                  color: (esSoloCortesia
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFD62828))
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEmpty
                                  ? Icons.point_of_sale_outlined
                                  : (esSoloCortesia
                                      ? Icons.volunteer_activism_outlined
                                      : Icons.point_of_sale_outlined),
                              size: 20,
                              color: isEmpty
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              esSoloCortesia ? 'CONFIRMAR CORTESÍA' : 'COBRAR',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isEmpty
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.white,
                                letterSpacing: 0.5,
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
    );
  }
}
