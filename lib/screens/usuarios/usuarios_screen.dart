import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/usuario_controller.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/screens/usuarios/usuario_form_screen.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

/// Pantalla rediseñada de "Gestión de Usuarios" bajo Material Design 3,
/// con paleta cálida (#FBF9F5, #FF6A00, #D62828), tarjetas elevadas de 84-92px con
/// escala táctil (0.98x), badges de rol estilizados, menú popup moderno y FAB con degradado.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  // Paleta de diseño especificada
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _badgeBg = Color(0xFFFFEBE3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioController>().loadUsuarios();
    });
  }

  void _showRecuperarDialog(String email) {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El usuario no tiene correo registrado.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final code = context.read<UsuarioController>().simularEnvioRecuperacion(
      email,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: _primaryRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Restablecer Usuario',
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
          'Simulación: Se ha enviado el código temporal $code al correo $email.',
          style: GoogleFonts.poppins(fontSize: 13, color: _secondaryText),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Entendido',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarDarDeBaja(Usuario user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Dar de baja?',
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
          'El usuario "${user.nombre}" ya no podrá ingresar al sistema de KIMI PIZZA.',
          style: GoogleFonts.poppins(fontSize: 13, color: _secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: _secondaryText,
                fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Dar de baja',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ctrl = context.read<UsuarioController>();
      final res = await ctrl.darDeBaja(user.id!);
      if (!res && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ctrl.error ?? 'Error al dar de baja al usuario.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().currentUser;
    final isAdmin = currentUser?.rol == 'admin';

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: _bgScreen,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _primaryText, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Gestión de Usuarios',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          centerTitle: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFDC2626),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Acceso Restringido',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solo el administrador puede gestionar los usuarios del sistema.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<UsuarioController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: _bgScreen,
          // 2. AppBar integrado sin sombras rígidas
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _primaryText, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Gestión de Usuarios',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryText,
              ),
            ),
            centerTitle: false,
          ),
          // 1. Estructura con scroll suave
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _accentOrange),
                )
              : controller.usuarios.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: _badgeBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_outlined,
                                size: 40,
                                color: _primaryRed,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No hay usuarios registrados',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Añade personal y cajeros para que puedan iniciar sesión en la app.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _secondaryText,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_accentOrange, _primaryRed],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryRed.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const UsuarioFormScreen(),
                                    ),
                                  );
                                  if (mounted) controller.loadUsuarios();
                                },
                                icon: const Icon(
                                  Icons.person_add_alt_1,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  'Añadir Usuario',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                      itemCount: controller.usuarios.length,
                      itemBuilder: (context, index) {
                        final u = controller.usuarios[index];
                        final isBloqueado = u.bloqueado == 1;

                        return _UserCard(
                          user: u,
                          onTap: () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    UsuarioFormScreen(usuarioId: u.id),
                              ),
                            );
                            if (mounted) controller.loadUsuarios();
                          },
                          trailing: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _cardBorder.withValues(alpha: 0.6),
                              ),
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: _secondaryText,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              color: Colors.white,
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          UsuarioFormScreen(usuarioId: u.id),
                                    ),
                                  );
                                  if (mounted) controller.loadUsuarios();
                                } else if (val == 'block') {
                                  await controller.toggleBloqueo(
                                    u.id!,
                                    isBloqueado,
                                  );
                                } else if (val == 'delete') {
                                  _confirmarDarDeBaja(u);
                                } else if (val == 'reset') {
                                  _showRecuperarDialog(u.correo ?? '');
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Editar Datos',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'block',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isBloqueado
                                            ? Icons.lock_open_outlined
                                            : Icons.lock_outline,
                                        color: const Color(0xFFEA580C),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        isBloqueado
                                            ? 'Desbloquear'
                                            : 'Bloquear',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'reset',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.vpn_key_outlined,
                                        color: Color(0xFF7C3AED),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Restablecer clave',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Dar de baja',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          // 4. Botón Flotante de Acción (FAB) con degradado naranja-rojo
          floatingActionButton: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentOrange, _primaryRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _primaryRed.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UsuarioFormScreen(),
                    ),
                  );
                  if (mounted) {
                    controller.loadUsuarios();
                  }
                },
                child: const Center(
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta de usuario con altura de 84-92px, radio de 18px y microinteracción táctil (0.98x)
class _UserCard extends StatefulWidget {
  final Usuario user;
  final VoidCallback onTap;
  final Widget trailing;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.trailing,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isBloqueado = widget.user.bloqueado == 1;
    final hasPhoto = widget.user.fotoRuta != null &&
        File(widget.user.fotoRuta!).existsSync();

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isBloqueado
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isBloqueado
                  ? const Color(0xFFDC2626).withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
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
              setState(() => _isPressed = highlighted);
            },
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Avatar circular de 48px con borde blanco y sombra
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.file(
                              File(widget.user.fotoRuta!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildAvatarPlaceholder(isBloqueado),
                            )
                          : _buildAvatarPlaceholder(isBloqueado),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Información del usuario (Centro)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.user.nombre.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isBloqueado
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF1F2937),
                            decoration: isBloqueado
                                ? TextDecoration.lineThrough
                                : null,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Badge del Rol
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBE3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.user.rol.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE04F1D),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            if (isBloqueado) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'BLOQUEADO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            // Separador visual
                            const Text(
                              '·',
                              style: TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Correo electrónico
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline,
                                    size: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.user.correo?.isNotEmpty == true
                                          ? widget.user.correo!
                                          : 'Sin correo',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF6B7280),
                                      ),
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

                  // Acciones (Derecha): Botón de 3 puntos
                  widget.trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(bool isBloqueado) {
    return Container(
      color: isBloqueado ? const Color(0xFFFEE2E2) : const Color(0xFFFFEBE3),
      child: Center(
        child: Icon(
          Icons.person_outline,
          color:
              isBloqueado ? const Color(0xFFDC2626) : const Color(0xFFD62828),
          size: 26,
        ),
      ),
    );
  }
}
