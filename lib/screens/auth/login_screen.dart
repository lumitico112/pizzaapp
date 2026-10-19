import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/core/storage/secure_auth_store.dart';
import 'package:pizzaapp/screens/dashboard/dashboard_screen.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/features/backup/presentation/backup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _logoRuta;
  String? _fondoRuta;
  String _nombreNegocio = '';
  bool _isLoadingConfig = true;
  bool _obscurePassword = true;
  bool _recordarUsuario = false;
  bool _huellaDisponible = false;
  bool _puedeEntrarConHuella = false;
  bool _usarHuella = false;
  bool _entrandoConHuella = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _cargarUsuarioRecordado();
    _cargarEstadoHuella();
  }

  Future<void> _loadConfig() async {
    final repo = ConfiguracionRepository();
    _logoRuta = await repo.getConfig('logo_ruta');
    _fondoRuta = await repo.getConfig('fondo_login_ruta');
    _nombreNegocio = await repo.getConfig('nombre_negocio') ?? '';
    if (!mounted) return;
    setState(() {
      _isLoadingConfig = false;
    });
  }

  /// Autocompleta el usuario recordado (solo el nombre; nunca la contraseña).
  /// Si el almacén seguro no está disponible, el login continúa sin prefill.
  Future<void> _cargarUsuarioRecordado() async {
    final controller = context.read<AuthController>();
    UsuarioRecordado? recordado;
    try {
      recordado = await controller.leerUsuarioRecordado();
    } catch (_) {
      return;
    }
    if (!mounted || recordado == null) return;
    final username = recordado.username;
    setState(() {
      _usernameController.text = username;
      _recordarUsuario = true;
    });
  }

  /// Consulta si el dispositivo puede ofrecer el acceso rápido con huella y
  /// si ya está habilitado para el usuario recordado (FS-11). Cualquier fallo
  /// (p. ej., plugin ausente en escritorio) oculta la opción.
  Future<void> _cargarEstadoHuella() async {
    final controller = context.read<AuthController>();
    bool disponible = false;
    bool puede = false;
    try {
      disponible = await controller.huellaDisponible();
      puede = disponible && await controller.puedeEntrarConHuella();
    } catch (_) {
      disponible = false;
      puede = false;
    }
    if (!mounted) return;
    setState(() {
      _huellaDisponible = disponible;
      _puedeEntrarConHuella = puede;
      _usarHuella = puede;
    });
  }

  /// Acceso rápido: pide la huella y, si es aceptada, entra sin contraseña.
  /// Ante cualquier rechazo se permanece en el login con contraseña.
  Future<void> _entrarConHuella() async {
    final controller = context.read<AuthController>();
    setState(() => _entrandoConHuella = true);
    final success = await controller.entrarConHuella();
    if (!mounted) return;
    setState(() => _entrandoConHuella = false);
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      return;
    }
    final error = controller.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
    await _cargarEstadoHuella();
  }

  void _login() async {
    final controller = context.read<AuthController>();
    final success = await controller.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      try {
        await controller.actualizarUsuarioRecordado(
          _recordarUsuario,
          usarHuella: _usarHuella,
        );
      } catch (_) {
        // La persistencia del usuario recordado no debe bloquear el acceso.
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Credenciales incorrectas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPassword() {
    // El login queda debajo del diálogo. Quitarle el foco antes de abrirlo
    // evita que el IME restaure un campo de la ruta anterior al cerrar el modal.
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context)
        .push<void>(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 360),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, _, _) =>
                _RecoveryPasswordPage(backgroundPath: _fondoRuta),
            transitionsBuilder: (_, animation, _, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.035),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          ),
        )
        .then((_) {
          // El Future de showDialog termina cuando la ruta modal ya fue retirada.
          // Desenfocar aquí cubre tanto Cancelar como el botón Atrás del sistema.
          if (mounted) {
            _usernameFocusNode.unfocus();
            _passwordFocusNode.unfocus();
          }
        });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final isLoading = context.watch<AuthController>().isLoading;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _WarmPhotoBackground(imagePath: _fondoRuta, blur: 7),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 46,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BrandHeader(
                        logoPath: _logoRuta,
                        title: _nombreNegocio.trim().isEmpty
                            ? 'PIZZAPP'
                            : _nombreNegocio.toUpperCase(),
                      ),
                      SizedBox(height: screenHeight < 700 ? 22 : 34),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xF7FFFDFA),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 28,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Ingresa tus datos para continuar.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _AuthInput(
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              hint: 'Usuario',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _passwordFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 15),
                            _AuthInput(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              hint: 'Contraseña',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => isLoading ? null : _login(),
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF9CA3AF),
                                  size: 20,
                                ),
                              ),
                            ),
                            CheckboxListTile(
                              value: _recordarUsuario,
                              onChanged: (value) => setState(() {
                                _recordarUsuario = value ?? false;
                                if (!_recordarUsuario) _usarHuella = false;
                              }),
                              title: const Text(
                                'Recordar usuario',
                                style: TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFFD62828),
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            if (_huellaDisponible && _recordarUsuario)
                              CheckboxListTile(
                                value: _usarHuella,
                                onChanged: (value) => setState(
                                  () => _usarHuella = value ?? false,
                                ),
                                title: const Text(
                                  'Entrar con huella',
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Acceso rápido sin escribir la contraseña.',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                activeColor: const Color(0xFFD62828),
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPassword,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFD62828),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _GradientActionButton(
                              label: 'ENTRAR',
                              icon: Icons.arrow_forward_rounded,
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _login,
                            ),
                            if (_puedeEntrarConHuella) ...[
                              const SizedBox(height: 6),
                              Center(
                                child: TextButton.icon(
                                  onPressed: (isLoading || _entrandoConHuella)
                                      ? null
                                      : _entrarConHuella,
                                  icon: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 22,
                                  ),
                                  label: const Text('Entrar con huella'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFB9432E),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 17),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'o',
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade300,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BackupScreen(
                                      restorationOnly: true,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.restore_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Restaurar una copia en este móvil',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFB9432E),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

class _WarmPhotoBackground extends StatelessWidget {
  const _WarmPhotoBackground({required this.imagePath, this.blur = 0});

  final String? imagePath;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && File(imagePath!).existsSync();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Image.file(File(imagePath!), fit: BoxFit.cover),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF54271D),
                  Color(0xFF9D4928),
                  Color(0xFF211C1A),
                ],
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x990F172A), Color(0x66111A23), Color(0xBB0F172A)],
            ),
          ),
        ),
        Positioned(
          right: -70,
          top: -95,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6A00).withValues(alpha: 0.18),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.logoPath, required this.title});

  final String? logoPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath != null && File(logoPath!).existsSync();
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF211C1A).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: hasLogo
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(File(logoPath!), fit: BoxFit.cover),
                )
              : const Icon(
                  Icons.local_pizza_rounded,
                  color: Color(0xFFFF8A32),
                  size: 43,
                ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            shadows: [Shadow(color: Color(0x88000000), blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'El verdadero sabor en cada bocado',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.84),
            fontSize: 14,
            shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 21),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onPressed == null
                ? const [Color(0xFFB7A49A), Color(0xFF9E8981)]
                : const [Color(0xFFFF6A00), Color(0xFFD62828)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: onPressed == null
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x44FF6A00),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 10),
                          Icon(icon, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La pantalla posee sus controladores hasta terminar su ciclo de vida.
class _RecoveryPasswordPage extends StatefulWidget {
  const _RecoveryPasswordPage({required this.backgroundPath});

  final String? backgroundPath;

  @override
  State<_RecoveryPasswordPage> createState() => _RecoveryPasswordPageState();
}

class _RecoveryPasswordPageState extends State<_RecoveryPasswordPage> {
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_isSubmitting) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    final error = await context.read<AuthController>().resetAdminPassword(
      username: _usernameController.text,
      recoveryCode: _codeController.text,
      newPassword: _passwordController.text,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _WarmPhotoBackground(imagePath: widget.backgroundPath, blur: 7),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.94),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Volver al inicio de sesión',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.fromLTRB(23, 27, 23, 23),
                        decoration: BoxDecoration(
                          color: const Color(0xF7FFFDFA),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 26,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Recuperar contraseña',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Usa la clave de rescate que guardaste al configurar la app. No se envía ningún correo.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _RecoveryInput(
                              controller: _usernameController,
                              label: 'Usuario administrador',
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 14),
                            _RecoveryInput(
                              controller: _codeController,
                              label: 'Clave de rescate',
                              icon: Icons.key_outlined,
                            ),
                            const SizedBox(height: 14),
                            _RecoveryInput(
                              controller: _passwordController,
                              label: 'Nueva contraseña (mínimo 8 caracteres)',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                            ),
                            const SizedBox(height: 14),
                            _RecoveryInput(
                              controller: _confirmController,
                              label: 'Repite la contraseña',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFD62828),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GradientActionButton(
                                    label: 'Restablecer',
                                    isLoading: _isSubmitting,
                                    onPressed: _isSubmitting
                                        ? null
                                        : _resetPassword,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _RecoveryInput extends StatelessWidget {
  const _RecoveryInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1.5),
          ),
        ),
      ),
    );
  }
}
