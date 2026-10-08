import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/mermas/merma_form_screen.dart'
new_content = """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/merma_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/primary_button.dart';
import 'package:pizzaapp/core/widgets/app_text_field.dart';

class MermaFormScreen extends StatefulWidget {
  const MermaFormScreen({super.key});

  @override
  State<MermaFormScreen> createState() => _MermaFormScreenState();
}

class _MermaFormScreenState extends State<MermaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _esInsumo = true;
  int? _insumoSeleccionado;
  int? _varianteSeleccionada;
  
  String _tipoSeleccionado = 'dañado';
  final List<String> _tipos = ['quemado', 'vencido', 'dañado', 'otro'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
      context.read<PosController>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_esInsumo && _insumoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un insumo para reportar')));
      return;
    }
    if (!_esInsumo && _varianteSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un producto preparado para reportar')));
      return;
    }
    
    final ctrl = context.read<MermaController>();
    final res = await ctrl.registrarMerma(
      tipo: _tipoSeleccionado,
      cantidadText: _cantidadCtrl.text,
      descripcion: _descCtrl.text.trim(),
      insumoId: _esInsumo ? _insumoSeleccionado : null,
      varianteId: !_esInsumo ? _varianteSeleccionada : null,
    );

    if (!mounted) return;
    if (res) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merma registrada y stock descontado'), backgroundColor: AppColors.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ctrl.error ?? 'Error'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final insumoCtrl = context.watch<InsumoController>();
    final posCtrl = context.watch<PosController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Merma'),
        backgroundColor: AppColors.error,
      ),
      body: (insumoCtrl.isLoading || posCtrl.isLoading)
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Advertencia: Registrar una merma descontará automáticamente el stock.', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Insumos Crudos'),
                        selected: _esInsumo,
                        onSelected: (val) => setState(() { _esInsumo = true; _varianteSeleccionada = null; }),
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Productos Preparados'),
                        selected: !_esInsumo,
                        onSelected: (val) => setState(() { _esInsumo = false; _insumoSeleccionado = null; }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  if (_esInsumo)
                    DropdownButtonFormField<int>(
                      value: _insumoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Insumo Afectado', border: OutlineInputBorder()),
                      items: insumoCtrl.insumos.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.nombre} (${i.unidadMedida})'))).toList(),
                      onChanged: (val) => setState(() => _insumoSeleccionado = val),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _varianteSeleccionada,
                      decoration: const InputDecoration(labelText: 'Producto Afectado', border: OutlineInputBorder()),
                      items: posCtrl.posItems.map((p) => DropdownMenuItem(value: p.variante.id, child: Text('${p.producto.nombre} - ${p.variante.nombreVariante}'))).toList(),
                      onChanged: (val) => setState(() => _varianteSeleccionada = val),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _tipoSeleccionado,
                          decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder()),
                          items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                          onChanged: (val) => setState(() => _tipoSeleccionado = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _cantidadCtrl,
                          label: 'Cantidad Perdida',
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _descCtrl,
                    label: 'Descripción o detalle (Opcional)',
                  ),
                  
                  const SizedBox(height: 32),
                  Consumer<MermaController>(
                    builder: (ctx, ctrl, _) => PrimaryButton(
                      text: 'REGISTRAR MERMA',
                      color: AppColors.error,
                      isLoading: ctrl.isLoading,
                      onPressed: _guardar,
                    )
                  )
                ],
              ),
            ),
          ),
    );
  }
}
"""

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_content)
