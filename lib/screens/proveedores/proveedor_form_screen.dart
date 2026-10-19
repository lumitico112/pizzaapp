import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/proveedor_controller.dart';
import 'package:pizzaapp/models/proveedor.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

class ProveedorFormScreen extends StatefulWidget {
  final Proveedor? proveedor;
  const ProveedorFormScreen({super.key, this.proveedor});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Paleta de marca
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _prefixBg = Color(0xFFFFF5F2);

  late final _nombreCtrl = TextEditingController(text: widget.proveedor?.nombre ?? '');
  late final _telCtrl = TextEditingController(text: widget.proveedor?.telefono ?? '');
  late final _emailCtrl = TextEditingController(text: widget.proveedor?.email ?? '');
  late final _dirCtrl = TextEditingController(text: widget.proveedor?.direccion ?? '');
  late final _notasCtrl = TextEditingController(text: widget.proveedor?.notas ?? '');

  bool _isSaving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _dirCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final p = Proveedor(
      id: widget.proveedor?.id,
      nombre: _nombreCtrl.text.trim(),
      telefono: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      direccion: _dirCtrl.text.trim().isEmpty ? null : _dirCtrl.text.trim(),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );

    final err = await context.read<ProveedorController>().guardarProveedor(p);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.proveedor == null
                      ? 'Proveedor registrado correctamente'
                      : 'Proveedor actualizado correctamente',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  err,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: err.contains('ya existe') ? AppColors.warning : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    bool alignTop = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _textMuted,
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _secondaryRed,
      ),
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.only(
          left: 10,
          right: 12,
          top: alignTop ? 12 : 8,
          bottom: alignTop ? 12 : 8,
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _prefixBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(prefixIcon, color: _secondaryRed, size: 20),
        ),
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: 58,
        minHeight: alignTop ? 58 : 48,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryOrange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllerLoading = context.watch<ProveedorController>().isLoading;
    final isLoading = _isSaving || controllerLoading;

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: Center(
          child: Material(
            color: Colors.white.withValues(alpha: 0.18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          widget.proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_secondaryRed, _primaryOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera de Sección
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _prefixBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.business_center_outlined,
                        color: _secondaryRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Datos del Proveedor',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Campo Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: 'Nombre o Razón Social *',
                    hintText: 'Ej. Distribuidora San Jorge',
                    prefixIcon: Icons.storefront_rounded,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 14),

                // Campo Teléfono
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: 'Teléfono / Celular',
                    hintText: 'Ej. 987 654 321',
                    prefixIcon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Correo electrónico
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'Ej. contacto@proveedor.com',
                    prefixIcon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Dirección
                TextFormField(
                  controller: _dirCtrl,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: 'Dirección física / Local',
                    hintText: 'Ej. Av. Los Sauces 124, Lima',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),

                // Campo Notas Adicionales
                TextFormField(
                  controller: _notasCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: 'Notas adicionales',
                    hintText: 'Condiciones de pago, días de entrega, horarios...',
                    prefixIcon: Icons.sticky_note_2_outlined,
                    alignTop: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 28),

                // Botón Guardar
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryOrange, _secondaryRed],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _secondaryRed.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isLoading ? null : _guardar,
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
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
                                    widget.proveedor == null
                                        ? 'Guardar Proveedor'
                                        : 'Actualizar Proveedor',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
