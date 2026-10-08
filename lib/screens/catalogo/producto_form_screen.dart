import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/controllers/categoria_producto_controller.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:pizzaapp/screens/categorias/categorias_screen.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/primary_button.dart';
import 'package:pizzaapp/core/widgets/app_text_field.dart';

class VariantControllerState {
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

class ProductoFormScreen extends StatefulWidget {
  final Producto? productoAEditar;

  const ProductoFormScreen({super.key, this.productoAEditar});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  int? _categoriaSeleccionada;
  String _tipoPreparacion = 'anticipado';
  String? _imagePath;

  List<VariantControllerState> _variantesCtrl = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaProductoController>().loadCategorias();
    });

    if (widget.productoAEditar != null) {
      final p = widget.productoAEditar!;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion ?? '';
      _categoriaSeleccionada = p.categoriaId;
      _tipoPreparacion = p.tipoPreparacion;
      _imagePath = p.fotoRuta;
      _cargarVariantes(p.id!);
    } else {
      _addVariant(); // Al menos 1
    }
  }

  Future<void> _cargarVariantes(int productId) async {
    final vars = await context.read<ProductoController>().obtenerVariantes(productId);
    setState(() {
      if (vars.isEmpty) {
        _addVariant();
      } else {
        for (var v in vars) {
          final vc = VariantControllerState();
          vc.nameCtrl.text = v.nombreVariante;
          vc.priceCtrl.text = v.precioVenta.toString();
          vc.costCtrl.text = v.costoEstimadoManual.toString();
          vc.imagePath = v.imagen;
          _variantesCtrl.add(vc);
        }
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
    setState(() {
      _variantesCtrl[index].dispose();
      _variantesCtrl.removeAt(index);
    });
  }

  Future<void> _tomarFotoPrincipal(bool desdeCamara) async {
    final path = desdeCamara ? await _imageService.pickImageFromCamera() : await _imageService.pickImageFromGallery();
    if (path != null) setState(() => _imagePath = path);
  }

  Future<void> _tomarFotoVariante(int index, bool desdeCamara) async {
    final path = desdeCamara ? await _imageService.pickImageFromCamera() : await _imageService.pickImageFromGallery();
    if (path != null) setState(() => _variantesCtrl[index].imagePath = path);
  }

  void _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_variantesCtrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos una variante (ej: Personal)')));
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
    );

    List<VarianteProducto> vars = [];
    for (var vc in _variantesCtrl) {
      vars.add(VarianteProducto(
        productoId: 0,
        nombreVariante: vc.nameCtrl.text.trim(),
        precioVenta: double.tryParse(vc.priceCtrl.text) ?? 0.0,
        costoEstimadoManual: double.tryParse(vc.costCtrl.text) ?? 0.0,
        imagen: vc.imagePath,
      ));
    }

    final success = await context.read<ProductoController>().guardarProductoCompleto(
      producto: prod, 
      variantes: vars
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto guardado correctamente'), backgroundColor: AppColors.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<ProductoController>().error ?? 'Error'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catCtrl = context.watch<CategoriaProductoController>();
    final prodCtrl = context.watch<ProductoController>();

    if (_categoriaSeleccionada != null && !catCtrl.categorias.any((c) => c.id == _categoriaSeleccionada)) {
      _categoriaSeleccionada = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productoAEditar == null ? 'Nuevo Producto' : 'Editar Producto'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- IMAGEN PRINCIPAL ---
              Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(leading: const Icon(Icons.camera), title: const Text('Cámara'), onTap: () { Navigator.pop(ctx); _tomarFotoPrincipal(true); }),
                            ListTile(leading: const Icon(Icons.image), title: const Text('Galería'), onTap: () { Navigator.pop(ctx); _tomarFotoPrincipal(false); }),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                      image: _imagePath != null ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover) : null,
                    ),
                    child: _imagePath == null ? const Icon(Icons.add_a_photo, size: 40, color: AppColors.primary) : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- DATOS BÃSICOS ---
              AppTextField(
                controller: _nombreCtrl,
                label: 'Nombre del Producto (Ej: Pizza Americana)',
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descCtrl,
                label: 'Descripción (Opcional)',
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                      items: catCtrl.categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                      onChanged: (val) => setState(() => _categoriaSeleccionada = val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriasScreen()));
                      if (mounted) context.read<CategoriaProductoController>().loadCategorias();
                    },
                  )
                ],
              ),
              
              
              const SizedBox(height: 32),
              const Text('TAMAÑOS / VARIANTES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const Text('Ej: "Personal", "Familiar", "1 Litro". Si solo hay un tamaño, escribe "Único".', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              
              ..._variantesCtrl.asMap().entries.map((entry) {
                int index = entry.key;
                var vc = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (ctx) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(leading: const Icon(Icons.camera), title: const Text('Cámara'), onTap: () { Navigator.pop(ctx); _tomarFotoVariante(index, true); }),
                                        ListTile(leading: const Icon(Icons.image), title: const Text('Galería'), onTap: () { Navigator.pop(ctx); _tomarFotoVariante(index, false); }),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  image: vc.imagePath != null ? DecorationImage(image: FileImage(File(vc.imagePath!)), fit: BoxFit.cover) : null,
                                ),
                                child: vc.imagePath == null ? const Icon(Icons.add_a_photo, color: AppColors.textSecondary) : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: vc.nameCtrl,
                                label: 'Nombre de variante',
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            if (_variantesCtrl.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () => _removeVariant(index),
                              )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: vc.priceCtrl,
                                label: 'Precio Venta (S/)',
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),

              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar otro tamaño/variante'),
                onPressed: _addVariant,
              ),

              const SizedBox(height: 32),
              PrimaryButton(
                text: widget.productoAEditar == null ? 'GUARDAR PRODUCTO' : 'ACTUALIZAR PRODUCTO',
                isLoading: prodCtrl.isLoading,
                onPressed: _guardarProducto,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

