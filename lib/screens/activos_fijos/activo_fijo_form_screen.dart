import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/activo_fijo.dart';
import 'package:pizzaapp/controllers/activo_fijo_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/widgets/primary_button.dart';
import 'package:pizzaapp/core/widgets/app_text_field.dart';
import 'package:pizzaapp/core/widgets/app_image_picker.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/controllers/categoria_activo_controller.dart';
import 'package:pizzaapp/screens/categorias/categorias_activo_screen.dart';

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
  final List<String> _estados = ['En uso', 'En reparación', 'Fuera de servicio'];
  
  String _condicion = 'Comprado';
  final List<String> _condiciones = ['Comprado', 'Alquilado', 'Prestado', 'Regalado'];
  
  String _metodoPago = 'Contado';
  final List<String> _metodosPago = ['Contado', 'Crédito'];

  String? _frecuenciaAlquiler = 'Mensual';
  final List<String> _frecuencias = ['Diario', 'Mensual', 'Anual'];

  String? _fotoRuta;
  DateTime _fechaAdquisicion = DateTime.now();

  bool _isCalculating = false;

  void _calcularCostoTotal() {
    if (_isCalculating) return;
    _isCalculating = true;
    final condicionValida = _condicion == 'Prestado' || _condicion == 'Alquilado';
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
      if (_frecuencias.contains(a.frecuenciaAlquiler)) _frecuenciaAlquiler = a.frecuenciaAlquiler;
      
      _cuotasCtrl.text = a.cuotas.toString();
      _cantidadCtrl.text = a.cantidad.toString();
      
      _fotoRuta = a.fotoRuta;
      if (a.fechaAdquisicion != null && a.fechaAdquisicion!.isNotEmpty) {
        _fechaAdquisicion = DateTime.tryParse(a.fechaAdquisicion!) ?? DateTime.now();
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
    if (_condicion == 'Comprado' || _condicion == 'Alquilado' || _condicion == 'Prestado') {
        costo = double.tryParse(_costoCtrl.text) ?? 0;
        if ((_condicion == 'Comprado' || _condicion == 'Alquilado') && costo <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un costo válido')));
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
      frecuenciaAlquiler: _condicion == 'Alquilado' ? _frecuenciaAlquiler : null,
      observaciones: _obsCtrl.text.trim(),
      fotoRuta: _fotoRuta,
      adelanto: adelanto,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ctrl.error ?? 'Error al guardar')));
    }
  }

  void _mostrarDialogoReparacion(BuildContext context) {
    final costoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Reparación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esto registrará un gasto en la caja de hoy y cambiará el estado a "En reparación".'),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: costoCtrl, decoration: const InputDecoration(labelText: 'Costo (S/)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Detalle del arreglo', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final costo = double.tryParse(costoCtrl.text) ?? 0;
              if (costo > 0) {
                Navigator.pop(ctx);
                final ok = await context.read<ActivoFijoController>().registrarReparacion(widget.activoAEditar!, costo, descCtrl.text.trim());
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reparación y Gasto registrados', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
                  setState(() { _estado = 'En reparación'; });
                }
              }
            },
            child: const Text('Confirmar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activoAEditar == null ? 'Nuevo Activo' : 'Editar Activo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ActivoFijoController>(
        builder: (context, ctrl, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: AppImagePicker(
                      currentImagePath: _fotoRuta,
                      onImageSelected: (path) => setState(() => _fotoRuta = path),
                      isCircular: false,
                      size: 120,
                      label: 'Foto del activo',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppTextField(
                          controller: _nombreCtrl,
                          label: 'Nombre del Activo',
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 1,
                        child: AppTextField(
                          controller: _cantidadCtrl,
                          label: 'Cant.',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Req';
                            final c = int.tryParse(v);
                            if (c == null || c <= 0) return '> 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<CategoriaActivoController>(
                          builder: (context, catCtrl, child) {
                            final uniqueNames = catCtrl.categorias.map((c) => c.nombre).toSet().toList();
                            return DropdownButtonFormField<String>(
                              value: uniqueNames.contains(_categoriaSeleccionada) ? _categoriaSeleccionada : null,
                              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                              items: uniqueNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                              onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                            );
                          }
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriasActivoScreen())).then((_) {
                            if (mounted) context.read<CategoriaActivoController>().loadCategorias();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _condicion,
                          decoration: const InputDecoration(labelText: 'Condición', border: OutlineInputBorder()),
                          items: _condiciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() {
                            _condicion = v!;
                            _calcularCostoTotal();
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _estado,
                          decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                          items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _estado = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_condicion == 'Alquilado') ...[
                    DropdownButtonFormField<String>(
                      value: _frecuenciaAlquiler,
                      decoration: const InputDecoration(labelText: 'Frecuencia de alquiler', border: OutlineInputBorder()),
                      items: _frecuencias.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _frecuenciaAlquiler = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  
                  if ((_condicion == 'Prestado' || _condicion == 'Alquilado') && (int.tryParse(_cantidadCtrl.text) ?? 1) > 1) ...[
                    AppTextField(
                      controller: _valorUnitarioCtrl,
                      label: 'Valor por unidad (Opcional)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  
                  if (_condicion == 'Comprado' || _condicion == 'Alquilado' || _condicion == 'Prestado') ...[
                    AppTextField(
                      controller: _costoCtrl,
                      label: _condicion == 'Comprado' ? 'Costo Total de Adquisición' : (_condicion == 'Alquilado' ? 'Costo de Alquiler' : 'Valor Total Estimado (Opcional)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_condicion == 'Prestado') return null;
                        return v!.isEmpty ? 'Requerido' : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  
                  if (_condicion == 'Comprado') ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _metodoPago,
                            decoration: const InputDecoration(labelText: 'Método de Pago', border: OutlineInputBorder()),
                            items: _metodosPago.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => setState(() => _metodoPago = v!),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        if (_metodoPago == 'Crédito') ...[
                          Expanded(
                            child: AppTextField(
                              controller: _cuotasCtrl,
                              label: 'Cuotas',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              controller: _adelantoCtrl,
                              label: 'Adelanto',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          ),
                        ] else
                          const Spacer(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  
                  AppDatePicker(
                    selectedDate: _fechaAdquisicion,
                    onDateChanged: (dt) => setState(() => _fechaAdquisicion = dt),
                    label: 'Fecha de Adquisición / Registro',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  AppTextField(
                    controller: _obsCtrl,
                    label: 'Observaciones (Ej: Marca, modelo, serie)',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  PrimaryButton(
                    text: widget.activoAEditar == null ? 'REGISTRAR ACTIVO' : 'ACTUALIZAR ACTIVO',
                    color: AppColors.primary,
                    isLoading: ctrl.isLoading,
                    onPressed: _guardar,
                  ),
                  
                  if (widget.activoAEditar != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14)
                      ),
                      icon: const Icon(Icons.build),
                      label: const Text('REGISTRAR GASTO DE REPARACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _mostrarDialogoReparacion(context),
                    )
                  ],
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
