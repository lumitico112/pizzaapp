import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/controllers/promocion_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/app/app_router.dart';

class PromocionesScreen extends StatefulWidget {
  const PromocionesScreen({super.key});

  @override
  State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromocionController>().loadPromociones();
    });
  }

  void _abrirFormulario({Promocion? promocion}) async {
    final result = await AppRouter.push<bool>(
      context,
      AppRoutes.promocionForm,
      arguments: promocion,
    );
    if (result == true && mounted) {
      context.read<PromocionController>().loadPromociones();
    }
  }

  Widget _buildPromocionCard(Promocion promocion) {
    final isActive = promocion.activa == 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(promocion.nombre, style: AppTextStyles.sectionTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      AppStatusChip(
                        label: isActive ? 'Activa' : 'Inactiva',
                        color: isActive ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Precio: \$${promocion.precio.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (promocion.diasSemana != null && promocion.diasSemana!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text('Días: ${promocion.diasSemana}', style: AppTextStyles.caption),
                      ],
                    ),
                  if (promocion.horaInicio != null && promocion.horaFin != null)
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text('${promocion.horaInicio} - ${promocion.horaFin}', style: AppTextStyles.caption),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => _abrirFormulario(promocion: promocion),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromocionController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Promociones'),
            backgroundColor: AppColors.secondary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: ctrl.loadPromociones,
              ),
            ],
          ),
          body: ctrl.isLoading
              ? const AppLoadingState(message: 'Cargando promociones...')
              : ctrl.promociones.isEmpty
                  ? AppEmptyState(
                      message: 'No hay promociones registradas.\nAgrega la primera con el botón +',
                      icon: Icons.local_offer_outlined,
                      actionLabel: 'Crear Promoción',
                      onAction: () => _abrirFormulario(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100, top: AppSpacing.sm),
                      itemCount: ctrl.promociones.length,
                      itemBuilder: (_, i) => _buildPromocionCard(ctrl.promociones[i]),
                    ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.secondary,
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Promoción'),
          ),
        );
      },
    );
  }
}
