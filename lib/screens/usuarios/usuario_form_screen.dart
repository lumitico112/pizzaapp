import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/usuario_controller.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

/// Pantalla rediseñada de "Editar Usuario" / "Nuevo Usuario" bajo Material Design 3,
/// con paleta cálida (#FBF9F5, #FF6A00, #D03B1E), avatar con botón de cámara interactivo,
/// campos con microinteracciones y botón guardar con degradado.
class UsuarioFormScreen extends StatefulWidget {
  final int? usuarioId;
  const UsuarioFormScreen({super.key, this.usuarioId});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  // Paleta de diseño especificada
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _placeholderText = Color(0xFF9CA3AF);
  static const Color _inputBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _primaryRed = Color(0xFFD03B1E);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _badgeBg = Color(0xFFFFEBE3);

  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  final _nombreCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _rol = 'empleado';
  String? _fotoRuta;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _usernameCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    if (widget.usuarioId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final user = await context.read<UsuarioController>().getUsuario(
      widget.usuarioId!,
    );
    if (user != null && mounted) {
      _nombreCtrl.text = user.nombre;
      _usernameCtrl.text = user.username;
      _correoCtrl.text = user.correo ?? '';
      _rol = user.rol;
      _fotoRuta = user.fotoRuta;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final path = fromCamera
        ? await _imageService.pickImageFromCamera()
        : await _imageService.pickImageFromGallery();

    if (path != null && mounted) {
      setState(() => _fotoRuta = path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = context.read<UsuarioController>();
    final authCtrl = context.read<AuthController>();
    final isCreating = widget.usuarioId == null;

    setState(() => _isSaving = true);

    final success = await ctrl.guardarUsuario(
      id: widget.usuarioId,
      nombre: _nombreCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      rol: _rol,
      fotoRuta: _fotoRuta,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // Si se editó el usuario actual, actualizar la sesión de AuthController
      if (widget.usuarioId != null &&
          widget.usuarioId == authCtrl.currentUser?.id) {
        final updatedUser = await ctrl.getUsuario(widget.usuarioId!);
        if (updatedUser != null && mounted) {
          authCtrl.updateCurrentUser(updatedUser);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCreating
                  ? 'Usuario creado exitosamente.'
                  : 'Cambios guardados correctamente.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.error ?? 'Error al guardar usuario'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Foto de Perfil',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: _primaryRed,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Tomar foto con la cámara',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primaryText,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(true);
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: _primaryRed,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Elegir de la galería',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primaryText,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(false);
                },
              ),
              if (_fotoRuta != null) ...[
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Eliminar foto actual',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _fotoRuta = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _secondaryText,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: _placeholderText,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled ? _inputBg : const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentOrange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgScreen,
        body: Center(
          child: CircularProgressIndicator(color: _accentOrange),
        ),
      );
    }

    final currentUser = context.read<AuthController>().currentUser;
    final isAdmin = currentUser?.rol == 'admin';
    final isCreating = widget.usuarioId == null;
    final canManageRole =
        isAdmin && (isCreating || widget.usuarioId != currentUser?.id);
    final canEditBasicData = isAdmin || isCreating;

    final hasPhoto = _fotoRuta != null && _fotoRuta!.isNotEmpty;

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
          isCreating ? 'Nuevo Usuario' : 'Editar Usuario',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _primaryText,
          ),
        ),
        centerTitle: false,
      ),
      // 1. Estructura con scroll vertical suave (BouncingScrollPhysics)
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 3. Área del Avatar (Foto de Usuario)
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _mostrarOpcionesImagen,
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
                                  File(_fotoRuta!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildAvatarPlaceholder(),
                                )
                              : _buildAvatarPlaceholder(),
                        ),
                      ),
                    ),
                    // Botón de acción rápida (Cámara) con microinteracción
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _mostrarOpcionesImagen,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_accentOrange, _primaryRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withValues(alpha: 0.35),
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

              const SizedBox(height: 28),

              // 4. Formulario de Datos

              // Campo 1: Nombre Completo
              _buildFieldLabel('Nombre Completo'),
              TextFormField(
                controller: _nombreCtrl,
                enabled: canEditBasicData,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
                decoration: _buildInputDecoration(
                  hintText: 'Ej: Brighith Kiara Baquerizo Pérez',
                  enabled: canEditBasicData,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: _secondaryText,
                    size: 20,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Campo 2: Usuario (Login)
              _buildFieldLabel('Usuario (Login)'),
              TextFormField(
                controller: _usernameCtrl,
                enabled: canEditBasicData,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _primaryText,
                ),
                decoration: _buildInputDecoration(
                  hintText: 'Ej: brighith',
                  enabled: canEditBasicData,
                  prefixIcon: const Icon(
                    Icons.alternate_email,
                    color: _secondaryText,
                    size: 20,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Campo 3: Correo Electrónico
              _buildFieldLabel('Correo Electrónico'),
              TextFormField(
                controller: _correoCtrl,
                enabled: canEditBasicData,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _primaryText,
                ),
                decoration: _buildInputDecoration(
                  hintText: 'Ej: brighithkb@gmail.com',
                  enabled: canEditBasicData,
                  prefixIcon: const Icon(
                    Icons.mail_outline,
                    color: _secondaryText,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Rol (si aplica para gestión por admin)
              if (canManageRole) ...[
                _buildFieldLabel('Rol del Usuario'),
                DropdownButtonFormField<String>(
                  initialValue: _rol,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primaryText,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Selecciona un rol',
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: _secondaryText,
                      size: 20,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrador'),
                    ),
                    DropdownMenuItem(
                      value: 'empleado',
                      child: Text('Empleado (Cajero/Preparador)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _rol = v);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Campo 4: Nueva Contraseña
              _buildFieldLabel(
                isCreating ? 'Contraseña' : 'Nueva Contraseña (Opcional)',
              ),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _primaryText,
                ),
                decoration: _buildInputDecoration(
                  hintText: isCreating
                      ? 'Contraseña (mínimo 6 caracteres)'
                      : 'Nueva Contraseña (Opcional)',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: _secondaryText,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _secondaryText,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (isCreating && (v == null || v.isEmpty)) {
                    return 'Contraseña requerida';
                  }
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),

              // 5. Botón "GUARDAR CAMBIOS"
              const SizedBox(height: 28),
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryRed, _accentOrange],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryRed.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GUARDAR CAMBIOS',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(
          Icons.person_outline,
          color: Color(0xFF9CA3AF),
          size: 52,
        ),
      ),
    );
  }
}
