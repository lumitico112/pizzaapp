import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/core/widgets/app_confirm_dialog.dart';
import 'package:pizzaapp/screens/insumos/insumo_form_screen.dart';
import 'package:pizzaapp/screens/compras/compras_screen.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
    });
  }

  void _abrirFormulario({Insumo? insumo}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => InsumoFormScreen(insumoAEditar: insumo)),
    );
    if (result == true && mounted) {
      context.read<InsumoController>().loadInsumos();
    }
  }

  Future<void> _confirmarSeAcabo(Insumo insumo) async {
    if (insumo.stockActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El stock ya es 0.')),
      );
      return;
    }
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '¿Se acabó el insumo?',
      message: 'El sistema registra ${insumo.stockActual.toStringAsFixed(2)} ${insumo.unidadMedida} de "${insumo.nombre}".\n\nEl stock se ajustará a 0.',
      confirmLabel: 'Sí, ajustar a 0',
      cancelLabel: 'Cancelar',
      confirmColor: AppColors.warning,
      icon: Icons.warning_amber_outlined,
    );
    if (!confirmed || !mounted) return;

    final controller = context.read<InsumoController>();
    final success = await controller.ajustarStock(
      insumoId: insumo.id!,
      cantidadText: (-insumo.stockActual).toString(),
      motivo: 'Se acabó (Ajuste a 0)',
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock de "${insumo.nombre}" ajustado a 0'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Error al ajustar stock'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Determina el color del stock basado en stock actual vs mínimo
  Color _stockColor(Insumo insumo) {
    if (insumo.stockActual <= 0) return AppColors.stockEmpty;
    if (insumo.stockActual <= insumo.stockMinimo) return AppColors.stockLow;
    return AppColors.stockOk;
  }

  /// Determina la etiqueta del estado de stock
  String _stockLabel(Insumo insumo) {
    if (insumo.stockActual <= 0) return 'Sin stock';
    if (insumo.stockActual <= insumo.stockMinimo) return 'Stock bajo';
    return 'En stock';
  }

  Widget _buildInsumoCard(Insumo insumo) {
    final stockColor = _stockColor(insumo);
    final hasPhoto = insumo.fotoRuta != null && insumo.fotoRuta!.isNotEmpty;
    final esPaquete = insumo.unidadMedida == 'Paquetes';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: stockColor.withValues(alpha: 0.5), width: 1.5),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: hasPhoto
                  ? Image.file(File(insumo.fotoRuta!), width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64, height: 64,
                      color: AppColors.surfaceVariant,
                      child: Icon(Icons.inventory_2_outlined, color: AppColors.secondary, size: 32),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(insumo.nombre, style: AppTextStyles.sectionTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      AppStatusChip(label: _stockLabel(insumo), color: stockColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insumo.tipoInsumo,
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.inventory, size: 14, color: stockColor),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${insumo.stockActual.toStringAsFixed(2)} ${insumo.unidadMedida}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: stockColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Mínimo: ${insumo.stockMinimo.toStringAsFixed(2)} ${insumo.unidadMedida}',
                    style: AppTextStyles.caption,
                  ),
                  if (esPaquete)
                    Text(
                      '${insumo.contenidoPaquete} unidades por paquete',
                      style: AppTextStyles.caption.copyWith(color: AppColors.info),
                    ),
                ],
              ),
            ),
            // Menú 3 puntos
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              onSelected: (val) {
                switch (val) {
                  case 'edit':
                    _abrirFormulario(insumo: insumo);
                  case 'comprar':
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ComprasScreen()));
                  case 'cero':
                    _confirmarSeAcabo(insumo);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                    title: Text('Editar insumo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'comprar',
                  child: ListTile(
                    leading: Icon(Icons.shopping_cart_outlined, color: AppColors.secondary),
                    title: Text('Comprar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'cero',
                  child: ListTile(
                    leading: Icon(Icons.remove_circle_outline, color: AppColors.warning),
                    title: Text('Se acabó', style: TextStyle(color: AppColors.warning)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InsumoController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventario de Insumos'),
            backgroundColor: AppColors.secondary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: ctrl.loadInsumos,
              ),
            ],
          ),
          body: ctrl.isLoading
              ? const AppLoadingState(message: 'Cargando insumos...')
              : ctrl.insumos.isEmpty
                  ? AppEmptyState(
                      message: 'No hay insumos registrados.\nAgrega el primero con el botón +',
                      icon: Icons.inventory_2_outlined,
                      actionLabel: 'Agregar insumo',
                      onAction: () => _abrirFormulario(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100, top: AppSpacing.sm),
                      itemCount: ctrl.insumos.length,
                      itemBuilder: (_, i) => _buildInsumoCard(ctrl.insumos[i]),
                    ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.secondary,
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Insumo'),
          ),
        );
      },
    );
  }
}
