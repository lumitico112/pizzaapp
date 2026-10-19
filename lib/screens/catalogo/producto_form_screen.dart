import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/categoria_producto_controller.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:pizzaapp/screens/categorias/categorias_screen.dart';

/// Estado de controladores para cada variante / tamaño del producto
class VariantControllerState {
  int? id;
  int? baseVariantId;
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  String? imagePath;

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    costCtrl.dispose();
  }
}

/// Pantalla rediseñada de Formulario de Nuevo / Editar Producto
/// bajo Material Design 3, paleta cálida (#FBF9F5, #FF6A00, #D62828),
/// media uploader centrado con borde punteado, microinteracciones táctiles
/// y tarjetas elevadas para tamaños / variantes.
class ProductoFormScreen extends StatefulWidget {
  final Producto? productoAEditar;

  const ProductoFormScreen({super.key, this.productoAEditar});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  // Paleta de colores cálida y coherente con la marca Kimi Pizza
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _deepRed = Color(0xFFD03B1E);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _uploaderBg = Color(0xFFFFF5F0);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textPlaceholder = Color(0xFF9CA3AF);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _categoriaSeleccionada;
  String _tipoPreparacion = 'anticipado';
  String? _imagePath;
  bool _derivado = false;
  int? _productoBaseId;
  List<VarianteProducto> _variantesBase = [];

