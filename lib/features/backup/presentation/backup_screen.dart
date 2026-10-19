import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/app/app_router.dart';
import 'package:pizzaapp/features/backup/application/backup_service.dart';
import 'package:pizzaapp/features/backup/presentation/widgets/backup_password_dialog.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

/// Pantalla rediseñada de "Copias de Seguridad" bajo Material Design 3,
/// con paleta cálida (#FBF9F5, #FF6A00, #D62828), microinteracciones táctiles (0.98x scale),
/// tarjetas informativas y diálogos modernos de alta confianza.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key, this.restorationOnly = false});

  final bool restorationOnly;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  // Paleta de diseño especificada
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _bodyMuted = Color(0xFF4B5563);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _iconBadgeBg = Color(0xFFFFEBE3);

  final _service = BackupService();
  bool _working = false;

  Future<void> _export() async {
    final password = await _requestPassword(
      title: 'Proteger copia portátil',
      confirm: true,
      help:
          'Usa una contraseña de al menos 12 caracteres. La necesitarás para restaurar la copia en este u otro móvil.',
    );
    if (password == null) return;
    await _run(
      () => _service.exportPortableBackup(password),
      success: 'Copia cifrada guardada. Conserva su contraseña por separado.',
    );
  }

  Future<void> _restorePortable() async {
    late final Uint8List bytes;
    try {
      bytes = await _service.readPickedBackup();
    } on BackupCancelledException {
      return;
    } catch (error) {
      _showError(_messageFor(error));
      return;
    }
    final password = await _requestPassword(
      title: 'Contraseña de la copia',
      help:
          'La restauración reemplazará los datos actuales. Antes se guardará una copia local de seguridad.',
    );
    if (password == null) return;
    final confirmed = await _confirmRestore();
    if (!confirmed) return;
    await _run(
      () => _service.restorePortableBackup(bytes, password),
      success:
          'Datos restaurados. La copia anterior quedó guardada en este móvil.',
      returnToDashboard: true,
    );
  }

  Future<void> _restoreLocal() async {
    final confirmed = await _confirmRestore(local: true);
    if (!confirmed) return;
    await _run(
      _service.restoreLatestLocalBackup,
      success: 'Se restauró la copia local más reciente.',
      returnToDashboard: true,
    );
  }

  Future<String?> _requestPassword({
    required String title,
    required String help,
    bool confirm = false,
  }) async {
    final password = await BackupPasswordDialog.show(
      context,
      title: title,
      help: help,
      confirm: confirm,
    );
    if (password == null) return null;
    if (confirm && password.runes.length < 12) {
      _showError(
        'La contraseña de la copia debe tener al menos 12 caracteres.',
      );
      return null;
    }
    return password;
  }

  Future<bool> _confirmRestore({bool local = false}) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reemplazar datos',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _primaryText,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              local
                  ? 'Se reemplazarán los datos con la copia automática más reciente de este móvil. Se creará un respaldo previo.'
                  : 'Se reemplazarán los datos actuales con los de la copia seleccionada. Se creará un respaldo previo.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _secondaryText,
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _secondaryText,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'Restaurar',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _run(
    Future<void> Function() operation, {
    required String success,
    bool returnToDashboard = false,
  }) async {
    setState(() => _working = true);
    try {
      await operation();
      if (!mounted) return;
      if (returnToDashboard) {
        try {
          context.read<PosController>().limpiarCarrito();
        } catch (_) {}
        final auth = context.read<AuthController>();
        final navigator = Navigator.of(context);
        await auth.logout();
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (mounted) _showError(_messageFor(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _messageFor(Object error) {
    if (error is BackupCancelledException) return 'Operación cancelada.';
    if (error is BackupPasswordPolicyException) {
      return 'La contraseña de la copia debe tener al menos 12 caracteres.';
    }
    if (error is BackupPasswordException) {
      return 'La contraseña no es correcta.';
    }
    if (error is BackupNotFoundException) {
      return 'Todavía no hay una copia automática local disponible.';
    }
    if (error is BackupFormatException) return error.message;
    return 'No se pudo completar la operación. Revisa el espacio disponible e inténtalo de nuevo.';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      // 2. AppBar integrado sin sombras rígidas
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Semantics(
          button: true,
          label: 'Volver',
          child: IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back, color: _primaryText, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Copias de seguridad',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _primaryText,
          ),
        ),
        centerTitle: false,
      ),
      // 1. Estructura con scroll suave
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. Encabezado de Sección con Icono de Candado / Seguridad
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _iconBadgeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: _primaryRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tus datos se guardan cifrados en este móvil. Para cambiar de móvil, exporta una copia portátil y conserva su contraseña en otro lugar.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _bodyMuted,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Tarjetas de Acción (Sección Central)

                // Tarjeta 1: Exportar copia portátil
                if (!widget.restorationOnly)
                  _BackupActionCard(
                    icon: Icons.upload_file,
                    title: 'Exportar copia para transferir',
                    description:
                        'Guarda un archivo cifrado que puedes mover a otro móvil o a una computadora.',
                    onTap: _working ? null : _export,
                  ),

                // Tarjeta 2: Restaurar desde un archivo portátil
                _BackupActionCard(
                  icon: Icons.folder_open_outlined,
                  title: 'Restaurar desde un archivo',
                  description:
                      'Abre una copia portátil. Los datos actuales se reemplazarán después de confirmar.',
                  onTap: _working ? null : _restorePortable,
                ),

                // Tarjeta 3: Restaurar copia automática local
                if (!widget.restorationOnly)
                  _BackupActionCard(
                    icon: Icons.history,
                    title: 'Restaurar copia automática local',
                    description:
                        'Recupera la copia diaria más reciente de este móvil.',
                    onTap: _working ? null : _restoreLocal,
                  ),

                // 5. Pie de Pantalla (Información Adicional / Advertencia)
                if (!widget.restorationOnly) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: _secondaryText,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'La app conserva hasta siete copias automáticas locales. Si pierdes el móvil, solo podrás recuperar los datos desde una copia portátil que hayas guardado fuera del dispositivo.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Overlay de carga moderno con Backdrop Blur
          if (_working)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: _accentOrange,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Procesando copia de seguridad...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
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
    );
  }
}

/// Tarjeta de acción interactiva con microinteracción de escala táctil (0.98x)
class _BackupActionCard extends StatefulWidget {
  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  State<_BackupActionCard> createState() => _BackupActionCardState();
}

class _BackupActionCardState extends State<_BackupActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: '${widget.title}. ${widget.description}',
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: const Color(0xFFFF6A00).withValues(alpha: 0.08),
            highlightColor: const Color(0xFFFF6A00).withValues(alpha: 0.04),
            onHighlightChanged: (highlighted) {
              if (widget.onTap != null) {
                setState(() => _isPressed = highlighted);
              }
            },
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icono en contenedor circular pastel (44px x 44px)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBE3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFFD62828),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Textos (Título y Subtítulo)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.description,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF6B7280),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Icono de flecha
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF9CA3AF),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
