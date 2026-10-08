import sys

new_content = """import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/activo_fijo.dart';
import 'package:pizzaapp/controllers/activo_fijo_controller.dart';
import 'package:pizzaapp/services/image_service.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/primary_button.dart';
import 'package:pizzaapp/core/widgets/app_text_field.dart';
import 'package:pizzaapp/core/utils/formatters.dart';

class ActivoFijoFormScreen extends StatefulWidget {
  final ActivoFijo? activoAEditar;

  const ActivoFijoFormScreen({super.key, this.activoAEditar});

  @override
  State<ActivoFijoFormScreen> createState() => _ActivoFijoFormScreenState();
}

class _ActivoFijoFormScreenState extends State<ActivoFijoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  final _nombreCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController(text: '1');

  String _estado = 'Bueno';
  final List<String> _estados = ['Nuevo', 'Bueno', 'Regular', 'Malo', 'En reparación', 'Fuera de servicio'];
  
  String _condicion = 'Comprado';
  final List<String> _condiciones = ['Comprado', 'Alquilado', 'Prestado', 'Regalado'];
  
  String _metodoPago = 'Contado';
  final List<String> _metodosPago = ['Contado', 'Crédito'];

  String? _fotoRuta;
  String? _fechaAdquisicion;

  @override
  void initState() {
    super.initState();
    if (widget.activoAEditar != null) {
      final a = widget.activoAEditar!;
      _nombreCtrl.text = a.nombre;
      _categoriaCtrl.text = a.categoria ?? '';
      if (a.costo > 0) _costoCtrl.text = a.costo.toString();
      _obsCtrl.text = a.observaciones ?? '';
      
      if (_estados.contains(a.estado)) _estado = a.estado;
      if (_condiciones.contains(a.condicion)) _condicion = a.condicion;
      if (_metodosPago.contains(a.metodoPago)) _metodoPago = a.metodoPago;
      _cuotasCtrl.text = a.cuotas.toString();
      
      _fotoRuta = a.fotoRuta;
      _fechaAdquisicion = a.fechaAdquisicion;
    } else {
      _fechaAdquisicion = DateTime.now().toIso8601String().split('T')[0];
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _categoriaCtrl.dispose();
    _costoCtrl.dispose();
    _obsCtrl.dispose();
    _cuotasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_fechaAdquisicion!),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dt != null) {
      setState(() {
        _fechaAdquisicion = dt.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _tomarFoto() async {
    final ruta = await _imageService.takePicture();
    if (ruta != null) {
      setState(() => _fotoRuta = ruta);
    }
  }

  Future<void> _elegirFoto() async {
    final ruta = await _imageService.pickImageFromGallery();
    if (ruta != null) {
      setState(() => _fotoRuta = ruta);
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    double costo = 0;
    if (_condicion == 'Comprado' || _condicion == 'Alquilado') {
        costo = double.tryParse(_costoCtrl.text) ?? 0;
        if (costo <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un costo válido')));
          return;
        }
    }
    
    int cuotas = 1;
    if (_condicion == 'Comprado' && _metodoPago == 'Crédito') {
        cuotas = int.tryParse(_cuotasCtrl.text) ?? 1;
        if (cuotas <= 0) cuotas = 1;
    }

    final obj = ActivoFijo(
      id: widget.activoAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoriaCtrl.text.trim(),
      costo: costo,
      fechaAdquisicion: _fechaAdquisicion!,
      estado: _estado,
      condicion: _condicion,
      metodoPago: _metodoPago,
      cuotas: cuotas,
      observaciones: _obsCtrl.text.trim(),
      fotoRuta: _fotoRuta,
    );

    final ctrl = context.read<ActivoFijoController>();
    
    bool ok;
    if (widget.activoAEditar == null) {
      ok = await ctrl.agregarActivo(obj);
    } else {
      ok = await ctrl.actualizarActivo(obj);
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ctrl.error ?? 'Error al guardar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activoAEditar == null ? 'Nuevo Activo' : 'Editar Activo'),
        backgroundColor: Colors.brown,
      ),
      body: Consumer<ActivoFijoController>(
        builder: (context, ctrl, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Cámara'), onTap: () { Navigator.pop(context); _tomarFoto(); }),
                              ListTile(leading: const Icon(Icons.photo), title: const Text('Galería'), onTap: () { Navigator.pop(context); _elegirFoto(); }),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.brown.shade200),
                        ),
                        child: _fotoRuta != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_fotoRuta!), fit: BoxFit.cover))
                            : const Icon(Icons.add_a_photo, color: Colors.brown, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  AppTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre del Activo (Ej: Horno pizzero)',
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _categoriaCtrl,
                    label: 'Categoría (Ej: Maquinaria, Muebles)',
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _condicion,
                          decoration: const InputDecoration(labelText: 'Condición', border: OutlineInputBorder()),
                          items: _condiciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _condicion = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                  const SizedBox(height: 16),
                  
                  if (_condicion == 'Comprado' || _condicion == 'Alquilado') ...[
                    AppTextField(
                      controller: _costoCtrl,
                      label: _condicion == 'Comprado' ? 'Costo Total de Adquisición' : 'Costo de Alquiler',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (_condicion == 'Comprado') ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _metodoPago,
                            decoration: const InputDecoration(labelText: 'Método de Pago', border: OutlineInputBorder()),
                            items: _metodosPago.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => setState(() => _metodoPago = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_metodoPago == 'Crédito')
                          Expanded(
                            child: AppTextField(
                              controller: _cuotasCtrl,
                              label: 'Cuotas',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha de Adquisición / Registro'),
                    subtitle: Text(DateFormatter.formatFecha(_fechaAdquisicion ?? '')),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _seleccionarFecha,
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _obsCtrl,
                    label: 'Observaciones (Ej: Marca, modelo, serie)',
                  ),
                  const SizedBox(height: 32),
                  
                  PrimaryButton(
                    text: widget.activoAEditar == null ? 'REGISTRAR ACTIVO' : 'ACTUALIZAR ACTIVO',
                    color: Colors.brown,
                    isLoading: ctrl.isLoading,
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
"""

with open('C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
