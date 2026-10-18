import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/screens/auth/login_screen.dart';
import 'package:pizzaapp/screens/usuarios/usuario_form_screen.dart';

/// Pantalla rediseñada de "Mi Perfil" con Material Design 3,
/// paleta cálida de marca, jerarquía tipográfica optimizada y accesos directos.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  // Paleta de diseño solicitada
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _terracotta = Color(0xFFD03B1E);
  static const Color _badgeBg = Color(0xFFFFEBE3);
  static const Color _badgeText = Color(0xFFE04F1D);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _dividerColor = Color(0xFFE5E7EB);
  static const Color _logoutBg = Color(0xFFFEE2E2);
  static const Color _logoutBorder = Color(0xFFFCA5A5);
  static const Color _logoutRed = Color(0xFFDC2626);

  Future<void> _showRecoveryCode(BuildContext context) async {
    final auth = context.read<AuthController>();
    final code = await auth.generateRecoveryCode();
    if (!context.mounted || code == null) return;

    await showDialog<void>(
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
              child: const Icon(Icons.vpn_key_outlined, color: _terracotta, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Clave de Rescate',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guarda este código en un lugar seguro fuera de este dispositivo. Solo se muestra una vez y reemplaza cualquier clave anterior:',
              style: GoogleFonts.poppins(fontSize: 13, color: _secondaryText),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _dividerColor, width: 1.2),
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _terracotta,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _confirmarCerrarSesion(BuildContext context, AuthController auth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Cerrar Sesión?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: _primaryText),
        ),
        content: Text(
          'Tendrás que volver a ingresar tus credenciales para acceder a KIMI PIZZA.',
          style: GoogleFonts.poppins(fontSize: 13, color: _secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: _secondaryText, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _logoutRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              try {
                context.read<PosController>().limpiarCarrito();
              } catch (_) {}
              auth.logout();
              Navigator.pushAndRemoveUntil<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _bgScreen,
        body: Center(
          child: Text(
            'No hay una sesión activa.',
            style: GoogleFonts.poppins(fontSize: 16, color: _secondaryText),
          ),
        ),
      );
    }

    final isAdmin = user.rol.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: _bgScreen,
      // 2. AppBar integrado sin sombras rígidas ni botón "Back" superpuesto
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryText, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mi perfil',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _primaryText,
          ),
        ),
        centerTitle: false,
      ),
      // 1. Estructura y Scroll Suave
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 3. Sección del Usuario (Cabecera de Perfil)
            _buildProfileHeader(context, user, isAdmin),

            const SizedBox(height: 28),

            // 4. Tarjeta Contenedora de Opciones del Menú
            _buildOptionsCard(context, user, isAdmin),

            const SizedBox(height: 24),

            // 5. Botón de Cerrar Sesión con Gran Visibilidad
            _buildLogoutButton(context, auth),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Cabecera con Foto de Perfil, Botón rápido de cámara, Nombre, @username, Badge y Correo
  Widget _buildProfileHeader(BuildContext context, dynamic user, bool isAdmin) {
    final hasPhoto = user.fotoRuta != null && user.fotoRuta!.isNotEmpty;

    return Column(
      children: [
        // Avatar circular grande (104px) con borde blanco y sombra difusa
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => UsuarioFormScreen(usuarioId: user.id),
                    ),
                  );
                },
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? Image.file(
                            File(user.fotoRuta!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAvatarPlaceholder(),
                          )
                        : _buildAvatarPlaceholder(),
                  ),
                ),
              ),
              // Botón de acción rápida con icono de cámara
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UsuarioFormScreen(usuarioId: user.id),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _terracotta,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _terracotta.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nombre Completo en Poppins Bold 20sp
        Text(
          user.nombre.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _primaryText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),

        // @username en Poppins Regular 14sp
        Text(
          '@${user.username}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: _secondaryText,
          ),
        ),
        const SizedBox(height: 8),

        // Rol / Badge dentro de píldora con fondo naranja suave
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: _badgeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.rol.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _badgeText,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // Correo electrónico con icono sutil de email
        if (user.correo?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mail_outline,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                user.correo!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Tarjeta blanca con bordes redondeados (radio 20px) y opciones separadas por divisor
  Widget _buildOptionsCard(BuildContext context, dynamic user, bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Opción 1: Editar mis datos
          _buildOptionTile(
            icon: Icons.edit_outlined,
            iconColor: _terracotta,
            title: 'Editar mis datos',
            subtitle: 'Nombre, foto y datos de acceso',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UsuarioFormScreen(usuarioId: user.id),
                ),
              );
            },
          ),

          // Divisor
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: _dividerColor, height: 1, thickness: 1),
          ),

          // Opción 2: Renovar clave de rescate (para admin)
          if (isAdmin) ...[
            _buildOptionTile(
              icon: Icons.vpn_key_outlined,
              iconColor: _terracotta,
              title: user.recoveryCode == null
                  ? 'Configurar clave de rescate'
                  : 'Renovar clave de rescate',
              subtitle: 'Asegura el acceso a tu cuenta',
              onTap: () => _showRecoveryCode(context),
            ),
          ],
        ],
      ),
    );
  }

  /// Fila individual de opción con icono pastel a la izquierda y flecha chevron
  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // Icono dentro de un círculo con fondo pastel
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 14),

              // Textos: Título y Subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha de navegación derecha
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 5. Botón de Cerrar Sesión con fondo rojo suave, borde fino y diseño prominente
  Widget _buildLogoutButton(BuildContext context, AuthController auth) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _logoutBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _logoutBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _logoutRed.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _confirmarCerrarSesion(context, auth),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  color: _logoutRed,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Cerrar sesión',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _logoutRed,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFFFEBE3),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 52,
          color: _terracotta,
        ),
      ),
    );
  }
}
