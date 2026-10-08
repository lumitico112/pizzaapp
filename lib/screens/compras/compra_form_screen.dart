import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/compras_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/screens/insumos/insumo_form_screen.dart';
import 'package:pizzaapp/screens/proveedores/proveedores_screen.dart';
import 'package:pizzaapp/core/widgets/primary_button.dart';
import 'package:pizzaapp/core/widgets/app_text_field.dart';
import 'package:pizzaapp/core/widgets/app_image_picker.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';

class CompraFormScreen extends StatefulWidget {
  const CompraFormScreen({super.key});

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _insumoSeleccionadoId;
  final _cantidadCtrl = TextEditingController();
  final _costoTotalCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final _adelantoCtrl = TextEditingController();

  bool _esPorPagar = false;
  String? _facturaRuta;
  DateTime _fechaSeleccionada = DateTime.now();

  double get _costoUnitario {
    final cant = double.tryParse(_cantidadCtrl.text) ?? 0.0;
    final costo = double.tryParse(_costoTotalCtrl.text) ?? 0.0;
    if (cant > 0) return costo / cant;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _cantidadCtrl.addListener(() => setState(() {}));
    _costoTotalCtrl.addListener(() => setState(() {}));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
    });
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _costoTotalCtrl.dispose();
    _proveedorCtrl.dispose();
    _notaCtrl.dispose();
    _adelantoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_insumoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un insumo')));
      return;
    }

    // Agregar adelanto en la nota si es por pagar
    String notaFinal = _notaCtrl.text.trim();
    if (_esPorPagar && _adelantoCtrl.text.isNotEmpty) {
      notaFinal = 'Adelanto: ${_adelantoCtrl.text} | $notaFinal';
    }
    
    // También concatenar la fecha si el controlador no lo soporta (según instrucciones)
    notaFinal = 'Fecha: ${AppDateUtils.formatDisplay(_fechaSeleccionada)} | $notaFinal';

    final success = await context.read<ComprasController>().registrarCompra(
      _esPorPagar,
      insumoId: _insumoSeleccionadoId!,
      cantidadText: _cantidadCtrl.text,
      costoText: _costoTotalCtrl.text,
      nota: notaFinal,
      proveedor: _proveedorCtrl.text.trim(),
      facturaRuta: _facturaRuta,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra guardada'), backgroundColor: AppColors.success)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<ComprasController>().error ?? 'Error al guardar'), backgroundColor: AppColors.error)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final insumoCtrl = context.watch<InsumoController>();
    final comprasCtrl = context.watch<ComprasController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Compra'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: insumoCtrl.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDatePicker(
                    selectedDate: _fechaSeleccionada,
                    onDateChanged: (date) {
                      setState(() => _fechaSeleccionada = date);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Selección de insumo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Insumo',
                            border: OutlineInputBorder(),
                          ),
                          value: _insumoSeleccionadoId,
                          items: insumoCtrl.insumos.map((i) {
                            return DropdownMenuItem(
                              value: i.id,
                              child: Text(i.nombre),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _insumoSeleccionadoId = val),
                          validator: (val) => val == null ? 'Seleccione' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primaryDark, size: 36),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InsumoFormScreen()),
                          );
                          if (mounted) context.read<InsumoController>().loadInsumos();
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Cantidad y Costo Total
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _cantidadCtrl,
                          label: 'Cantidad',
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          controller: _costoTotalCtrl,
                          label: 'Costo Total',
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Costo unitario: S/ ${_costoUnitario.toStringAsFixed(2)}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Proveedor
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _proveedorCtrl,
                          label: 'Proveedor',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primaryDark, size: 36),
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Por pagar switch
                  SwitchListTile(
                    title: const Text('¿Es una cuenta por pagar?', style: AppTextStyles.bodyMedium),
                    value: _esPorPagar,
                    activeColor: AppColors.primaryDark,
                    onChanged: (val) => setState(() => _esPorPagar = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  if (_esPorPagar) ...[
                    AppTextField(
                      controller: _adelantoCtrl,
                      label: 'Adelanto (S/)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  AppTextField(
                    controller: _notaCtrl,
                    label: 'Motivo / Nota',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  AppImagePicker(
                    currentImagePath: _facturaRuta,
                    onImageSelected: (path) => setState(() => _facturaRuta = path),
                    label: 'Foto de comprobante / factura',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  PrimaryButton(
                    text: 'Guardar Compra',
                    isLoading: comprasCtrl.isLoading,
                    onPressed: comprasCtrl.isLoading ? null : _guardar,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
    );
  }
}
