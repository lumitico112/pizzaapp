import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/compras_controller.dart';
import 'package:pizzaapp/models/compra.dart';
import 'package:pizzaapp/screens/compras/widgets/insumo_search_field.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/proveedor_controller.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/por_pagar_controller.dart';
import 'package:pizzaapp/screens/insumos/insumo_form_screen.dart';
import 'package:pizzaapp/screens/proveedores/proveedor_form_screen.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/services/image_service.dart';

class CompraFormScreen extends StatefulWidget {
  final Compra? compra;
  const CompraFormScreen({super.key, this.compra});

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Paleta de la marca
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  int? _insumoSeleccionadoId;
  String? _insumoSeleccionadoNombre;
  final _insumoBusquedaCtrl = TextEditingController();
  final _insumoBusquedaFocus = FocusNode();
  int? _proveedorSeleccionadoId;
  final _cantidadCtrl = TextEditingController();
  final _costoTotalCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final _adelantoCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController(text: '1');

  bool _esPorPagar = false;
  String _metodoPago = 'efectivo';
  String? _facturaRuta;
  bool _guardando = false;
  DateTime _fechaSeleccionada = DateTime.now();

  double get _costoUnitario {
    final cant =
        double.tryParse(_cantidadCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final costo =
        double.tryParse(_costoTotalCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (cant > 0) return costo / cant;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.compra;
    if (existing != null) {
      _insumoSeleccionadoId = existing.insumoId;
      _insumoSeleccionadoNombre = existing.insumoNombre;
      _insumoBusquedaCtrl.text = existing.insumoNombre;
      _cantidadCtrl.text = existing.cantidad.toString();
      _costoTotalCtrl.text = (existing.cantidad * existing.costoUnitario)
          .toStringAsFixed(2);
      _notaCtrl.text = existing.motivo;
      _fechaSeleccionada = DateTime.tryParse(existing.fecha) ?? DateTime.now();
      _esPorPagar = existing.esPorPagar ?? false;
      _facturaRuta = existing.facturaRuta;
      _proveedorSeleccionadoId = existing.proveedorId;
      if (existing.metodoPago != null) {
        final mp = existing.metodoPago!.toLowerCase();
        _metodoPago = (mp == 'yape' || mp == 'plin' || mp == 'yape/plin')
            ? 'yape/plin'
            : 'efectivo';
      }
      if (existing.cuotas != null && existing.cuotas! > 0) {
        _cuotasCtrl.text = existing.cuotas.toString();
      }
      if (existing.adelanto != null && existing.adelanto! > 0) {
        _adelantoCtrl.text = existing.adelanto!.toStringAsFixed(2);
      }
    }
    _cantidadCtrl.addListener(() => setState(() {}));
    _costoTotalCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<InsumoController>().loadInsumos();
      final providerController = context.read<ProveedorController>();
      await providerController.loadProveedores();
      if (!mounted || existing == null) return;
      if (_proveedorSeleccionadoId == null && existing.proveedor != null) {
        final matches = providerController.proveedores.where(
          (p) => p.nombre.toLowerCase() == existing.proveedor!.toLowerCase(),
        );
        if (matches.isNotEmpty) {
          setState(() => _proveedorSeleccionadoId = matches.first.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _insumoBusquedaCtrl.dispose();
    _insumoBusquedaFocus.dispose();
    _cantidadCtrl.dispose();
    _costoTotalCtrl.dispose();
    _notaCtrl.dispose();
    _adelantoCtrl.dispose();
    _cuotasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _secondaryRed,
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  Future<void> _seleccionarImagen() async {
    final imageService = ImageService();
    final result = await showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
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
                'Comprobante / Factura',
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
                    color: const Color(0xFFFFF1ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: _primaryOrange),
                ),
                title: Text('Tomar foto', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () async {
                  final path = await imageService.pickImageFromCamera();
                  if (mounted) Navigator.pop(context, path);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: _secondaryRed),
                ),
                title: Text('Seleccionar de galería', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () async {
                  final path = await imageService.pickImageFromGallery();
                  if (mounted) Navigator.pop(context, path);
                },
              ),
              if (_facturaRuta != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  ),
                  title: Text('Eliminar foto', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontWeight: FontWeight.w500)),
                  onTap: () => Navigator.pop(context, '__remove__'),
                ),
            ],
          ),
        ),
      ),
    );

    if (result == '__remove__') {
      setState(() => _facturaRuta = null);
    } else if (result != null) {
      setState(() => _facturaRuta = result);
    }
  }

  Future<void> _mostrarCompraOcasionalPendiente(String query) async {
    final descripcion = query.trim();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Registrar como compra ocasional',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                descripcion.isEmpty
                    ? 'Este gasto no forma parte del inventario de insumos.'
                    : 'No encontramos "$descripcion" en el inventario. Puedes registrarlo como una compra ocasional.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.45,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'La compra ocasional no crea stock ni modifica el inventario. '
                        'Su captura y guardado se habilitarán en la siguiente fase; '
                        'por ahora no se guardó ningún dato.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.45,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¿Eliminar compra?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Eliminar este registro? Se revertirá el gasto en caja y se descontará la cantidad añadida al stock del insumo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final controller = context.read<ComprasController>();
    final id = widget.compra!.movimientoId ?? widget.compra!.id;
    final success = await controller.eliminarCompra(id);

    if (!mounted) return;
    if (success) {
      context.read<InsumoController>().loadInsumos();
      context.read<CajaController>().loadDatosCaja();
      context.read<DashboardController>().refreshDashboard();
      context.read<PorPagarController>().loadCuentas();
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Error al eliminar compra'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    if (_insumoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seleccione un insumo',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cantidadCuotas = int.tryParse(_cuotasCtrl.text) ?? 1;
    final adelanto = _esPorPagar
        ? (double.tryParse(_adelantoCtrl.text) ?? 0)
        : 0.0;
    if (_esPorPagar && cantidadCuotas < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Las cuotas deben ser al menos 1.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final controller = context.read<ComprasController>();
    final selectedVendors = context
        .read<ProveedorController>()
        .proveedores
        .where((p) => p.id == _proveedorSeleccionadoId);
    final proveedorCtrlName = selectedVendors.isEmpty
        ? null
        : selectedVendors.first.nombre;

    final success = widget.compra != null
        ? await controller.corregirCompra(
            compra: widget.compra!,
            nuevoInsumoId: _insumoSeleccionadoId!,
            cantidadText: _cantidadCtrl.text,
            costoText: _costoTotalCtrl.text,
            fecha: AppDateUtils.formatStorage(_fechaSeleccionada),
            motivo: _notaCtrl.text.trim(),
            proveedor: proveedorCtrlName,
            proveedorId: _proveedorSeleccionadoId,
            facturaRuta: _facturaRuta,
            esPorPagar: _esPorPagar,
            adelanto: adelanto,
            cuotas: cantidadCuotas,
            metodoPago: _metodoPago,
          )
        : await controller.registrarCompra(
            _esPorPagar,
            insumoId: _insumoSeleccionadoId!,
            cantidadText: _cantidadCtrl.text,
            costoText: _costoTotalCtrl.text,
            nota: _notaCtrl.text.trim(),
            proveedor: proveedorCtrlName,
            proveedorId: _proveedorSeleccionadoId,
            facturaRuta: _facturaRuta,
            adelanto: adelanto,
            fechaPersonalizada: AppDateUtils.formatStorage(_fechaSeleccionada),
            metodoPago: _metodoPago,
            cuotas: cantidadCuotas,
          );

    if (!mounted) return;
    if (success) {
      // Notificación reactiva inmediata a todos los módulos
      context.read<InsumoController>().loadInsumos();
      context.read<CajaController>().loadDatosCaja();
      context.read<DashboardController>().refreshDashboard();
      context.read<PorPagarController>().loadCuentas();
      Navigator.pop(context, true);
    } else {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.error ?? 'Error al guardar la compra',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: const Color(0xFF9CA3AF),
      ),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
      prefixIcon: Icon(prefixIcon, color: _secondaryRed, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final insumoCtrl = context.watch<InsumoController>();
    final proveedorCtrl = context.watch<ProveedorController>();
    final comprasCtrl = context.watch<ComprasController>();

    final fechaStr =
        '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}';

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
          widget.compra == null ? 'Nueva Compra' : 'Corregir compra',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (widget.compra != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _confirmarEliminar,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
      body: insumoCtrl.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector de Fecha (Siempre editable)
                    InkWell(
                      onTap: _seleccionarFecha,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: _secondaryRed,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _textMuted,
                                    ),
                                  ),
                                  Text(
                                    fechaStr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _textMuted,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Fila de Insumo + Botón Rápido (+) (Siempre habilitado)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InsumoSearchField(
                            insumos: insumoCtrl.insumos,
                            selectedId: _insumoSeleccionadoId,
                            textController: _insumoBusquedaCtrl,
                            focusNode: _insumoBusquedaFocus,
                            decoration: _inputDecoration(
                              hintText: 'Buscar insumo por nombre, tipo o unidad',
                              prefixIcon: Icons.search_rounded,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _textDark,
                            ),
                            onSelected: (insumo) {
                              setState(() {
                                _insumoSeleccionadoId = insumo.id;
                                _insumoSeleccionadoNombre = insumo.nombre;
                              });
                              _insumoBusquedaFocus.unfocus();
                            },
                            onQueryChanged: (text) {
                              if (_insumoSeleccionadoId != null &&
                                  text.trim() !=
                                      (_insumoSeleccionadoNombre ?? '').trim()) {
                                setState(() {
                                  _insumoSeleccionadoId = null;
                                  _insumoSeleccionadoNombre = null;
                                });
                              }
                            },
                            onRegistrarOcasional:
                                _mostrarCompraOcasionalPendiente,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryOrange, _secondaryRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _secondaryRed.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final insumoCtrl = context.read<InsumoController>();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const InsumoFormScreen(),
                                  ),
                                );
                                await insumoCtrl.loadInsumos();
                                if (!mounted) return;
                                final insumos = insumoCtrl.insumos;
                                if (insumos.isNotEmpty) {
                                  final newest = insumos.reduce(
                                    (a, b) => (a.id ?? 0) > (b.id ?? 0) ? a : b,
                                  );
                                  setState(() {
                                    _insumoSeleccionadoId = newest.id;
                                    _insumoSeleccionadoNombre = newest.nombre;
                                    _insumoBusquedaCtrl.value = TextEditingValue(
                                      text: newest.nombre,
                                      selection: TextSelection.collapsed(
                                        offset: newest.nombre.length,
                                      ),
                                    );
                                  });
                                  _insumoBusquedaFocus.unfocus();
                                }
                              },
                              child: const Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Fila de Cantidad y Costo Total
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Cantidad',
                              prefixIcon: Icons.scale_outlined,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _costoTotalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Costo Total',
                              prefixIcon: Icons.payments_outlined,
                              prefixText: 'S/ ',
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),

                    // Badge de Costo Unitario animado
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFDCD2)),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            'Costo unitario: S/ ${_costoUnitario.toStringAsFixed(2)}',
                            key: ValueKey<double>(_costoUnitario),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _secondaryRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Fila de Proveedor + Botón Rápido (+) (Siempre visible y editable)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: proveedorCtrl.proveedores
                                    .any((p) => p.id == _proveedorSeleccionadoId)
                                ? _proveedorSeleccionadoId
                                : null,
                            decoration: _inputDecoration(
                              hintText: 'Proveedor (opcional)',
                              prefixIcon: Icons.storefront_outlined,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _textDark,
                            ),
                            items: proveedorCtrl.proveedores
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      p.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (id) =>
                                setState(() => _proveedorSeleccionadoId = id),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_secondaryRed, _primaryOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _secondaryRed.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final provCtrl = context.read<ProveedorController>();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProveedorFormScreen(),
                                  ),
                                );
                                await provCtrl.loadProveedores();
                                if (!mounted) return;
                                final proveedores = provCtrl.proveedores;
                                if (proveedores.isNotEmpty) {
                                  final newest = proveedores.reduce(
                                    (a, b) => (a.id ?? 0) > (b.id ?? 0) ? a : b,
                                  );
                                  setState(() => _proveedorSeleccionadoId = newest.id);
                                }
                              },
                              child: const Center(
                                child: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 5. Tarjeta "¿Es una cuenta por pagar?" y Selector de Método de Pago
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pending_actions_rounded,
                            color: Color(0xFFEA580C),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '¿Es una cuenta por pagar?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _esPorPagar,
                            activeTrackColor: _primaryOrange,
                            onChanged: (val) => setState(() => _esPorPagar = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Campos condicionales si es cuenta por pagar
                    if (_esPorPagar) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cuotasCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                              decoration: _inputDecoration(
                                hintText: 'N.° Cuotas',
                                prefixIcon: Icons.format_list_numbered_rounded,
                              ),
                              validator: (value) {
                                final cuotas = int.tryParse(value ?? '');
                                return (cuotas == null || cuotas < 1)
                                    ? 'Mínimo 1 cuota'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _adelantoCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                              decoration: _inputDecoration(
                                hintText: 'Adelanto',
                                prefixIcon: Icons.price_change_outlined,
                                prefixText: 'S/ ',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                final amount = double.tryParse(value);
                                final total =
                                    double.tryParse(_costoTotalCtrl.text) ?? 0;
                                return (amount == null || amount < 0 || amount > total)
                                    ? 'Máximo S/ ${total.toStringAsFixed(2)}'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Selector de Método de Pago Unificado (Efectivo & Yape/Plin con iconos)
                    if (!_esPorPagar) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _metodoPago,
                        decoration: _inputDecoration(
                          hintText: 'Método de pago',
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'efectivo',
                            child: Row(
                              children: [
                                Icon(Icons.payments_outlined, color: _secondaryRed, size: 20),
                                SizedBox(width: 10),
                                Text('Efectivo'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'yape/plin',
                            child: Row(
                              children: [
                                Icon(Icons.qr_code_2_rounded, color: _secondaryRed, size: 20),
                                SizedBox(width: 10),
                                Text('Yape/Plin'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _metodoPago = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (widget.compra?.esPorPagar == true) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Los pagos ya registrados se conservan. El nuevo total no puede quedar por debajo de lo abonado.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 6. Campo Motivo / Nota (Siempre visible)
                    TextFormField(
                      controller: _notaCtrl,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Motivo / Nota (opcional)',
                        prefixIcon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 7. Cargador de Comprobante / Factura (Dropzone Moderno - Siempre disponible)
                    GestureDetector(
                      onTap: _seleccionarImagen,
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: _primaryOrange,
                          strokeWidth: 1.5,
                          radius: 16.0,
                        ),
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _facturaRuta != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(_facturaRuta!),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.edit_outlined,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Cambiar',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFEBE3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_outlined,
                                        color: _secondaryRed,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Foto de comprobante / factura',
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
                    const SizedBox(height: 20),

                    // 8. Botón Principal ("Guardar Compra" o "Guardar corrección")
                    SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: comprasCtrl.isLoading ? null : _guardar,
                                child: Center(
                                  child: comprasCtrl.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.compra == null
                                                  ? 'Guardar Compra'
                                                  : 'Guardar corrección',
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
                          if (widget.compra != null) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(
                                  color: Color(0xFFFCA5A5),
                                  width: 1.2,
                                ),
                                backgroundColor: const Color(0xFFFEF2F2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed:
                                  comprasCtrl.isLoading ? null : _confirmarEliminar,
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              label: Text(
                                'Eliminar esta compra',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Custom painter para el borde discontinuo (DashedBorder) del dropzone de comprobantes
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  static const double dashWidth = 6.0;
  static const double dashSpace = 4.0;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 16.0,
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
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          next > metric.length ? metric.length : next,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