  final List<VariantControllerState> _variantesCtrl = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaProductoController>().loadCategorias();
      context.read<InsumoController>().loadInsumos();
      context.read<ProductoController>().loadProductos();
    });

    if (widget.productoAEditar != null) {
      final p = widget.productoAEditar!;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion ?? '';
      _categoriaSeleccionada = p.categoriaId;
      _tipoPreparacion = p.tipoPreparacion;
      _imagePath = p.fotoRuta;
      _derivado = p.derivaDeProductoId != null;
      _productoBaseId = p.derivaDeProductoId;
      _cargarVariantes(p.id!);
      if (p.derivaDeProductoId != null) {
        _cargarVariantesBase(p.derivaDeProductoId!);
      }
    } else {
      _addVariant(); // Al menos 1 variante inicial
    }
  }

  Future<void> _cargarVariantes(int productId) async {
    final vars = await context.read<ProductoController>().obtenerVariantes(
          productId,
        );
    if (!mounted) return;
    setState(() {
      if (vars.isEmpty) {
        _addVariant();
      } else {
        for (var v in vars) {
          final vc = VariantControllerState();
          vc.id = v.id;
          vc.baseVariantId = v.varianteBaseId;
          vc.nameCtrl.text = v.nombreVariante;
          vc.priceCtrl.text = v.precioVenta.toString();
          vc.costCtrl.text = v.costoEstimadoManual.toString();
          vc.imagePath = v.imagen;
          _variantesCtrl.add(vc);
        }
      }
    });
  }

  Future<void> _cargarVariantesBase(int id) async {
    final variants = await context.read<ProductoController>().obtenerVariantes(
          id,
        );
    if (mounted) setState(() => _variantesBase = variants);
  }

  Future<void> _seleccionarProductoBase(int? id) async {
    setState(() {
      _productoBaseId = id;
      _variantesBase = [];
    });
    if (id == null) return;
    final variants = await context.read<ProductoController>().obtenerVariantes(
          id,
        );
    if (!mounted) return;
    setState(() {
      _variantesBase = variants;
      for (final target in _variantesCtrl) {
        final match = variants.where(
          (v) =>
              v.nombreVariante.toLowerCase() ==
              target.nameCtrl.text.trim().toLowerCase(),
        );
        target.baseVariantId ??= match.isEmpty ? null : match.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    for (var v in _variantesCtrl) {
      v.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() => _variantesCtrl.add(VariantControllerState()));
  }

  void _removeVariant(int index) {
    if (_variantesCtrl.length <= 1) return;
    setState(() {
      _variantesCtrl[index].dispose();
      _variantesCtrl.removeAt(index);
    });
  }

  Future<void> _tomarFotoPrincipal(bool desdeCamara) async {
    final path = desdeCamara
        ? await _imageService.pickImageFromCamera()
        : await _imageService.pickImageFromGallery();
    if (path != null && mounted) setState(() => _imagePath = path);
  }

  Future<void> _tomarFotoVariante(int index, bool desdeCamara) async {
    final path = desdeCamara
        ? await _imageService.pickImageFromCamera()
        : await _imageService.pickImageFromGallery();
    if (path != null && mounted) {
      setState(() => _variantesCtrl[index].imagePath = path);
    }
  }

  void _mostrarSelectorFotoPrincipal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Foto del Producto',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                ),
                title: Text(
                  'Tomar con la Cámara',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFotoPrincipal(true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: _accentOrange),
                ),
                title: Text(
                  'Elegir de la Galería',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFotoPrincipal(false);
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
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  ),
                  title: Text(
                    'Eliminar Foto',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
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

  void _mostrarSelectorFotoVariante(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Foto del Tamaño / Variante',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                ),
                title: Text(
                  'Tomar con la Cámara',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFotoVariante(index, true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: _accentOrange),
                ),
                title: Text(
                  'Elegir de la Galería',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFotoVariante(index, false);
                },
              ),
              if (_variantesCtrl[index].imagePath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  ),
                  title: Text(
                    'Eliminar Foto de Variante',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _variantesCtrl[index].imagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_variantesCtrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Agrega al menos una variante (ej: Personal o Único)',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _primaryRed,
        ),
      );
      return;
    }

    final prod = Producto(
      id: widget.productoAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      categoriaId: _categoriaSeleccionada,
      tipoPreparacion: _tipoPreparacion,
      fotoRuta: _imagePath,
      activo: 1,
      derivaDeProductoId: _derivado ? _productoBaseId : null,
    );

    List<VarianteProducto> vars = [];
    for (var vc in _variantesCtrl) {
      vars.add(
        VarianteProducto(
          productoId: widget.productoAEditar?.id ?? 0,
          nombreVariante: vc.nameCtrl.text.trim(),
          precioVenta: double.tryParse(vc.priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
          costoEstimadoManual: double.tryParse(vc.costCtrl.text.replaceAll(',', '.')) ?? 0.0,
          imagen: vc.imagePath,
          id: vc.id,
          varianteBaseId: _derivado ? vc.baseVariantId : null,
        ),
      );
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final success = await context
        .read<ProductoController>()
        .guardarProductoCompleto(producto: prod, variantes: vars);

    if (!mounted) return;
    if (success) {
      nav.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.productoAEditar == null
                ? 'Producto registrado correctamente'
                : 'Producto actualizado correctamente',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.read<ProductoController>().error ?? 'Error al guardar producto',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: _textPlaceholder,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(prefixIcon, color: _accentOrange, size: 20),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: _textDark,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentOrange, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catCtrl = context.watch<CategoriaProductoController>();
    final prodCtrl = context.watch<ProductoController>();

    if (_categoriaSeleccionada != null &&
        !catCtrl.categorias.any((c) => c.id == _categoriaSeleccionada)) {
      _categoriaSeleccionada = null;
    }

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _accentOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_outlined,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Volver',
        ),
        title: Text(
          widget.productoAEditar == null ? 'Nuevo Producto' : 'Editar Producto',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------------
              // ÁREA DE IMAGEN DEL PRODUCTO (Media uploader centrado 110x110)
              // ----------------------------------------------------
              Center(
                child: GestureDetector(
                  onTap: _mostrarSelectorFotoPrincipal,
                  child: CustomPaint(
                    painter: const _DashedBorderPainter(
                      color: _accentOrange,
                      strokeWidth: 1.6,
                      dash: 6.0,
                      gap: 4.5,
                      radius: 20.0,
                    ),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: _uploaderBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _imagePath != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: _textMuted,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: _primaryRed,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 32,
                                    color: _primaryRed,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Foto del producto',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ----------------------------------------------------
              // CAMPO 1: NOMBRE DEL PRODUCTO
              // ----------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre del Producto',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nombreCtrl,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    decoration: _buildInputDecoration(
                      hintText: 'Ej: Pizza Americana',
                      prefixIcon: Icons.local_pizza_outlined,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // SECCIÓN CONDICIONAL: ESTE PRODUCTO DERIVA DE OTRO
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Este producto deriva de otro',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Comparte el inventario o físico con el producto base.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _derivado,
                          activeThumbColor: _accentOrange,
                          activeTrackColor: _accentOrange.withValues(alpha: 0.35),
                          onChanged: (val) {
                            setState(() {
                              _derivado = val;
                              if (!val) {
                                _productoBaseId = null;
                                _variantesBase = [];
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_derivado) ...[
                      const SizedBox(height: 12),
                      const Divider(color: _cardBorder, height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'Producto Base',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: prodCtrl.productos.any(
                          (p) =>
                              p.id == _productoBaseId &&
                              p.id != widget.productoAEditar?.id,
                        )
                            ? _productoBaseId
                            : null,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Seleccionar producto base...',
                          prefixIcon: Icons.link_rounded,
                        ),
                        items: prodCtrl.productos
                            .where(
                              (p) =>
                                  p.id != widget.productoAEditar?.id &&
                                  p.derivaDeProductoId == null,
                            )
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _seleccionarProductoBase,
                        validator: (v) => _derivado && v == null
                            ? 'Selecciona el producto base'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cada variante comparte el saldo de una variante base. Su receta puede agregar insumos propios.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // CAMPO 2: DESCRIPCIÓN (OPCIONAL)
              // ----------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descripción (Opcional)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    minLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Escribe una breve descripción del producto...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _textPlaceholder,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 28),
                        child: Icon(
                          Icons.description_outlined,
                          color: _accentOrange,
                          size: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _cardBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _accentOrange, width: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // FILA 3: CATEGORÍA + BOTÓN CIRCULAR (+)
              // ----------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categoría',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _categoriaSeleccionada,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Seleccionar categoría...',
                            prefixIcon: Icons.category_outlined,
                          ),
                          items: catCtrl.categorias.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.nombre,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _textDark,
                                ),
                              ),
                            ),
                          ).toList(),
                          onChanged: (val) =>
                              setState(() => _categoriaSeleccionada = val),
                          validator: (v) =>
                              v == null ? 'Selecciona una categoría' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () async {
                          final catController =
                              context.read<CategoriaProductoController>();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriasScreen(),
                            ),
                          );
                          if (!mounted) return;
                          catController.loadCategorias();
                        },
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _primaryRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // FILA 4: ¿CÓMO SE CONTROLA EL INVENTARIO?
              // ----------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo se controla el inventario?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoPreparacion,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    decoration: _buildInputDecoration(
                      hintText: 'Tipo de inventario',
                      prefixIcon: Icons.inventory_2_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'anticipado',
                        child: Text('Preparado previamente'),
                      ),
                      DropdownMenuItem(
                        value: 'momento',
                        child: Text('Preparado al momento'),
                      ),
                      DropdownMenuItem(
                        value: 'ambos',
                        child: Text('Usar stock y preparar faltantes'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _tipoPreparacion = val);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tipoPreparacion == 'anticipado'
                        ? 'Descuenta unidades preparadas del stock de cada variante.'
                        : _tipoPreparacion == 'momento'
                            ? 'Descuenta automáticamente los insumos definidos en la receta de cada variante.'
                            : 'Usa primero el stock preparado disponible; los faltantes se descuentan de su receta.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ----------------------------------------------------
              // SECCIÓN: TAMAÑOS / VARIANTES
              // ----------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'TAMAÑOS / VARIANTES',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ej: "Personal, Familiar". Si solo hay un tamaño, escribe "Único".',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Listado de Tarjetas de Variantes
              ..._variantesCtrl.asMap().entries.map((entry) {
                final index = entry.key;
                final vc = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Si es producto derivado: selector de variante base
                      if (_derivado) ...[
                        DropdownButtonFormField<int>(
                          initialValue: _variantesBase.any(
                            (v) => v.id == vc.baseVariantId,
                          )
                              ? vc.baseVariantId
                              : null,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Comparte stock con...',
                            prefixIcon: Icons.share_location_outlined,
                          ),
                          items: _variantesBase
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v.id,
                                  child: Text(v.nombreVariante),
                                ),
                              )
                              .toList(),
                          onChanged: (id) =>
                              setState(() => vc.baseVariantId = id),
                          validator: (value) => _derivado && value == null
                              ? 'Selecciona la variante base'
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Row superior: Foto cuadrada + Nombre de variante + Botón eliminar
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _mostrarSelectorFotoVariante(index),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _uploaderBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _accentOrange.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                image: vc.imagePath != null
                                    ? DecorationImage(
                                        image: FileImage(File(vc.imagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: vc.imagePath == null
                                  ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: _primaryRed,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: vc.nameCtrl,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nombre de variante',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _textPlaceholder,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _accentOrange),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                          if (_variantesCtrl.length > 1) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _removeVariant(index),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Row inferior: Precio Venta (S/)
                      TextFormField(
                        controller: vc.priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _textPlaceholder,
                          ),
                          prefixIcon: const Icon(
                            Icons.payments_outlined,
                            color: _accentOrange,
                            size: 18,
                          ),
                          prefixText: 'S/ ',
                          prefixStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _accentOrange),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          final num = double.tryParse(v.replaceAll(',', '.'));
                          if (num == null || num < 0) return 'Precio inválido';
                          return null;
                        },
                      ),
                    ],
                  ),
                );
              }),

              // Botón "Agregar otro tamaño/variante" (46px con borde discontinuo)
              _DashedButton(
                onTap: _addVariant,
                label: 'Agregar otro tamaño/variante',
              ),
              const SizedBox(height: 28),

              // ----------------------------------------------------
              // ACCIÓN DE GUARDADO (BOTÓN DE ENVÍO DE 52PX CON DEGRADADO)
              // ----------------------------------------------------
              _ScaleButton(
                onTap: prodCtrl.isLoading ? () {} : _guardarProducto,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_deepRed, _accentOrange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _accentOrange.withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: prodCtrl.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.productoAEditar == null
                                    ? 'REGISTRAR PRODUCTO'
                                    : 'GUARDAR CAMBIOS',
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
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter para dibujar bordes punteados/discontinuos redondeados
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dash = 6.0,
    this.gap = 4.0,
    this.radius = 20.0,
  });

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
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len =
            (distance + dash > metric.length) ? (metric.length - distance) : dash;
        dashPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap ||
      oldDelegate.radius != radius;
}

/// Botón con borde discontinuo fino y microinteracción táctil
class _DashedButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _DashedButton({required this.onTap, required this.label});

  @override
  State<_DashedButton> createState() => _DashedButtonState();
}

class _DashedButtonState extends State<_DashedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFFF6A00);
    const textColor = Color(0xFFD62828);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: CustomPaint(
          painter: const _DashedBorderPainter(
            color: borderColor,
            strokeWidth: 1.4,
            dash: 5.0,
            gap: 4.0,
            radius: 14.0,
          ),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: _isPressed
                  ? const Color(0xFFFFF5F0)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_rounded,
                  color: textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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

/// Microinteracción táctil de escala suave
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
