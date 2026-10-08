import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/categoria_insumo_controller.dart';
import 'package:pizzaapp/screens/categorias/categorias_insumo_screen.dart';

import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_image_picker.dart';

class InsumoFormScreen extends StatefulWidget {
  final Insumo? insumoAEditar;

  const InsumoFormScreen({super.key, this.insumoAEditar});

  @override
  State<InsumoFormScreen> createState() => _InsumoFormScreenState();
}

class _InsumoFormScreenState extends State<InsumoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _stockMinimoCtrl = TextEditingController(text: '0.0');
  final _rendimientoCtrl = TextEditingController(text: '1.0');
  final _contenidoPaqueteCtrl = TextEditingController(text: '1.0');

  String? _categoriaSeleccionada;
  String _unidadSeleccionada = 'Kg';
  String? _imagePath;

  final List<String> _unidades = ['Kg', 'gr', 'Litros', 'ml', 'Paquetes', 'Unidades'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaInsumoController>().loadCategorias();
    });

    if (widget.insumoAEditar != null) {
      final i = widget.insumoAEditar!;
      _nombreCtrl.text = i.nombre;
      _stockMinimoCtrl.text = i.stockMinimo.toString();
      _rendimientoCtrl.text = i.rendimientoPorUnidad.toString();
      _categoriaSeleccionada = i.tipoInsumo;
      if (_unidades.contains(i.unidadMedida)) {
        _unidadSeleccionada = i.unidadMedida;
      }
      _contenidoPaqueteCtrl.text = i.contenidoPaquete.toString();
      _imagePath = i.fotoRuta;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _rendimientoCtrl.dispose();
    _contenidoPaqueteCtrl.dispose();
    super.dispose();
  }

  void _crearCategoria() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriasInsumoScreen()));
    if (mounted) context.read<CategoriaInsumoController>().loadCategorias();
  }

  Future<void> _guardarInsumo() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría'), backgroundColor: AppColors.error)
      );
      return;
    }

    final controller = context.read<InsumoController>();
    final success = await controller.guardarInsumo(
      id: widget.insumoAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      tipoInsumo: _categoriaSeleccionada!,
      unidadMedida: _unidadSeleccionada,
      stockMinimoText: _stockMinimoCtrl.text,
      rendimientoPorUnidadText: _rendimientoCtrl.text,
      contenidoPaquete: _unidadSeleccionada == 'Paquetes' ? (int.tryParse(_contenidoPaqueteCtrl.text) ?? 1) : 1,
      fotoRuta: _imagePath,
    );

    if (!mounted) return;
    
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.insumoAEditar == null ? 'Insumo creado' : 'Insumo actualizado'), 
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Error'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<InsumoController>().isLoading;
    final categorias = context.watch<CategoriaInsumoController>().categorias;

    // Asegurarse de que el valor seleccionado existe
    if (_categoriaSeleccionada != null && !categorias.any((c) => c.nombre == _categoriaSeleccionada)) {
      if (categorias.isNotEmpty) {
        _categoriaSeleccionada = categorias.first.nombre;
      } else {
        _categoriaSeleccionada = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.insumoAEditar == null ? 'Nuevo Insumo' : 'Editar Insumo'),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppImagePicker(
                currentImagePath: _imagePath,
                isCircular: true,
                size: 110,
                onImageSelected: (path) => setState(() => _imagePath = path),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Insumo', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                      items: categorias.map((c) => DropdownMenuItem(value: c.nombre, child: Text(c.nombre))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _categoriaSeleccionada = val);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.secondary, size: 32),
                    onPressed: _crearCategoria,
                    tooltip: 'Crear nueva categoría',
                  )
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unidadSeleccionada,
                      decoration: const InputDecoration(labelText: 'Und. Medida', border: OutlineInputBorder()),
                      items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _unidadSeleccionada = val);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _stockMinimoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock Mínimo', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              if (_unidadSeleccionada == 'Paquetes') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _contenidoPaqueteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Contenido del Paquete',
                    border: OutlineInputBorder(),
                    helperText: 'Ej: 50 (si el paquete trae 50 unidades)',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _rendimientoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rendimiento por Und. Medida', 
                  border: OutlineInputBorder(),
                  helperText: 'Ej: 1 Kg de harina da 3 masas (Rendimiento: 3)',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                  ),
                  onPressed: isLoading ? null : _guardarInsumo,
                  child: isLoading 
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.insumoAEditar == null ? 'GUARDAR INSUMO' : 'ACTUALIZAR INSUMO',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
