import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/promocion_controller.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/services/image_service.dart';

/// Formulario rediseñado para Nueva/Editar Promoción bajo Material Design 3.
/// Incorpora banner uploader con borde punteado, selector interactivo de días,
/// tarjetas de horarios de aplicación, sección moderna de productos incluidos
/// y botón de acción con degradado corporativo y microinteracción táctil.
class PromocionFormScreen extends StatefulWidget {
  final Promocion? promocionAEditar;

  const PromocionFormScreen({super.key, this.promocionAEditar});

  @override
  State<PromocionFormScreen> createState() => _PromocionFormScreenState();
}

class _PromocionItemUI {
  final PromocionItem item;
  final String nombreProducto;
  final String nombreVariante;

  _PromocionItemUI({
    required this.item,
    required this.nombreProducto,
    required this.nombreVariante,
  });
}

class _PromocionFormScreenState extends State<PromocionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Paleta de colores corporativa
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  final List<String> _diasSemana = ['1', '2', '3', '4', '5', '6', '7'];
  final List<String> _diasLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  final List<String> _diasSeleccionados = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String? _imagePath;

  List<_PromocionItemUI> _items = [];
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoController>().loadProductos();
    });

    if (widget.promocionAEditar != null) {
      final p = widget.promocionAEditar!;
      _nombreCtrl.text = p.nombre;
      _precioCtrl.text = p.precio.toStringAsFixed(2);
      _descripcionCtrl.text = p.descripcion ?? '';
      _imagePath = p.imagenRuta;
      if (p.diasSemana != null && p.diasSemana!.isNotEmpty) {
        _diasSeleccionados.addAll(p.diasSemana!.split(',').map((e) => e.trim()));
      }
      if (p.horaInicio != null && p.horaInicio!.isNotEmpty) {
        final parts = p.horaInicio!.split(':');
        if (parts.length == 2) {
          _horaInicio = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      if (p.horaFin != null && p.horaFin!.isNotEmpty) {
        final parts = p.horaFin!.split(':');
        if (parts.length == 2) {
          _horaFin = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      _items = p.items
          .map(
            (e) => _PromocionItemUI(
              item: e,
              nombreProducto: e.insumoId != null
                  ? 'Insumo ${e.insumoId}'
                  : 'Producto ${e.varianteId}',
              nombreVariante: e.insumoId != null ? 'Insumo' : 'Variante',
            ),
          )
          .toList();
    } else {
      // Por defecto todos los días seleccionados
      _diasSeleccionados.addAll(['1', '2', '3', '4', '5', '6', '7']);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _selectTime(bool isInicio) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isInicio ? _horaInicio : _horaFin) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final imageService = ImageService();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Foto de la Promoción',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: _secondaryRed,
                  ),
                ),
                title: Text(
                  'Tomar foto con la cámara',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await imageService.pickImageFromCamera();
                  if (path != null && mounted) {
                    setState(() => _imagePath = path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: _primaryOrange,
                  ),
                ),
                title: Text(
                  'Seleccionar de la galería',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await imageService.pickImageFromGallery();
                  if (path != null && mounted) {
                    setState(() => _imagePath = path);
                  }
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  title: Text(
                    'Eliminar imagen',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _agregarProducto() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AgregarProducto',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: const _AgregarProductoDialog(),
            ),
          ),
        );
      },
    ).then((result) {
      if (result != null && result is _PromocionItemUI) {
        setState(() {
          _items.add(result);
        });
      }
    });
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione al menos un día de vigencia'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregue al menos un producto o insumo a la promoción'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final p = Promocion(
      id: widget.promocionAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      precio: double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0.0,
      descripcion: _descripcionCtrl.text.trim(),
      imagenRuta: _imagePath,
      diasSemana: _diasSeleccionados.join(','),
      horaInicio: _formatTime(_horaInicio),
      horaFin: _formatTime(_horaFin),
      activa: widget.promocionAEditar?.activa ?? 1,
    );

    final success = await context.read<PromocionController>().guardarPromocion(
      p,
      _items.map((e) => e.item).toList(),
    );
    if (mounted && success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promoción guardada exitosamente'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } else if (mounted) {
      final error =
          context.read<PromocionController>().error ??
          'No se pudo guardar la promoción.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required Widget prefixIcon,
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _secondaryRed,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _textMuted,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
    final isEditing = widget.promocionAEditar != null;

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Editar Promoción' : 'Nueva Promoción',
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 2. Área de Imagen Promocional (Banner Uploader con DashedBorder)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: _primaryOrange,
                      strokeWidth: 1.5,
                      radius: 18,
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  color: Colors.black26,
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.photo_camera_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Cambiar imagen',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFEBE3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: _secondaryRed,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subir foto o banner de la promoción',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Campos de Información Principal
              TextFormField(
                controller: _nombreCtrl,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
                decoration: _buildInputDecoration(
                  labelText: 'Nombre de Promoción',
                  hintText: 'ej. 2x1 Pizza Americana',
                  prefixIcon: const Icon(
                    Icons.local_offer_outlined,
                    color: _secondaryRed,
                    size: 22,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
                decoration: _buildInputDecoration(
                  labelText: 'Precio Total (S/)',
                  prefixText: 'S/ ',
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: _secondaryRed,
                    size: 22,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _textDark,
                ),
                decoration: _buildInputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Detalles de la oferta, términos o condiciones',
                  prefixIcon: const Icon(
                    Icons.notes_rounded,
                    color: _textMuted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Selector Interactivo de Días de la Semana
              Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    size: 18,
                    color: _secondaryRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Días de la semana:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_diasSemana.length, (index) {
                  final dia = _diasSemana[index];
                  final isSelected = _diasSeleccionados.contains(dia);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _diasSeleccionados.remove(dia);
                        } else {
                          _diasSeleccionados.add(dia);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [_primaryOrange, _secondaryRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: _cardBorder, width: 1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      _primaryOrange.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _diasLabels[index],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : _textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),

              // 5. Selector de Horario de Aplicación
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: _secondaryRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Horario de Aplicación:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Hora Inicio
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(true),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: _primaryOrange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _horaInicio == null
                                    ? 'Hora Inicio'
                                    : _formatTime(_horaInicio),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: _horaInicio != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _horaInicio != null
                                      ? _textDark
                                      : _textMuted,
                                ),
                              ),
                            ),
                            if (_horaInicio != null)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _horaInicio = null),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Hora Fin
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(false),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: _secondaryRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _horaFin == null
                                    ? 'Hora Fin'
                                    : _formatTime(_horaFin),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: _horaFin != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _horaFin != null
                                      ? _textDark
                                      : _textMuted,
                                ),
                              ),
                            ),
                            if (_horaFin != null)
                              GestureDetector(
                                onTap: () => setState(() => _horaFin = null),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Sección Productos Incluidos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Productos Incluidos',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _agregarProducto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFCDD2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: _secondaryRed,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+ Añadir Producto',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _secondaryRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contenedor de Lista / Estado Vacío
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.fastfood_outlined,
                          size: 32,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay productos en esta promoción.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final uiItem = _items[index];
                    final isIngrediente = uiItem.item.insumoId != null;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isIngrediente
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFFFF1ED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isIngrediente
                                  ? Icons.inventory_2_outlined
                                  : Icons.restaurant_menu_rounded,
                              size: 18,
                              color: isIngrediente
                                  ? const Color(0xFFEA580C)
                                  : _secondaryRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${uiItem.nombreProducto} · ${uiItem.nombreVariante}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1ED),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Cantidad: ${uiItem.item.cantidad}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _secondaryRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _items.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 28),

              // 7. Botón Principal ("Guardar Promoción")
              SafeArea(
                top: false,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isButtonPressed = true),
                  onTapUp: (_) => setState(() => _isButtonPressed = false),
                  onTapCancel: () => setState(() => _isButtonPressed = false),
                  child: AnimatedScale(
                    scale: _isButtonPressed ? 0.98 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
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
                            color: _primaryOrange.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: context.watch<PromocionController>().isLoading
                              ? null
                              : _guardar,
                          child: Center(
                            child: context.watch<PromocionController>().isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Guardar Promoción',
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter para el borde punteado moderno del Banner Uploader
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 18,
  });

  static const double dashWidth = 6.0;
  static const double dashSpace = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

