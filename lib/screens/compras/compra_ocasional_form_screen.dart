import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/features/purchases/domain/rules/occasional_purchase_rules.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/compras_controller.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/por_pagar_controller.dart';
import 'package:pizzaapp/services/image_service.dart';

/// Registro de un egreso que no crea insumos ni modifica inventario.
class CompraOcasionalFormScreen extends StatefulWidget {
  final String? descripcionInicial;

  const CompraOcasionalFormScreen({super.key, this.descripcionInicial});

  @override
  State<CompraOcasionalFormScreen> createState() =>
      _CompraOcasionalFormScreenState();
}

class _CompraOcasionalFormScreenState extends State<CompraOcasionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _unidadCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();
  final _adelantoCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController(text: '1');

  late String _categoria;
  DateTime _fecha = DateTime.now();
  String _metodoPago = 'efectivo';
  String? _facturaRuta;
  bool _esPorPagar = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl.text = widget.descripcionInicial?.trim() ?? '';
    _categoria = OccasionalPurchaseRules.categoriasSugeridas.first;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _cantidadCtrl.dispose();
    _unidadCtrl.dispose();
    _costoCtrl.dispose();
    _proveedorCtrl.dispose();
    _adelantoCtrl.dispose();
    _cuotasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fecha = picked);
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Tomar foto',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  final path = await imageService.pickImageFromCamera();
                  if (mounted) Navigator.pop(context, path);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.secondary,
                ),
                title: Text(
                  'Seleccionar de galería',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  final path = await imageService.pickImageFromGallery();
                  if (mounted) Navigator.pop(context, path);
                },
              ),
              if (_facturaRuta != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Eliminar foto',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final total = double.tryParse(_costoCtrl.text.replaceAll(',', '.')) ?? 0;
    final adelanto = _esPorPagar
        ? (double.tryParse(_adelantoCtrl.text.replaceAll(',', '.')) ?? 0)
        : 0.0;
    final cuotas = _esPorPagar ? (int.tryParse(_cuotasCtrl.text) ?? 1) : 1;
    if (_esPorPagar && adelanto > total + 0.000001) {
      _mostrarError('El adelanto no puede superar el costo total.');
      return;
    }
    if (_esPorPagar && cuotas < 1) {
      _mostrarError('Las cuotas deben ser al menos 1.');
      return;
    }

    setState(() => _guardando = true);
    final controller = context.read<ComprasController>();
    final ok = await controller.registrarCompraOcasional(
      descripcion: _descripcionCtrl.text,
      cantidadText: _cantidadCtrl.text,
      unidadMedida: _unidadCtrl.text,
      costoText: _costoCtrl.text,
      categoria: _categoria,
      proveedor: _proveedorCtrl.text,
      facturaRuta: _facturaRuta,
      esPorPagar: _esPorPagar,
      adelanto: adelanto,
      cuotas: cuotas,
      fechaPersonalizada: AppDateUtils.formatStorage(_fecha),
      metodoPago: _metodoPago,
    );

    if (!mounted) return;
    if (!ok) {
      setState(() => _guardando = false);
      _mostrarError(controller.error ?? 'No se pudo registrar la compra.');
      return;
    }

    context.read<CajaController>().loadDatosCaja();
    context.read<DashboardController>().refreshDashboard();
    context.read<PorPagarController>().loadCuentas();
    Navigator.pop(context, true);
  }

  void _mostrarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String? _validarRequerido(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }
    return null;
  }

  String? _validarMonto(String? value, String label) {
    final monto = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (monto == null || monto <= 0) return '$label debe ser mayor a cero';
    return null;
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  String get _fechaTexto {
    final dia = _fecha.day.toString().padLeft(2, '0');
    final mes = _fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${_fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final comprasCtrl = context.watch<ComprasController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Compra ocasional',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Este egreso no crea insumos ni modifica stock. '
                      'Se registra como gasto y, si corresponde, en caja o '
                      'cuentas por pagar.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Datos de la compra'),
            TextFormField(
              controller: _descripcionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                hintText: 'Ej. Fósforos, servicio de gas, flete...',
                prefixIcon: Icons.description_outlined,
              ),
              validator: (value) => _validarRequerido(value, 'La descripción'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidadCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Cantidad',
                      prefixIcon: Icons.numbers_rounded,
                    ),
                    validator: (value) => _validarMonto(value, 'La cantidad'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _unidadCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      hintText: 'Unidad (opcional)',
                      prefixIcon: Icons.straighten_rounded,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                hintText: 'Costo total',
                prefixIcon: Icons.payments_outlined,
                prefixText: 'S/ ',
              ),
              validator: (value) => _validarMonto(value, 'El costo total'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: _inputDecoration(
                hintText: 'Categoría',
                prefixIcon: Icons.category_outlined,
              ),
              items: OccasionalPurchaseRules.categoriasSugeridas
                  .map(
                    (categoria) => DropdownMenuItem(
                      value: categoria,
                      child: Text(
                        categoria,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _guardando
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _categoria = value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _guardando ? null : _seleccionarFecha,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _inputDecoration(
                  hintText: 'Fecha',
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                child: Text(
                  _fechaTexto,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _proveedorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hintText: 'Proveedor (opcional)',
                prefixIcon: Icons.store_outlined,
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Forma de pago'),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _esPorPagar,
              onChanged: _guardando
                  ? null
                  : (value) => setState(() => _esPorPagar = value),
              title: Text(
                'Compra a crédito',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                _esPorPagar
                    ? 'Se registrará una cuenta por pagar.'
                    : 'Se registrará como gasto de contado.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (_esPorPagar) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adelantoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Adelanto',
                        prefixIcon: Icons.price_change_outlined,
                        prefixText: 'S/ ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final monto = double.tryParse(
                          value.replaceAll(',', '.'),
                        );
                        final total =
                            double.tryParse(
                              _costoCtrl.text.replaceAll(',', '.'),
                            ) ??
                            0;
                        if (monto == null || monto < 0 || monto > total) {
                          return 'Máximo S/ ${total.toStringAsFixed(2)}';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cuotasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hintText: 'Cuotas',
                        prefixIcon: Icons.view_week_outlined,
                      ),
                      validator: (value) {
                        final cuotas = int.tryParse(value ?? '') ?? 0;
                        return cuotas < 1 ? 'Mínimo 1' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _metodoPago,
              decoration: _inputDecoration(
                hintText: _esPorPagar
                    ? 'Método del adelanto'
                    : 'Método de pago',
                prefixIcon: Icons.account_balance_wallet_outlined,
              ),
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'yape', child: Text('Yape')),
                DropdownMenuItem(value: 'plin', child: Text('Plin')),
                DropdownMenuItem(
                  value: 'yape/plin',
                  child: Text('Yape / Plin'),
                ),
              ],
              onChanged: _guardando
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _metodoPago = value);
                      }
                    },
            ),
            const SizedBox(height: 18),
            _sectionTitle('Comprobante (opcional)'),
            InkWell(
              onTap: _guardando ? null : _seleccionarImagen,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: _facturaRuta == null
                    ? Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Adjuntar foto o imagen',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textHint,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_facturaRuta!),
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 80,
                                alignment: Alignment.center,
                                color: AppColors.surfaceVariant,
                                child: Text(
                                  'Vista previa no disponible',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca para cambiar o eliminar',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _guardando ? 'Guardando...' : 'Registrar compra ocasional',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (comprasCtrl.error != null) ...[
              const SizedBox(height: 10),
              Text(
                comprasCtrl.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
