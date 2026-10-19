import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/services/pos_service.dart';

class PosItemDetailSheet extends StatefulWidget {
  final PosItem? item;
  final Promocion? promo;
  final PosController controller;

  const PosItemDetailSheet({
    super.key,
    this.item,
    this.promo,
    required this.controller,
  }) : assert(item != null || promo != null);

  static Future<bool?> show({
    required BuildContext context,
    required PosItem item,
    required PosController controller,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => PosItemDetailSheet(
        item: item,
        controller: controller,
      ),
    );
  }

  static Future<bool?> showPromo({
    required BuildContext context,
    required Promocion promo,
    required PosController controller,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => PosItemDetailSheet(
        promo: promo,
        controller: controller,
      ),
    );
  }

  @override
  State<PosItemDetailSheet> createState() => _PosItemDetailSheetState();
}

class _PosItemDetailSheetState extends State<PosItemDetailSheet> {
  int _cantidad = 1;
  bool _deCortesia = false;
  late final TextEditingController _precioController;

  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _brandRed = Color(0xFFD62828);
  static const Color _brandOrange = Color(0xFFFF6A00);
  static const Color _borderColor = Color(0xFFE5E7EB);

  double get _precioBase =>
      widget.promo?.precio ?? widget.item!.variante.precioVenta;

  @override
  void initState() {
    super.initState();
    _precioController = TextEditingController(
      text: _precioBase.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  double get _precioActual {
    if (_deCortesia) return 0.0;
    final parsed = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );
    return parsed ?? 0.0;
  }

  double get _subtotal => _precioActual * _cantidad;

  void _guardar({required bool cobrarAhora}) {
    final precioFinal = _precioActual;

    if (!_deCortesia && (!precioFinal.isFinite || precioFinal < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio no puede ser negativo.')),
      );
      return;
    }

    if (widget.promo != null) {
      final promo = widget.promo!;
      final error = widget.controller.agregarPromocionAlCarrito(
        promo,
        cantidad: _cantidad,
        precioPersonalizado: _deCortesia
            ? null
            : ((precioFinal - promo.precio).abs() > 0.001 ? precioFinal : null),
        esCortesia: _deCortesia,
      );

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }

      Navigator.pop(context, cobrarAhora);
      return;
    }

    final item = widget.item!;

    final newVariante = VarianteProducto(
      id: item.variante.id,
      productoId: item.variante.productoId,
      nombreVariante: item.variante.nombreVariante,
      precioVenta: precioFinal,
      costoEstimadoManual: item.variante.costoEstimadoManual,
      empaqueInsumoId: item.variante.empaqueInsumoId,
      imagen: item.variante.imagen,
      stock: item.variante.stock,
      active: item.variante.active,
      varianteBaseId: item.variante.varianteBaseId,
    );

    final customItem = PosItem(item.producto, newVariante);

    final error = widget.controller.agregarAlCarrito(
      customItem,
      _cantidad,
      esCortesia: _deCortesia,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pop(context, cobrarAhora);
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final item = widget.item;
    final imagePath = promo != null
        ? promo.imagenRuta
        : (item!.variante.imagen ?? item.producto.fotoRuta);
    final titulo = promo != null
        ? promo.nombre
        : '${widget.controller.nombreVenta(item!.producto, item.variante)} - ${item.variante.nombreVariante}';
    final subtitulo =
        promo != null ? widget.controller.descripcionPromocion(promo) : null;
    final isCartEmpty = widget.controller.carrito.isEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Manija de arrastre superior
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sección de Media (Foto del Producto o Promoción)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: const Color(0xFFFFF7ED),
                  child: imagePath != null && File(imagePath).existsSync()
                      ? Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            promo != null
                                ? Icons.local_offer_rounded
                                : Icons.local_pizza_rounded,
                            size: 52,
                            color: _brandOrange.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Detalles del Producto / Promoción (Título)
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              if (subtitulo != null && subtitulo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Campo de Precio Editable
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precio (Editable)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 52,
                    child: TextField(
                      controller: _precioController,
                      enabled: !_deCortesia,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _deCortesia ? _textMuted : _textDark,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.sell_outlined,
                          size: 19,
                          color: _textMuted,
                        ),
                        prefixText: 'S/ ',
                        prefixStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _deCortesia ? _textMuted : _textDark,
                        ),
                        filled: true,
                        fillColor: _deCortesia
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _brandOrange,
                            width: 1.6,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Interruptor de Cortesía
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marcar como cortesía',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Se registrará a S/. 0 y descontará el stock correspondiente.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _textMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Marcar como cortesía',
                      child: Switch.adaptive(
                        value: _deCortesia,
                        activeThumbColor: _brandRed,
                        activeTrackColor: const Color(0xFFFFD8C8),
                        onChanged: (val) {
                          setState(() {
                            _deCortesia = val;
                            if (val) {
                              _precioController.text = '0.00';
                            } else {
                              _precioController.text =
                                  _precioBase.toStringAsFixed(2);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Control de Cantidad (Stepper)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón Menos (-)
                  Semantics(
                    button: true,
                    label: 'Disminuir cantidad',
                    onTap: _cantidad > 1
                        ? () => setState(() => _cantidad--)
                        : null,
                    child: ExcludeSemantics(
                      child: Material(
                        color: const Color(0xFFFEF2F2),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _cantidad > 1
                              ? () => setState(() => _cantidad--)
                              : null,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.remove_circle_outline,
                              color: _cantidad > 1
                                  ? _brandRed
                                  : _brandRed.withValues(alpha: 0.35),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Cantidad Central
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: Text(
                        '$_cantidad',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                    ),
                  ),

                  // Botón Más (+)
                  Semantics(
                    button: true,
                    label: 'Aumentar cantidad',
                    onTap: () => setState(() => _cantidad++),
                    child: ExcludeSemantics(
                      child: Material(
                        color: const Color(0xFFECFDF5),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _cantidad++),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.add_circle,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Resumen de Subtotal
              Center(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                    children: [
                      const TextSpan(text: 'Subtotal: '),
                      TextSpan(
                        text: 'S/. ${_subtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: _brandRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Acciones Inferiores (Los Botones de Registro)
              if (isCartEmpty)
                // Fila con 2 Botones (Carrito vacío)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _guardar(cobrarAhora: false),
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                            color: _brandRed,
                          ),
                          label: Text(
                            'Agregar',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _brandRed,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _brandRed, width: 1.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _guardar(cobrarAhora: true),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [_brandOrange, _brandRed],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandRed.withValues(alpha: 0.32),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.payments_outlined,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cobrar ahora',
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
                )
              else
                // Botón Único (Carrito con productos)
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _guardar(cobrarAhora: false),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [_brandOrange, _brandRed],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _brandRed.withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 19,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _deCortesia
                                  ? 'Agregar cortesía'
                                  : 'Agregar al pedido',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
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
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
