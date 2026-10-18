import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class PosVentaExitosaDialog extends StatelessWidget {
  final String? pdfPath;
  final double total;
  final String metodoPago;
  final String ticketNum;

  const PosVentaExitosaDialog({
    super.key,
    this.pdfPath,
    required this.total,
    required this.metodoPago,
    required this.ticketNum,
  });

  /// Muestra el modal de confirmación con la animación y el scrim personalizados.
  static Future<void> show({
    required BuildContext context,
    String? pdfPath,
    required double total,
    required String metodoPago,
    required String ticketNum,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Venta Exitosa',
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.50),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * animation.value,
            sigmaY: 4 * animation.value,
          ),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PosVentaExitosaDialog(
          pdfPath: pdfPath,
          total: total,
          metodoPago: metodoPago,
          ticketNum: ticketNum,
        );
      },
    );
  }

  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textPill = Color(0xFF374151);
  static const Color _brandOrange = Color(0xFFFF6A00);
  static const Color _brandRed = Color(0xFFD62828);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _emeraldPastel = Color(0xFFD1FAE5);
  static const Color _pillBackground = Color(0xFFF9FAFB);
  static const Color _borderGrey = Color(0xFFE5E7EB);
  static const Color _secondaryBtnBg = Color(0xFFFFF5F2);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.86;
    final tienePdf = pdfPath != null && pdfPath!.isNotEmpty;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 2. Icono de Éxito Animado (Header Visual Concéntrico)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 650),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: _emeraldPastel,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _emeraldGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _emeraldGreen.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Tipografía
              Text(
                '¡Venta Cobrada con Éxito!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tienePdf
                    ? 'La venta ha sido registrada en el sistema y la boleta fue generada correctamente.'
                    : 'La venta fue registrada correctamente, pero la boleta no pudo generarse. Puedes reimprimirla desde el historial de boletas.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: _textMuted,
                  height: 1.4,
                ),
              ),

              // Píldora de Resumen Rápido
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _pillBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderGrey),
                ),
                child: Text(
                  'S/. ${total.toStringAsFixed(2)} · $metodoPago · $ticketNum',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textPill,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 4. Botones de Acción
              if (tienePdf) ...[
                // Botón Primario: "Ver Boleta"
                _ScaleActionButton(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_brandOrange, _brandRed],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _brandOrange.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    await OpenFilex.open(pdfPath!);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ver Boleta',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Botón Secundario: "Descargar / Compartir Boleta"
                _ScaleActionButton(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _secondaryBtnBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _brandRed,
                      width: 1.5,
                    ),
                  ),
                  onPressed: () async {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(pdfPath!)],
                        text: 'Boleta de Venta - KIMI PIZZA',
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.share_outlined,
                        color: _brandRed,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Descargar / Compartir Boleta',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _brandRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Botón Terciario: "Continuar / Nueva Venta"
              _ScaleActionButton(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Color(0xFF4B5563),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Continuar / Nueva Venta',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaleActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final BoxDecoration decoration;
  final double height;

  const _ScaleActionButton({
    required this.onPressed,
    required this.child,
    required this.decoration,
    this.height = 50,
  });

  @override
  State<_ScaleActionButton> createState() => _ScaleActionButtonState();
}

class _ScaleActionButtonState extends State<_ScaleActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: widget.decoration,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
