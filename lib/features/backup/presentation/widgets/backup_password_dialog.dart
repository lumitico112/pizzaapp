import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FS-7A (DEF-FS7-01): diálogo de contraseña para copias portátiles.
///
/// El widget es dueño de sus [TextEditingController] y los libera en
/// [dispose], cuando la ruta del diálogo ya terminó su animación de salida.
/// Liberarlos apenas `showDialog` retorna (mientras los `TextField` todavía
/// existen durante la transición) provoca
/// "A TextEditingController was used after being disposed" y la aserción
/// `_dependents.isEmpty` del framework.
class BackupPasswordDialog extends StatefulWidget {
  const BackupPasswordDialog({
    super.key,
    required this.title,
    required this.help,
    this.confirm = false,
  });

  final String title;
  final String help;
  final bool confirm;

  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _terracotta = Color(0xFFD03B1E);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _iconBadgeBg = Color(0xFFFFEBE3);

  /// Abre el diálogo y devuelve la contraseña confirmada, o `null` si se
  /// cancela. La validación de longitud mínima queda en el llamador.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String help,
    bool confirm = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) =>
          BackupPasswordDialog(title: title, help: help, confirm: confirm),
    );
  }

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _passwordError;
  String? _confirmationError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _continue() {
    final value = _passwordController.text;
    if (value.isEmpty) {
      setState(() {
        _passwordError = 'Escribe la contraseña.';
        _confirmationError = null;
      });
      return;
    }
    if (widget.confirm && value != _confirmationController.text) {
      setState(() {
        _passwordError = null;
        _confirmationError = 'Las contraseñas no coinciden.';
      });
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BackupPasswordDialog._iconBadgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.vpn_key_outlined,
              color: BackupPasswordDialog._primaryRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: BackupPasswordDialog._primaryText,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.help,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: BackupPasswordDialog._secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: BackupPasswordDialog._primaryText,
              ),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                errorText: _passwordError,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: BackupPasswordDialog._secondaryText,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: BackupPasswordDialog._secondaryText,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: BackupPasswordDialog._secondaryText,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: BackupPasswordDialog._cardBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: BackupPasswordDialog._cardBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: BackupPasswordDialog._accentOrange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (widget.confirm) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _confirmationController,
                obscureText: _obscureConfirmation,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: BackupPasswordDialog._primaryText,
                ),
                decoration: InputDecoration(
                  labelText: 'Repite la contraseña',
                  errorText: _confirmationError,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: BackupPasswordDialog._secondaryText,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_reset_outlined,
                    color: BackupPasswordDialog._secondaryText,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: BackupPasswordDialog._secondaryText,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: BackupPasswordDialog._cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: BackupPasswordDialog._cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: BackupPasswordDialog._accentOrange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BackupPasswordDialog._secondaryText,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                BackupPasswordDialog._terracotta,
                BackupPasswordDialog._accentOrange,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: BackupPasswordDialog._terracotta.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: _continue,
            child: Text(
              'Continuar',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
