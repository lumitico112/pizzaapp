import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/proveedor_controller.dart';
import 'package:pizzaapp/models/proveedor.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';

class ProveedorFormScreen extends StatefulWidget {
  final Proveedor? proveedor;
  const ProveedorFormScreen({super.key, this.proveedor});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.proveedor?.nombre ?? '');
  late final _telCtrl = TextEditingController(text: widget.proveedor?.telefono ?? '');
  late final _emailCtrl = TextEditingController(text: widget.proveedor?.email ?? '');
  late final _dirCtrl = TextEditingController(text: widget.proveedor?.direccion ?? '');
  late final _notasCtrl = TextEditingController(text: widget.proveedor?.notas ?? '');

  @override
  void dispose() {
    _nombreCtrl.dispose(); _telCtrl.dispose(); _emailCtrl.dispose();
    _dirCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final p = Proveedor(
      id: widget.proveedor?.id,
      nombre: _nombreCtrl.text.trim(),
      telefono: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      direccion: _dirCtrl.text.trim().isEmpty ? null : _dirCtrl.text.trim(),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    final err = await context.read<ProveedorController>().guardarProveedor(p);
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: err.contains('ya existe') ? AppColors.warning : AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProveedorController>().isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Datos del Proveedor', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store_outlined)),
                validator: (v) => v!.trim().isEmpty ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _dirCtrl,
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas adicionales', border: OutlineInputBorder(), alignLabelWithHint: true),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : _guardar,
                icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: Text(widget.proveedor == null ? 'Guardar Proveedor' : 'Actualizar Proveedor', style: AppTextStyles.buttonLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
