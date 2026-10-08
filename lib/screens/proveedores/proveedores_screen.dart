import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/proveedor_controller.dart';
import 'package:pizzaapp/models/proveedor.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/core/widgets/app_confirm_dialog.dart';
import 'proveedor_form_screen.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorController>().loadProveedores();
    });
  }

  Future<void> _abrirFormulario({Proveedor? proveedor}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProveedorFormScreen(proveedor: proveedor)),
    );
    if (result == true && mounted) {
      context.read<ProveedorController>().loadProveedores();
    }
  }

  Future<void> _confirmarEliminar(Proveedor p) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Eliminar proveedor',
      message: '¿Eliminar a "${p.nombre}"? No se borrarán sus compras asociadas.',
      confirmLabel: 'Eliminar',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    final err = await context.read<ProveedorController>().eliminarProveedor(p.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Proveedor eliminado'),
      backgroundColor: err == null ? AppColors.success : AppColors.error,
    ));
  }

  Widget _buildCard(Proveedor p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: Text(p.nombre[0].toUpperCase(), style: AppTextStyles.sectionTitle.copyWith(color: AppColors.primaryDark)),
        ),
        title: Text(p.nombre, style: AppTextStyles.labelBold),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.telefono != null && p.telefono!.isNotEmpty)
              Row(children: [
                const Icon(Icons.phone, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(p.telefono!, style: AppTextStyles.caption),
              ]),
            if (p.email != null && p.email!.isNotEmpty)
              Row(children: [
                const Icon(Icons.email_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(p.email!, style: AppTextStyles.caption),
              ]),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => _abrirFormulario(proveedor: p),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmarEliminar(p),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProveedorController>(
      builder: (_, ctrl, __) => Scaffold(
        appBar: AppBar(
          title: const Text('Proveedores'),
          backgroundColor: AppColors.primaryDark,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: ctrl.loadProveedores),
          ],
        ),
        body: ctrl.isLoading
            ? const AppLoadingState(message: 'Cargando proveedores...')
            : ctrl.proveedores.isEmpty
                ? AppEmptyState(
                    message: 'No hay proveedores registrados.',
                    icon: Icons.store_outlined,
                    actionLabel: 'Agregar proveedor',
                    onAction: () => _abrirFormulario(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 100),
                    itemCount: ctrl.proveedores.length,
                    itemBuilder: (_, i) => _buildCard(ctrl.proveedores[i]),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryDark,
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add),
          label: const Text('Añadir proveedor'),
        ),
      ),
    );
  }
}
