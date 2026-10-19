import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/assets/domain/entities/asset.dart';
import 'package:pizzaapp/features/assets/presentation/controllers/asset_controller.dart';
import 'package:pizzaapp/controllers/categoria_activo_controller.dart';
import 'package:pizzaapp/screens/categorias/categorias_activo_screen.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';

class ActivoFijoFormScreen extends StatefulWidget {
  final ActivoFijo? activoAEditar;

  const ActivoFijoFormScreen({super.key, this.activoAEditar});

  @override
  State<ActivoFijoFormScreen> createState() => _ActivoFijoFormScreenState();
}

class _ActivoFijoFormScreenState extends State<ActivoFijoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  String? _categoriaSeleccionada;
  final _costoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _valorUnitarioCtrl = TextEditingController();
  final _adelantoCtrl = TextEditingController(text: '0');
  final _cuotasCtrl = TextEditingController(text: '1');

  String _estado = 'En uso';
  final List<String> _estados = [
    'En uso',
    'En reparación',
    'Fuera de servicio',
  ];

  String _condicion = 'Comprado';
  final List<String> _condiciones = [
    'Comprado',
    'Alquilado',
    'Prestado',
    'Regalado',
  ];

  String _metodoPago = 'Contado';
  final List<String> _metodosPago = ['Contado', 'Crédito'];

  String? _frecuenciaAlquiler = 'Mensual';
  final List<String> _frecuencias = ['Diario', 'Mensual', 'Anual'];

  String? _fotoRuta;
  DateTime _fechaAdquisicion = DateTime.now();

  bool _isCalculating = false;

  // Paleta de diseño solicitada
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryRed = Color(0xFFA8220A);
  static const Color _terracotta = Color(0xFFD03B1E);
  static const Color _orangeAccent = Color(0xFFFF6A00);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _photoBg = Color(0xFFF5EFE6);
  static const Color _photoText = Color(0xFF5C544B);

  void _calcularCostoTotal() {
    if (_isCalculating) return;
    _isCalculating = true;
    final condicionValida =
        _condicion == 'Prestado' || _condicion == 'Alquilado';
    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (condicionValida && cantidad > 1) {
      final valorUnitario = double.tryParse(_valorUnitarioCtrl.text) ?? 0;
      if (valorUnitario > 0) {
        _costoCtrl.text = (valorUnitario * cantidad).toStringAsFixed(2);
      }
    }
    _isCalculating = false;
  }

  @override
  void initState() {
    super.initState();
    _cantidadCtrl.addListener(() {
      setState(() {});
      _calcularCostoTotal();
    });
    _valorUnitarioCtrl.addListener(_calcularCostoTotal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaActivoController>().loadCategorias();
    });
    if (widget.activoAEditar != null) {
      final a = widget.activoAEditar!;
      _nombreCtrl.text = a.nombre;
      _categoriaSeleccionada = a.categoria;
      if (a.costo > 0) _costoCtrl.text = a.costo.toString();
      _obsCtrl.text = a.observaciones ?? '';

      if (_estados.contains(a.estado)) _estado = a.estado;
      if (_condiciones.contains(a.condicion)) _condicion = a.condicion;
      if (_metodosPago.contains(a.metodoPago)) _metodoPago = a.metodoPago;
      if (_frecuencias.contains(a.frecuenciaAlquiler)) {
        _frecuenciaAlquiler = a.frecuenciaAlquiler;
      }

      _cuotasCtrl.text = a.cuotas.toString();
      _cantidadCtrl.text = a.cantidad.toString();

      _fotoRuta = a.fotoRuta;
      if (a.fechaAdquisicion != null && a.fechaAdquisicion!.isNotEmpty) {
        _fechaAdquisicion =
            DateTime.tryParse(a.fechaAdquisicion!) ?? DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _costoCtrl.dispose();
    _obsCtrl.dispose();
    _cantidadCtrl.dispose();
    _valorUnitarioCtrl.dispose();
    _adelantoCtrl.dispose();
    _cuotasCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    double costo = 0;
    if (_condicion == 'Comprado' ||
        _condicion == 'Alquilado' ||
        _condicion == 'Prestado') {
      costo = double.tryParse(_costoCtrl.text) ?? 0;
      if ((_condicion == 'Comprado' || _condicion == 'Alquilado') &&
          costo <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese un costo válido')),
        );
        return;
      }
    }

    int cuotas = 1;
    if (_condicion == 'Comprado' && _metodoPago == 'Crédito') {
      cuotas = int.tryParse(_cuotasCtrl.text) ?? 1;
      if (cuotas <= 0) cuotas = 1;
    }

    int cantidad = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (cantidad <= 0) cantidad = 1;

    final ctrl = context.read<ActivoFijoController>();
    double adelanto = double.tryParse(_adelantoCtrl.text) ?? 0;

    final ok = await ctrl.guardarActivo(
      id: widget.activoAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoriaSeleccionada ?? 'Sin Categoría',
      costo: costo,
      fechaAdquisicion: AppDateUtils.formatStorage(_fechaAdquisicion),
      estado: _estado,
      condicion: _condicion,
      metodoPago: _metodoPago,
      cuotas: cuotas,
      cantidad: cantidad,
      frecuenciaAlquiler: _condicion == 'Alquilado'
          ? _frecuenciaAlquiler
          : null,
      observaciones: _obsCtrl.text.trim(),
      fotoRuta: _fotoRuta,
      adelanto: adelanto,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ctrl.error ?? 'Error al guardar')));
    }
  }

  Future<void> _seleccionarFoto() async {
    final imageService = ImageService();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                'Seleccionar Foto del Activo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _terracotta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: _terracotta),
                ),
                title: Text(
                  'Tomar con la cámara',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await imageService.pickImageFromCamera();
                  if (path != null && mounted) {
                    setState(() => _fotoRuta = path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: _orangeAccent),
                ),
                title: Text(
                  'Elegir de la galería',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await imageService.pickImageFromGallery();
                  if (path != null && mounted) {
                    setState(() => _fotoRuta = path);
                  }
                },
              ),
              if (_fotoRuta != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error),
                  ),
                  title: Text(
                    'Eliminar foto',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _fotoRuta = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoReparacion(BuildContext context) {
    final costoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Registrar Reparación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esto registrará un gasto en la caja de hoy y cambiará el estado a "En reparación".',
              style: GoogleFonts.poppins(fontSize: 13, color: _textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: costoCtrl,
              decoration: InputDecoration(
                labelText: 'Costo (S/)',
                prefixIcon: const Icon(Icons.payments_outlined, color: _terracotta),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Detalle del arreglo',
                prefixIcon: const Icon(Icons.edit_note_outlined, color: _terracotta),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: _textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final costo = double.tryParse(costoCtrl.text) ?? 0;
              if (costo > 0) {
                Navigator.pop(ctx);
                final ok = await context
                    .read<ActivoFijoController>()
                    .registrarReparacion(
                      widget.activoAEditar!,
                      costo,
                      descCtrl.text.trim(),
                    );
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Reparación y Gasto registrados',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  setState(() {
                    _estado = 'En reparación';
                  });
                }
              }
            },
            child: Text(
              'Confirmar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activoAEditar != null;

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _terracotta],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEditing ? 'Editar Activo' : 'Nuevo Activo',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.cleaning_services_outlined, color: _terracotta),
                            title: Text(
                              'Limpiar formulario',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _nombreCtrl.clear();
                                _costoCtrl.clear();
                                _obsCtrl.clear();
                                _cantidadCtrl.text = '1';
                                _fotoRuta = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Consumer<ActivoFijoController>(
        builder: (context, ctrl, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 3. Área de Carga de Imagen (Foto del Activo)
                  Center(child: _buildImagePicker()),
                  const SizedBox(height: 22),

                  // Fila 1 (Nombre y Cantidad)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del Activo (73% de ancho aprox)
                      Expanded(
                        flex: 73,
                        child: _buildTextField(
                          controller: _nombreCtrl,
                          label: 'Nombre del activo',
                          hint: 'Nombre del activo',
                          prefixIcon: Icons.inventory_2_outlined,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Cant. (27% de ancho aprox)
                      Expanded(
                        flex: 27,
                        child: _buildCantidadStepper(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Fila 2 (Categoría)
                  _buildCategoriaRow(),
                  const SizedBox(height: 15),

                  // Fila 3 (Condición y Estado)
                  Row(
                    children: [
                      // Condición (50%)
                      Expanded(
                        child: _buildDropdownSelector(
                          label: 'Condición',
                          value: _condicion,
                          items: _condiciones,
                          icon: Icons.shopping_bag_outlined,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _condicion = val;
                                _calcularCostoTotal();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Estado (50%)
                      Expanded(
                        child: _buildDropdownSelector(
                          label: 'Estado',
                          value: _estado,
                          items: _estados,
                          icon: Icons.check_circle_outline,
                          onChanged: (val) {
                            if (val != null) setState(() => _estado = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Subcampos si es Alquilado o Prestado
                  if (_condicion == 'Alquilado') ...[
                    _buildDropdownSelector(
                      label: 'Frecuencia de alquiler',
                      value: _frecuenciaAlquiler ?? 'Mensual',
                      items: _frecuencias,
                      icon: Icons.repeat,
                      onChanged: (val) => setState(() => _frecuenciaAlquiler = val),
                    ),
                    const SizedBox(height: 15),
                  ],

                  if ((_condicion == 'Prestado' || _condicion == 'Alquilado') &&
                      (int.tryParse(_cantidadCtrl.text) ?? 1) > 1) ...[
                    _buildTextField(
                      controller: _valorUnitarioCtrl,
                      label: 'Valor por unidad (Opcional)',
                      hint: '0.00',
                      prefixText: 'S/ ',
                      prefixIcon: Icons.calculate_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // Fila 4 (Costo)
                  if (_condicion == 'Comprado' ||
                      _condicion == 'Alquilado' ||
                      _condicion == 'Prestado') ...[
                    _buildTextField(
                      controller: _costoCtrl,
                      label: _condicion == 'Comprado'
                          ? 'Costo Total de Adquisición'
                          : (_condicion == 'Alquilado'
                              ? 'Costo de Alquiler'
                              : 'Valor Total Estimado (Opcional)'),
                      hint: '0.00',
                      prefixText: 'S/ ',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (_condicion == 'Prestado') return null;
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Ingrese un costo válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                  ],

                  // Fila 5 (Método de Pago si es Comprado)
                  if (_condicion == 'Comprado') ...[
                    _buildDropdownSelector(
                      label: 'Método de Pago',
                      value: _metodoPago,
                      items: _metodosPago,
                      icon: Icons.account_balance_wallet_outlined,
                      onChanged: (val) {
                        if (val != null) setState(() => _metodoPago = val);
                      },
                    ),
                    if (_metodoPago == 'Crédito') ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cuotasCtrl,
                              label: 'Cuotas',
                              hint: '1',
                              prefixIcon: Icons.tag,
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _adelantoCtrl,
                              label: 'Adelanto',
                              hint: '0.00',
                              prefixText: 'S/ ',
                              prefixIcon: Icons.monetization_on_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 15),
                  ],

                  // Fila 6 (Fecha de Registro)
                  _buildDatePickerTile(),
                  const SizedBox(height: 15),

                  // Fila 7 (Observaciones)
                  _buildObservacionesField(),
                  const SizedBox(height: 26),

                  // 5. Acción de Guardado (Botón de Registro)
                  _buildSaveButton(ctrl.isLoading, isEditing),

                  if (isEditing) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.build_circle_outlined, size: 20),
                      label: Text(
                        'REGISTRAR GASTO DE REPARACIÓN',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () => _mostrarDialogoReparacion(context),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES REDISEÑADOS CON MATERIAL 3 ---

  /// Contenedor de Carga de Imagen cuadrado (110px x 110px, radio 20px)
  Widget _buildImagePicker() {
    final hasPhoto = _fotoRuta != null && _fotoRuta!.isNotEmpty;

    return Center(
      child: GestureDetector(
        onTap: _seleccionarFoto,
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: _photoBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasPhoto ? _terracotta : const Color(0xFFD7CCC8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasPhoto)
                  Image.file(
                    File(_fotoRuta!),
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderPhoto(),
                  )
                else
                  _buildPlaceholderPhoto(),
                if (hasPhoto)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _terracotta,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 13,
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

  Widget _buildPlaceholderPhoto() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_outlined,
          size: 32,
          color: _terracotta,
        ),
        const SizedBox(height: 6),
        Text(
          'Foto del activo',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _photoText,
          ),
        ),
      ],
    );
  }

  /// Campo de Texto Estándar (52px, radio 14px, fondo blanco, contorno ligero)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textDark,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: GoogleFonts.poppins(fontSize: 13, color: _textMuted),
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _terracotta, size: 21) : null,
          prefixText: prefixText,
          prefixStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  /// Stepper compacto para Cantidad con botones táctiles + y -
  Widget _buildCantidadStepper() {
    final currentQty = int.tryParse(_cantidadCtrl.text) ?? 1;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cant.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  if (currentQty > 1) {
                    _cantidadCtrl.text = (currentQty - 1).toString();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.remove, size: 14, color: _textDark),
                ),
              ),
              Expanded(
                child: Text(
                  _cantidadCtrl.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  _cantidadCtrl.text = (currentQty + 1).toString();
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _terracotta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 14, color: _terracotta),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Fila de Categoría con Selector y Botón circular (+) independiente
  Widget _buildCategoriaRow() {
    return Consumer<CategoriaActivoController>(
      builder: (context, catCtrl, child) {
        final uniqueNames = catCtrl.categorias.map((c) => c.nombre).toSet().toList();
        final selected = uniqueNames.contains(_categoriaSeleccionada)
            ? _categoriaSeleccionada
            : null;

        return Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: selected,
                    hint: Row(
                      children: [
                        const Icon(Icons.category_outlined, color: _terracotta, size: 21),
                        const SizedBox(width: 10),
                        Text(
                          'Categoría',
                          style: GoogleFonts.poppins(fontSize: 13, color: _textMuted),
                        ),
                      ],
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted),
                    items: uniqueNames.map((n) {
                      return DropdownMenuItem<String>(
                        value: n,
                        child: Row(
                          children: [
                            const Icon(Icons.category_outlined, color: _terracotta, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              n,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botón Añadir (+) circular independiente en rojo terracota
            InkWell(
              borderRadius: BorderRadius.circular(27),
              onTap: () async {
                final catCtrl = context.read<CategoriaActivoController>();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriasActivoScreen()),
                );
                catCtrl.loadCategorias();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD62828),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD62828).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Selector tipo Dropdown con etiqueta superior e icono
  Widget _buildDropdownSelector({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              isExpanded: true,
              value: items.contains(value) ? value : items.first,
              icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 20),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: _terracotta),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          e,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Selector de Fecha con etiqueta superior, formato dd/MM/yyyy e icono de calendario
  Widget _buildDatePickerTile() {
    final dateStr = DateFormat('dd/MM/yyyy').format(_fechaAdquisicion);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fechaAdquisicion,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: _terracotta,
                  onPrimary: Colors.white,
                  onSurface: _textDark,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _fechaAdquisicion = picked);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: _terracotta,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Fecha de Adquisición / Registro',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  /// Campo multilínea de Observaciones (75-80px de altura)
  Widget _buildObservacionesField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: 8.0),
            child: Icon(Icons.edit_note_outlined, color: _terracotta, size: 24),
          ),
          Expanded(
            child: TextFormField(
              controller: _obsCtrl,
              maxLines: 2,
              style: GoogleFonts.poppins(fontSize: 13, color: _textDark),
              decoration: InputDecoration(
                hintText: 'Observaciones (Ej: Marca, modelo, serie)',
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón principal con degradado cálido (#D03B1E a #FF6A00), altura 52px y radio 16px
  Widget _buildSaveButton(bool isLoading, bool isEditing) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_terracotta, _orangeAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _terracotta.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        isEditing ? 'ACTUALIZAR ACTIVO' : 'REGISTRAR ACTIVO',
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
      ),
    );
  }
}
