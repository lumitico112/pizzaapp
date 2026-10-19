import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';

class PosHistorialBoletasSheet extends StatefulWidget {
  final PosController controller;

  const PosHistorialBoletasSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, PosController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => PosHistorialBoletasSheet(controller: controller),
    );
  }

  @override
  State<PosHistorialBoletasSheet> createState() =>
      _PosHistorialBoletasSheetState();
}

class _PosHistorialBoletasSheetState extends State<PosHistorialBoletasSheet> {
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _brandRed = Color(0xFFD62828);
  static const Color _borderColor = Color(0xFFE5E7EB);

  int _refreshTick = 0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Manija superior de arrastre
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Encabezado del Historial
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBE3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: _brandRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Historial de Boletas Emitidas',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Cerrar historial de boletas',
                      onTap: () => Navigator.pop(sheetContext),
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.pop(sheetContext),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: _textMuted,
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

              // Línea divisoria
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Divider(height: 1, color: _borderColor),
              ),

              // Contenido / Lista de Boletas
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey(_refreshTick),
                  future: widget.controller.getHistorialVentas(),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _brandRed),
                      );
                    }

                    final ventas = snapshot.data ?? [];
                    if (ventas.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 44,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay ventas registradas recientemente',
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

                    return ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: ventas.length,
                      itemBuilder: (ctx, index) {
                        final v = ventas[index];
                        final ventaId = v['id'] as int;
                        final fecha = v['fecha'] as String;
                        final hora = v['hora'] as String;
                        final total = (v['total'] as num).toDouble();
                        final metodo =
                            (v['metodo_pago'] as String).toUpperCase();
                        final itemsCount = v['items_count'] ?? 1;
                        final isAnulada = (v['anulada'] as int? ?? 0) == 1;
                        final nota = (v['nota'] as String? ?? '').trim();

                        String motivoAnulacion = '';
                        if (isAnulada && nota.contains('[ANULADA:')) {
                          final start = nota.indexOf('[ANULADA:') + 9;
                          final end = nota.indexOf(']', start);
                          motivoAnulacion = end != -1
                              ? nota.substring(start, end).trim()
                              : nota.substring(start).trim();
                        }

                        Future<void> verBoleta() async {
                          final messenger = ScaffoldMessenger.of(context);
                          final path =
                              await widget.controller.obtenerBoleta(ventaId);
                          if (path != null) {
                            await OpenFilex.open(path);
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo abrir la boleta'),
                              ),
                            );
                          }
                        }

                        Future<void> comparteBoleta() async {
                          final messenger = ScaffoldMessenger.of(context);
                          final path =
                              await widget.controller.obtenerBoleta(ventaId);
                          if (path != null) {
                            await SharePlus.instance.share(
                              ShareParams(
                                files: [XFile(path)],
                                text:
                                    'Boleta de Venta #$ventaId - KIMI PIZZA',
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo compartir la boleta',
                                ),
                              ),
                            );
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isAnulada
                                ? const Color(0xFFF9FAFB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAnulada
                                  ? const Color(0xFFFCA5A5)
                                  : _borderColor,
                              width: 1,
                            ),
                            boxShadow: isAnulada
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF1F2937)
                                          .withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final path = await widget.controller
                                    .obtenerBoleta(ventaId);
                                if (path != null) {
                                  await OpenFilex.open(path);
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('No se pudo abrir la boleta'),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Columna 1: Avatar / Identificador
                                    Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isAnulada
                                            ? const Color(0xFFE5E7EB)
                                            : const Color(0xFFFFEBE3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '#$ventaId',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isAnulada
                                              ? _textMuted
                                              : _brandRed,
                                          decoration: isAnulada
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),

                                    // Columna 2: Detalles de la Boleta
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'S/. ${total.toStringAsFixed(2)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAnulada
                                                        ? _textMuted
                                                        : _textDark,
                                                    decoration: isAnulada
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (isAnulada)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFFEE2E2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFFCA5A5),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'ANULADA',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                            0xFFB91C1C),
                                                      ),
                                                    ),
                                                  )
                                                else if (total <= 0 ||
                                                    metodo.contains('CORTES'))
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFFEF3C7),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFFDE68A),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'CORTESÍA',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                            0xFFB45309),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    '- $metodo',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF4B5563),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '$fecha $hora',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: _textMuted,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  ' • ',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: _textMuted,
                                                  ),
                                                ),
                                                Text(
                                                  '$itemsCount ítem(s)',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isAnulada
                                                        ? _textMuted
                                                        : const Color(
                                                            0xFF2E6F40),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isAnulada &&
                                                motivoAnulacion.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Text(
                                                  'Motivo: $motivoAnulacion',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontStyle: FontStyle.italic,
                                                    color:
                                                        const Color(0xFFDC2626),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Columna 3: Acciones Rápidas
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Botón Visualizar
                                        Semantics(
                                          button: true,
                                          label: 'Ver boleta #$ventaId',
                                          onTap: verBoleta,
                                          child: ExcludeSemantics(
                                            child: SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: Center(
                                                child: Material(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(18),
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(18),
                                                    onTap: verBoleta,
                                                    child: const SizedBox(
                                                      width: 34,
                                                      height: 34,
                                                      child: Icon(
                                                        Icons.visibility_outlined,
                                                        size: 18,
                                                        color: Color(0xFF2563EB),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Botón Compartir
                                        Semantics(
                                          button: true,
                                          label: 'Compartir boleta #$ventaId',
                                          onTap: comparteBoleta,
                                          child: ExcludeSemantics(
                                            child: SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: Center(
                                                child: Material(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(18),
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(18),
                                                    onTap: comparteBoleta,
                                                    child: const SizedBox(
                                                      width: 34,
                                                      height: 34,
                                                      child: Icon(
                                                        Icons.share_outlined,
                                                        size: 17,
                                                        color: Color(0xFF059669),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Menú de Acciones (Editar/Anular) solo para ventas activas
                                        if (!isAnulada) ...[
                                          const SizedBox(width: 4),
                                          PopupMenuButton<String>(
                                            tooltip:
                                                'Más acciones de la venta #$ventaId',
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 20,
                                              color: _textMuted,
                                            ),
                                            padding: const EdgeInsets.all(14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            onSelected: (action) {
                                              if (action == 'cambiar_metodo') {
                                                _mostrarDialogoCambiarMetodo(
                                                  context,
                                                  ventaId,
                                                  metodo,
                                                );
                                              } else if (action ==
                                                  'anular_recargar') {
                                                _mostrarDialogoAnularVenta(
                                                  context,
                                                  ventaId,
                                                  total,
                                                  recargarEnCarrito: true,
                                                );
                                              } else if (action ==
                                                  'anular_solo') {
                                                _mostrarDialogoAnularVenta(
                                                  context,
                                                  ventaId,
                                                  total,
                                                  recargarEnCarrito: false,
                                                );
                                              }
                                            },
                                            itemBuilder: (popCtx) => [
                                              if (total > 0 &&
                                                  !metodo.contains('CORTES'))
                                                PopupMenuItem(
                                                  value: 'cambiar_metodo',
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.swap_horiz,
                                                        size: 20,
                                                        color:
                                                            Color(0xFF2563EB),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Flexible(
                                                        child: Text(
                                                          'Cambiar método de pago',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              PopupMenuItem(
                                                value: 'anular_recargar',
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .shopping_cart_checkout,
                                                      size: 20,
                                                      color: Color(0xFFD97706),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Flexible(
                                                      child: Text(
                                                        'Anular y corregir en carrito',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'anular_solo',
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.cancel_outlined,
                                                      size: 20,
                                                      color: Color(0xFFDC2626),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Flexible(
                                                      child: Text(
                                                        'Anular venta',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFFDC2626),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarDialogoCambiarMetodo(
    BuildContext context,
    int ventaId,
    String metodoActual,
  ) async {
    String seleccionado = metodoActual.toLowerCase().trim();
    if (seleccionado == 'yape/plin') seleccionado = 'yape';
    if (!const ['efectivo', 'yape', 'plin', 'tarjeta'].contains(seleccionado)) {
      seleccionado = 'efectivo';
    }

    final metodos = [
      {
        'id': 'efectivo',
        'label': 'Efectivo',
        'icon': Icons.payments_outlined,
        'color': const Color(0xFF059669),
      },
      {
        'id': 'yape',
        'label': 'Yape',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFF7C3AED),
      },
      {
        'id': 'plin',
        'label': 'Plin',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'id': 'tarjeta',
        'label': 'Tarjeta',
        'icon': Icons.credit_card_rounded,
        'color': const Color(0xFFD97706),
      },
    ];

    final nuevoMetodo = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz,
                    color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cambiar Método de Pago',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Venta #$ventaId - Método actual: ${metodoActual.toUpperCase()}',
                style: GoogleFonts.poppins(fontSize: 12, color: _textMuted),
              ),
              const SizedBox(height: 16),
              ...metodos.map((m) {
                final id = m['id'] as String;
                final isSelected = seleccionado == id;
                final color = m['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : _borderColor,
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setDialogState(() => seleccionado = id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(m['icon'] as IconData, color: color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m['label'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? color : _textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: color, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancelar',
                  style: GoogleFonts.poppins(color: _textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, seleccionado),
              child: Text('Guardar Cambio',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (nuevoMetodo != null && nuevoMetodo != metodoActual.toLowerCase()) {
      final success =
          await widget.controller.cambiarMetodoPago(ventaId, nuevoMetodo);
      if (!context.mounted) return;
      if (success) {
        context.read<CajaController>().loadDatosCaja();
        context.read<DashboardController>().refreshDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Venta #$ventaId actualizada a ${nuevoMetodo.toUpperCase()}',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        setState(() => _refreshTick++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error ?? 'Error al cambiar método'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAnularVenta(
    BuildContext context,
    int ventaId,
    double total, {
    bool recargarEnCarrito = false,
  }) async {
    final motivos = [
      'Cliente canceló pedido',
      'Error al registrar venta',
      'Producto / cantidad equivocada',
      'Cobro duplicado',
      'Otro motivo',
    ];
    String motivoSeleccionado = recargarEnCarrito
        ? 'Producto / cantidad equivocada'
        : 'Cliente canceló pedido';
    final notaCtrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  recargarEnCarrito
                      ? Icons.shopping_cart_checkout
                      : Icons.cancel_outlined,
                  color: const Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  recargarEnCarrito
                      ? 'Anular y Editar en Carrito'
                      : 'Anular Venta #$ventaId',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recargarEnCarrito
                              ? 'La venta #$ventaId (S/. ${total.toStringAsFixed(2)}) se anulará, se revertirá su stock y dinero, y sus productos se cargarán en el carrito para que los corrijas.'
                              : 'Esta acción devolverá los productos e insumos al inventario y revertirá el dinero de la caja registradora.',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Motivo de anulación:',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: motivos.map((m) {
                    final isSel = motivoSeleccionado == m;
                    return ChoiceChip(
                      label: Text(
                        m,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight:
                              isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFFFEE2E2),
                      backgroundColor: const Color(0xFFF3F4F6),
                      onSelected: (val) {
                        if (val) setDialogState(() => motivoSeleccionado = m);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Detalle o nota adicional (opcional)',
                    hintStyle:
                        GoogleFonts.poppins(fontSize: 12, color: _textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.poppins(color: _textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                recargarEnCarrito ? 'Anular y Reabrir Carrito' : 'Anular Venta',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmado == true) {
      final motivoFinal = notaCtrl.text.trim().isEmpty
          ? motivoSeleccionado
          : '$motivoSeleccionado: ${notaCtrl.text.trim()}';

      final ok = await widget.controller.anularVenta(
        ventaId,
        motivo: motivoFinal,
        recargarEnCarrito: recargarEnCarrito,
      );

      if (!context.mounted) return;
      if (ok) {
        context.read<CajaController>().loadDatosCaja();
        context.read<DashboardController>().refreshDashboard();

        if (recargarEnCarrito) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Venta #$ventaId anulada. Productos cargados al carrito para corregir.',
              ),
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta #$ventaId anulada correctamente.'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
          setState(() => _refreshTick++);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error ?? 'Error al anular venta'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }
}
