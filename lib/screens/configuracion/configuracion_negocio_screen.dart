import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

/// Pantalla rediseñada de "Configuración del Negocio" bajo Material Design 3,
/// con paleta cálida (#FBF9F5, #FF6A00, #D03B1E), contenedor destacado para el QR
/// con marco morado para Yape/Plin, campos estilizados y microinteracciones táctiles.
class ConfiguracionNegocioScreen extends StatefulWidget {
  const ConfiguracionNegocioScreen({super.key});

  @override
  State<ConfiguracionNegocioScreen> createState() =>
      _ConfiguracionNegocioScreenState();
}

class _ConfiguracionNegocioScreenState
    extends State<ConfiguracionNegocioScreen> {
  // Paleta de diseño especificada
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _bodyMuted = Color(0xFF4B5563);
  static const Color _placeholderText = Color(0xFF9CA3AF);
  static const Color _inputBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _primaryRed = Color(0xFFD03B1E);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _purpleBrand = Color(0xFF7C3AED);
  static const Color _purpleLightBg = Color(0xFFF5F3FF);

  final _formKey = GlobalKey<FormState>();
  final _repository = ConfiguracionRepository();
  final _imageService = ImageService();

  final _nombreCtrl = TextEditingController();
  final _identificacionCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();

  String? _qrRuta;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  bool get _isAdmin =>
      context.read<AuthController>().currentUser?.rol == 'admin';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _identificacionCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isAdmin) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final values = await Future.wait([
        _repository.getConfig('nombre_negocio'),
        _repository.getConfig('ruc_dni'),
        _repository.getConfig('direccion_negocio'),
        _repository.getConfig('telefono_negocio'),
        _repository.getConfig('mensaje_ticket'),
        _repository.getConfig('qr_ventas_ruta'),
      ]);
      if (!mounted) return;
      _nombreCtrl.text = values[0] ?? '';
      _identificacionCtrl.text = values[1] ?? '';
      _direccionCtrl.text = values[2] ?? '';
      _telefonoCtrl.text = values[3] ?? '';
      _mensajeCtrl.text = values[4] ?? '';
      final savedQr = values[5];
      _qrRuta = savedQr != null && File(savedQr).existsSync() ? savedQr : null;
      setState(() {
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'No se pudo cargar la configuración del negocio.';
      });
    }
  }

  Future<void> _pickQr() async {
    final path = await _imageService.pickImageFromGallery();
    if (!mounted || path == null) return;
    try {
      final source = File(path);
      if (!await source.exists()) {
        _showMessage('No se encontró la imagen seleccionada.');
        return;
      }
      final documents = await getApplicationDocumentsDirectory();
      final directory = Directory('${documents.path}/configuracion');
      await directory.create(recursive: true);
      final extension = path.contains('.') ? path.split('.').last : 'jpg';
      final stored = await source.copy(
        '${directory.path}/qr_ventas_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      if (!mounted) return;
      setState(() => _qrRuta = stored.path);
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo guardar la imagen QR seleccionada.');
      }
    }
  }

  Future<void> _save() async {
    if (!_isAdmin) {
      _showMessage('Solo el administrador puede cambiar esta configuración.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final configs = <String, String>{
        'nombre_negocio': _nombreCtrl.text.trim(),
        'ruc_dni': _identificacionCtrl.text.trim(),
        'direccion_negocio': _direccionCtrl.text.trim(),
        'telefono_negocio': _telefonoCtrl.text.trim(),
        'mensaje_ticket': _mensajeCtrl.text.trim(),
        ...?(_qrRuta == null
            ? null
            : <String, String>{'qr_ventas_ruta': _qrRuta!}),
      };
      await _repository.saveConfigs(
        configs,
        deleteKeys: _qrRuta == null ? ['qr_ventas_ruta'] : const [],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada exitosamente.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('No se pudo guardar la configuración. Inténtalo de nuevo.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    int maxLines = 1,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: _placeholderText,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _inputBg,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: maxLines > 1 ? 16 : 14,
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bgScreen,
        body: Center(
          child: CircularProgressIndicator(color: _accentOrange),
        ),
      );
    }

    if (!_isAdmin) {
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
            'Configuración del negocio',
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
                  'Solo el administrador puede consultar o modificar la configuración del negocio.',
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

    final hasQr = _qrRuta != null && File(_qrRuta!).existsSync();

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
          'Configuración del negocio',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _primaryText,
          ),
        ),
        centerTitle: false,
      ),
      // 1. Estructura con scroll vertical suave (BouncingScrollPhysics)
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.error),
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Encabezados de Sección e Instrucción Superior
                    Text(
                      'Datos que aparecerán en las boletas y en el cobro por QR.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _bodyMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Formulario de Datos (Campos de Entrada)

                    // Fila 1: Nombre comercial / Razón social
                    _buildFieldLabel('Nombre comercial / Razón social'),
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: KIMI PIZZA',
                        prefixIcon: const Icon(
                          Icons.storefront_outlined,
                          color: _accentOrange,
                          size: 20,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'El nombre del negocio es obligatorio.'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Fila 2: RUC o DNI (opcional)
                    _buildFieldLabel('RUC o DNI (opcional)'),
                    TextFormField(
                      controller: _identificacionCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _primaryText,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: 10602462353',
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: _secondaryText,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fila 3: Dirección (opcional)
                    _buildFieldLabel('Dirección (opcional)'),
                    TextFormField(
                      controller: _direccionCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _primaryText,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: Alameda La Floresta',
                        prefixIcon: const Icon(
                          Icons.place_outlined,
                          color: _secondaryText,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fila 4: Teléfono de contacto (opcional)
                    _buildFieldLabel('Teléfono de contacto (opcional)'),
                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _primaryText,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: +51 947 816 385',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: _secondaryText,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fila 5: Mensaje al pie de la boleta (opcional, 64px)
                    _buildFieldLabel(
                      'Mensaje al pie de la boleta (opcional)',
                    ),
                    TextFormField(
                      controller: _mensajeCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: _primaryText,
                      ),
                      decoration: _buildInputDecoration(
                        hintText:
                            '¡Gracias por su preferencia! Vuelva Pronto.',
                        maxLines: 2,
                        prefixIcon: const Icon(
                          Icons.receipt_long_outlined,
                          color: _secondaryText,
                          size: 20,
                        ),
                      ),
                    ),

                    // 5. Tarjeta y Gestión del Código QR
                    const SizedBox(height: 24),
                    Text(
                      'Código QR de cobro',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Se mostrará cuando se seleccione Yape/Plin en el POS.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tarjeta Contenedora del QR
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _cardBorder, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Marco morado (dimensiones ~148x148) para albergar el QR de Yape/Plin
                          InkWell(
                            onTap: _pickQr,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                color: _purpleLightBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: hasQr
                                      ? _purpleBrand
                                      : _purpleBrand.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: hasQr
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_qrRuta!),
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _purpleBrand.withValues(
                                                  alpha: 0.15,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_2_outlined,
                                            size: 40,
                                            color: _purpleBrand,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Subir imagen QR',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _purpleBrand,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Toca para seleccionar',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: _secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Acciones de Gestión debajo del QR
                          if (hasQr) ...[
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Botón Quitar QR
                                Material(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () =>
                                        setState(() => _qrRuta = null),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            color: Color(0xFFDC2626),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Quitar QR',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Botón Cambiar Imagen
                                Material(
                                  color: _purpleLightBg,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: _pickQr,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.photo_library_outlined,
                                            color: _purpleBrand,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Cambiar imagen',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _purpleBrand,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 6. Botón de Acción Principal (Guardado)
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
                        onPressed: _saving ? null : _save,
                        child: _saving
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
                                    'Guardar cambios',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
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
}
