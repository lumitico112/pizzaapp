import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/categoria_insumo_controller.dart';
import 'package:pizzaapp/screens/categorias/categorias_insumo_screen.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:pizzaapp/features/inventory/domain/services/unit_converter.dart';

/// Pantalla rediseñada de Formulario de Nuevo / Editar Insumo bajo Material Design 3,
/// con paleta cálida y funcional (verde bosque #1E4630 / #2E6F40, crema #FBF9F5),
/// media uploader centrado con borde punteado, campos estándar de 52px,
/// selector con botón circular (+) independiente y botón de guardado moderno de 52px.
class InsumoFormScreen extends StatefulWidget {
  final Insumo? insumoAEditar;

  const InsumoFormScreen({super.key, this.insumoAEditar});

  @override
  State<InsumoFormScreen> createState() => _InsumoFormScreenState();
}

class _InsumoFormScreenState extends State<InsumoFormScreen> {
  // Paleta de colores para insumos
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _appBarGreen = Color(0xFF1E4630);
  static const Color _accentGreen = Color(0xFF2E6F40);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textPlaceholder = Color(0xFF9CA3AF);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _uploaderBg = Color(0xFFFFF5F0);

  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  final _nombreCtrl = TextEditingController();
  final _stockMinimoCtrl = TextEditingController(text: '0.0');
  final _contenidoPaqueteCtrl = TextEditingController(text: '1');

  String? _categoriaSeleccionada;
  String _unidadSeleccionada = 'Kg';
  String _unidadStockMinimo = 'Kg';
  String? _imagePath;