/// Diálogo rediseñado para añadir producto o insumo al combo
class _AgregarProductoDialog extends StatefulWidget {
  const _AgregarProductoDialog();

  @override
  State<_AgregarProductoDialog> createState() =>
      _AgregarProductoDialogState();
}

class _AgregarProductoDialogState extends State<_AgregarProductoDialog> {
  bool _includeIngredient = false;
  int? _selectedIngredientId;
  Producto? _selectedProducto;
  VarianteProducto? _selectedVariante;
  final _cantidadCtrl = TextEditingController(text: '1');
  List<VarianteProducto> _variantes = [];
  bool _isLoadingVariantes = false;

  Future<void> _loadVariantes(Producto producto) async {
    setState(() {
      _isLoadingVariantes = true;
      _selectedVariante = null;
    });
    final variantes = await context.read<ProductoController>().obtenerVariantes(
      producto.id!,
    );
    if (mounted) {
      setState(() {
        _variantes = variantes;
        _isLoadingVariantes = false;
        if (_variantes.isNotEmpty) {
          _selectedVariante = _variantes.first;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
    });
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Consumer<ProductoController>(
          builder: (context, ctrl, _) {
            if (ctrl.isLoading) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Añadir a la Promoción',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selector Segmentado de Tipo
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _includeIngredient = false;
                              _selectedIngredientId = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: !_includeIngredient
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_includeIngredient
                                    ? [
                                        const BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Producto',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: !_includeIngredient
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: !_includeIngredient
                                        ? const Color(0xFFD62828)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _includeIngredient = true;
                              _selectedProducto = null;
                              _selectedVariante = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: _includeIngredient
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _includeIngredient
                                    ? [
                                        const BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Insumo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: _includeIngredient
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: _includeIngredient
                                        ? const Color(0xFFD62828)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_includeIngredient) ...[
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Insumo',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      items: context
                          .watch<InsumoController>()
                          .insumos
                          .where((i) => i.activo == 1)
                          .map(
                            (i) => DropdownMenuItem(
                              value: i.id,
                              child: Text('${i.nombre} (${i.unidadMedida})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedIngredientId = value),
                    ),
                  ] else ...[
                    DropdownButtonFormField<Producto>(
                      decoration: InputDecoration(
                        labelText: 'Producto',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      initialValue: _selectedProducto,
                      items: ctrl.productos
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedProducto = val);
                          _loadVariantes(val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingVariantes)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      ),
                    if (!_isLoadingVariantes && _selectedProducto != null)
                      DropdownButtonFormField<VarianteProducto>(
                        decoration: InputDecoration(
                          labelText: 'Variante / Tamaño',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        initialValue: _selectedVariante,
                        items: _variantes
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.nombreVariante),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedVariante = val),
                      ),
                  ],
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6A00), Color(0xFFD62828)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              final cant = int.tryParse(_cantidadCtrl.text);
                              if (cant == null || cant < 1) return;
                              if (_includeIngredient &&
                                  _selectedIngredientId != null) {
                                final ingredient = context
                                    .read<InsumoController>()
                                    .insumos
                                    .firstWhere(
                                      (i) => i.id == _selectedIngredientId,
                                    );
                                Navigator.pop(
                                  context,
                                  _PromocionItemUI(
                                    item: PromocionItem(
                                      promocionId: 0,
                                      insumoId: _selectedIngredientId,
                                      cantidad: cant,
                                    ),
                                    nombreProducto: ingredient.nombre,
                                    nombreVariante: 'Insumo',
                                  ),
                                );
                              } else if (_selectedProducto != null &&
                                  _selectedVariante != null) {
                                Navigator.pop(
                                  context,
                                  _PromocionItemUI(
                                    item: PromocionItem(
                                      promocionId: 0,
                                      varianteId: _selectedVariante!.id!,
                                      cantidad: cant,
                                    ),
                                    nombreProducto: _selectedProducto!.nombre,
                                    nombreVariante:
                                        _selectedVariante!.nombreVariante,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Añadir',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