  final List<String> _unidades = [
    'Kg',
    'gr',
    'Litros',
    'ml',
    'Paquetes',
    'Unidades',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaInsumoController>().loadCategorias();
    });

    if (widget.insumoAEditar != null) {
      final i = widget.insumoAEditar!;
      _nombreCtrl.text = i.nombre;
      _categoriaSeleccionada = i.tipoInsumo;
      if (_unidades.contains(i.unidadMedida)) {
        _unidadSeleccionada = i.unidadMedida;
      }
      _contenidoPaqueteCtrl.text = i.contenidoPaquete.toString();
      _unidadStockMinimo = _unidadMinimaPorDefecto(_unidadSeleccionada);
      var minimoMostrado = i.stockMinimo;
      if (i.stockMinimo > 0 && i.stockMinimo < 1) {
        final subUnidad = _subUnidadStock(_unidadSeleccionada);
        if (subUnidad != null) {
          _unidadStockMinimo = subUnidad;
          minimoMostrado = _convertirMinimo(
            i.stockMinimo,
            _codigoUnidad(_unidadSeleccionada),
            _codigoUnidad(subUnidad),
          );
        }
      }
      _stockMinimoCtrl.text = _formatearCantidad(minimoMostrado);
      _imagePath = i.fotoRuta;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _contenidoPaqueteCtrl.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto(bool desdeCamara) async {
    final path = desdeCamara
        ? await _imageService.pickImageFromCamera()
        : await _imageService.pickImageFromGallery();
    if (path != null && mounted) setState(() => _imagePath = path);
  }

  void _mostrarSelectorFoto() {
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
                'Foto del Insumo',
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
                    color: const Color(0xFFE2ECE6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: _accentGreen,
                  ),
                ),
                title: Text(
                  'Tomar con la Cámara',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFoto(true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: Text(
                  'Elegir de la Galería',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFoto(false);
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
                      color: Color(0xFFEF4444),
                    ),
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

  void _crearCategoria() async {
    final catController = context.read<CategoriaInsumoController>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoriasInsumoScreen()),
    );
    if (!mounted) return;
    catController.loadCategorias();
  }

  List<String> _opcionesUnidadStock(String unidadPedido) {
    switch (unidadPedido) {
      case 'Kg':
        return const ['Kg', 'gr'];
      case 'Litros':
        return const ['L', 'ml'];
      case 'Paquetes':
        return const ['Paq.', 'Unid.'];
      default:
        return const [];
    }
  }

  String? _subUnidadStock(String unidadPedido) {
    switch (unidadPedido) {
      case 'Kg':
        return 'gr';
      case 'Litros':
        return 'ml';
      case 'Paquetes':
        return 'Unid.';
      default:
        return null;
    }
  }

  String _unidadMinimaPorDefecto(String unidadPedido) {
    switch (unidadPedido) {
      case 'Kg':
        return 'Kg';
      case 'gr':
        return 'gr';
      case 'Litros':
        return 'L';
      case 'ml':
        return 'ml';
      case 'Paquetes':
        return 'Paq.';
      default:
        return 'Unid.';
    }
  }

  String _codigoUnidad(String unidad) {
    switch (unidad) {
      case 'L':
        return 'Litros';
      case 'Paq.':
        return 'Paquetes';
      case 'Unid.':
        return 'Unidades';
      default:
        return unidad;
    }
  }

  int get _contenidoPaquete =>
      (int.tryParse(_contenidoPaqueteCtrl.text) ?? 1).clamp(1, 1 << 31).toInt();

  double _convertirMinimo(double cantidad, String desde, String hasta) {
    if (_codigoUnidad(desde) == _codigoUnidad(hasta)) return cantidad;
    return UnitConverter.convert(
      cantidad,
      _codigoUnidad(desde),
      _codigoUnidad(hasta),
      packageContent: _contenidoPaquete,
    );
  }

  double _minimoEnUnidadPedido() {
    final cantidad =
        double.tryParse(_stockMinimoCtrl.text.replaceAll(',', '.')) ?? 0;
    return _convertirMinimo(
      cantidad,
      _unidadStockMinimo,
      _unidadMinimaPorDefecto(_unidadSeleccionada),
    );
  }

  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) {
      return cantidad.toInt().toString();
    }
    return cantidad.toString();
  }

  String? get _ayudaStockMinimo {
    if (_unidadStockMinimo == _unidadMinimaPorDefecto(_unidadSeleccionada)) {
      return null;
    }
    final cantidad = double.tryParse(
      _stockMinimoCtrl.text.replaceAll(',', '.'),
    );
    if (cantidad == null) return null;

    if (_unidadSeleccionada == 'Paquetes' && _unidadStockMinimo == 'Unid.') {
      return 'Alerta cuando queden ${_formatearCantidad(cantidad)} unidades o menos (de $_contenidoPaquete por paquete).';
    }
    final base = _convertirMinimo(
      cantidad,
      _unidadStockMinimo,
      _unidadMinimaPorDefecto(_unidadSeleccionada),
    );
    if (_unidadSeleccionada == 'Kg' && _unidadStockMinimo == 'gr') {
      return 'Alerta cuando queden ${_formatearCantidad(cantidad)} gr (${_formatearCantidad(base)} Kg) o menos.';
    }
    if (_unidadSeleccionada == 'Litros' && _unidadStockMinimo == 'ml') {
      return 'Alerta cuando queden ${_formatearCantidad(cantidad)} ml (${_formatearCantidad(base)} L) o menos.';
    }
    return null;
  }

  Widget _selectorUnidadStock() {
    final opciones = _opcionesUnidadStock(_unidadSeleccionada);
    final esSeleccionable = opciones.length > 1;
    final pill = Container(
      height: 36,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _unidadStockMinimo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E4630),
            ),
          ),
          if (esSeleccionable) ...[
            const SizedBox(width: 2),
            const Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: Color(0xFF1E4630),
            ),
          ],
        ],
      ),
    );

    if (!esSeleccionable) return pill;
    return PopupMenuButton<String>(
      tooltip: 'Unidad del stock mínimo',
      padding: EdgeInsets.zero,
      onSelected: (unidad) {
        final baseActual = _minimoEnUnidadPedido();
        setState(() {
          _unidadStockMinimo = unidad;
          _stockMinimoCtrl.text = _formatearCantidad(
            _convertirMinimo(
              baseActual,
              _unidadMinimaPorDefecto(_unidadSeleccionada),
              unidad,
            ),
          );
        });
      },
      itemBuilder: (context) => [
        for (final unidad in opciones)
          PopupMenuItem<String>(value: unidad, child: Text(unidad)),
      ],
      child: pill,
    );
  }

  Future<void> _guardarInsumo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecciona una categoría para el insumo',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final controller = context.read<InsumoController>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final success = await controller.guardarInsumo(
      id: widget.insumoAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      tipoInsumo: _categoriaSeleccionada!,
      unidadMedida: _unidadSeleccionada,
      stockMinimoText: _formatearCantidad(_minimoEnUnidadPedido())
          .replaceAll(',', '.'),
      rendimientoPorUnidadText: '1',
      contenidoPaquete: _unidadSeleccionada == 'Paquetes'
          ? (int.tryParse(_contenidoPaqueteCtrl.text) ?? 1)
          : 1,
      fotoRuta: _imagePath,
    );

    if (!mounted) return;

    if (success) {
      nav.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.insumoAEditar == null
                ? 'Insumo creado correctamente'
                : 'Insumo actualizado correctamente',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            controller.error ?? 'Error al guardar insumo',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: _textPlaceholder,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(prefixIcon, color: _accentGreen, size: 20),
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
        borderSide: const BorderSide(color: _accentGreen, width: 1.6),
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
    final isLoading = context.watch<InsumoController>().isLoading;
    final categorias = context.watch<CategoriaInsumoController>().categorias;

    if (_categoriaSeleccionada != null &&
        !categorias.any((c) => c.nombre == _categoriaSeleccionada)) {
      _categoriaSeleccionada = categorias.isNotEmpty
          ? categorias.first.nombre
          : null;
    }

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _appBarGreen,
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
          widget.insumoAEditar == null ? 'Nuevo Insumo' : 'Editar Insumo',
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
              // ÁREA DE IMAGEN DEL INSUMO (Media uploader centrado 100x100)
              // ----------------------------------------------------
              Center(
                child: GestureDetector(
                  onTap: _mostrarSelectorFoto,
                  child: CustomPaint(
                    painter: const _DashedBorderPainter(
                      color: _accentGreen,
                      strokeWidth: 1.5,
                      dash: 5.5,
                      gap: 4.0,
                      radius: 20.0,
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
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
                                    errorBuilder:
                                        (context, error, stackTrace) =>
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
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _accentGreen,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 12,
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
                                    size: 28,
                                    color: _accentGreen,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Foto del insumo',
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
              // CAMPO 1: NOMBRE DEL INSUMO
              // ----------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre del Insumo',
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
                      hintText: 'Ej: Piña, Queso, Harina',
                      prefixIcon: Icons.inventory_2_outlined,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // FILA 2: CATEGORÍA + BOTÓN CIRCULAR (+)
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
                        child: DropdownButtonFormField<String>(
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
                          items: categorias
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.nombre,
                                  child: Text(
                                    c.nombre,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _categoriaSeleccionada = val);
                            }
                          },
                          validator: (v) =>
                              v == null ? 'Selecciona una categoría' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _crearCategoria,
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _accentGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accentGreen.withValues(alpha: 0.35),
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
              // FILA 3: UNIDAD DE MEDIDA Y STOCK MÍNIMO (50% / 50%)
              // ----------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de Unidad (Izquierda)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Und. Pedido',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _unidadSeleccionada,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Unidad',
                            prefixIcon: Icons.scale_outlined,
                          ),
                          items: _unidades
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final minimoBase = _minimoEnUnidadPedido();
                              var minimoEnNuevaUnidad = minimoBase;
                              try {
                                minimoEnNuevaUnidad = _convertirMinimo(
                                  minimoBase,
                                  _unidadMinimaPorDefecto(_unidadSeleccionada),
                                  _unidadMinimaPorDefecto(val),
                                );
                              } on ArgumentError {
                                // Un cambio entre magnitudes incompatibles
                                // conserva el umbral numérico ingresado.
                              }
                              setState(() {
                                _unidadSeleccionada = val;
                                _unidadStockMinimo = _unidadMinimaPorDefecto(
                                  val,
                                );
                                _stockMinimoCtrl.text = _formatearCantidad(
                                  minimoEnNuevaUnidad,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Stock Mínimo (Derecha)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Mínimo',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockMinimoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                          decoration:
                              _buildInputDecoration(
                                hintText: '0.0',
                                prefixIcon: Icons.warning_amber_rounded,
                                suffixIcon: _selectorUnidadStock(),
                              ).copyWith(
                                suffixIconConstraints: const BoxConstraints(
                                  minHeight: 48,
                                  minWidth: 0,
                                ),
                              ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requerido';
                            }
                            final val = double.tryParse(v.replaceAll(',', '.'));
                            if (val == null || val < 0) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_ayudaStockMinimo != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _ayudaStockMinimo!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: _textMuted,
                    ),
                  ),
                ),
              ],

              // Campo condicional para Paquetes
              if (_unidadSeleccionada == 'Paquetes') ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contenido del Paquete (Unidades por paquete)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contenidoPaqueteCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: 12',
                        prefixIcon: Icons.widgets_outlined,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final parsed = int.tryParse(v ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Debe ser al menos 1';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // ----------------------------------------------------
              // ACCIÓN DE GUARDADO (BOTÓN DE ENVÍO DE 52PX)
              // ----------------------------------------------------
              _ScaleButton(
                onTap: isLoading ? () {} : _guardarInsumo,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _appBarGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _appBarGreen.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
                                widget.insumoAEditar == null
                                    ? 'GUARDAR INSUMO'
                                    : 'ACTUALIZAR INSUMO',
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

/// CustomPainter para bordes discontinuos redondeados
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dash = 5.5,
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
        final len = (distance + dash > metric.length)
            ? (metric.length - distance)
            : dash;
        dashPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
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
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
