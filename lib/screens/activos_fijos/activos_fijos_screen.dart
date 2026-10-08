import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/activo_fijo.dart';
import 'package:pizzaapp/controllers/activo_fijo_controller.dart';
import 'package:pizzaapp/screens/activos_fijos/activo_fijo_form_screen.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/core/widgets/app_confirm_dialog.dart';

class ActivosFijosScreen extends StatefulWidget {
  const ActivosFijosScreen({super.key});

  @override
  State<ActivosFijosScreen> createState() => _ActivosFijosScreenState();
}

class _ActivosFijosScreenState extends State<ActivosFijosScreen> {
  String _filtroActual = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivoFijoController>().loadActivos();
    });
  }

  void _openForm({ActivoFijo? activo}) async {
    final res = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => ActivoFijoFormScreen(activoAEditar: activo))
    );
    if (res == true && mounted) {
      context.read<ActivoFijoController>().loadActivos();
    }
  }

  void _eliminar(ActivoFijo activo) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Eliminar activo',
      message: '¿Seguro que deseas eliminar el activo "${activo.nombre}"?',
      confirmLabel: 'Eliminar',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline,
    );
    
    if (confirm == true && mounted) {
      await context.read<ActivoFijoController>().eliminarActivo(activo.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activo eliminado')));
    }
  }

  void _cambiarEstadoDialog(ActivoFijo activo) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cambiar Estado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OpcionEstado(
                activo: activo, 
                estado: 'En uso', 
                color: AppColors.activoEnUso,
                ctx: ctx,
              ),
              _OpcionEstado(
                activo: activo, 
                estado: 'En reparación', 
                color: AppColors.activoEnReparacion,
                ctx: ctx,
              ),
              _OpcionEstado(
                activo: activo, 
                estado: 'Fuera de servicio', 
                color: AppColors.activoFueraServicio,
                ctx: ctx,
              ),
            ],
          ),
        );
      }
    );
  }

  Color _getColorParaEstado(String estado) {
    if (estado.toLowerCase().contains('uso') || estado.toLowerCase() == 'bueno') return AppColors.activoEnUso;
    if (estado.toLowerCase().contains('reparación') || estado.toLowerCase() == 'regular' || estado.toLowerCase().contains('reparaci')) return AppColors.activoEnReparacion;
    if (estado.toLowerCase().contains('fuera') || estado.toLowerCase() == 'malo') return AppColors.activoFueraServicio;
    return AppColors.textSecondary;
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha';
    try {
      final partes = fecha.split(' ')[0].split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    } catch (_) {}
    return fecha;
  }

  String _formatearMoneda(double monto) {
    return 'S/ ${monto.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivoFijoController>(
      builder: (context, controller, child) {
        
        List<ActivoFijo> activosFiltrados = controller.activos;
        if (_filtroActual != 'Todos') {
          activosFiltrados = activosFiltrados.where((a) {
            String e = a.estado.toLowerCase();
            if (_filtroActual == 'En uso') return e.contains('uso') || e == 'bueno';
            if (_filtroActual == 'En reparación') return e.contains('reparaci') || e == 'regular';
            if (_filtroActual == 'Fuera de servicio') return e.contains('fuera') || e == 'malo';
            return true;
          }).toList();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Activos Fijos', style: AppTextStyles.appBarTitle),
            backgroundColor: AppColors.primaryDark,
          ),
          body: Column(
            children: [
              // Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: ['Todos', 'En uso', 'En reparación', 'Fuera de servicio'].map((filtro) {
                    final isSelected = _filtroActual == filtro;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filtro),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _filtroActual = filtro);
                        },
                        selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Lista
              Expanded(
                child: controller.isLoading 
                  ? const AppLoadingState(message: 'Cargando activos fijos...')
                  : controller.activos.isEmpty 
                    ? const AppEmptyState(message: 'No hay activos fijos registrados.', icon: Icons.inventory_2_outlined)
                    : activosFiltrados.isEmpty
                      ? const AppEmptyState(message: 'No hay activos que coincidan con el filtro.', icon: Icons.filter_list_off)
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: activosFiltrados.length,
                          itemBuilder: (ctx, index) {
                            final a = activosFiltrados[index];
                            final colorEstado = _getColorParaEstado(a.estado);
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(left: BorderSide(color: colorEstado, width: 6)),
                                ),
                                child: InkWell(
                                  onTap: () => _openForm(activo: a),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Imagen
                                        Container(
                                          width: 80, height: 80,
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: AppRadius.smAll,
                                            image: a.fotoRuta != null && a.fotoRuta!.isNotEmpty
                                              ? DecorationImage(image: FileImage(File(a.fotoRuta!)), fit: BoxFit.cover)
                                              : null
                                          ),
                                          child: a.fotoRuta == null || a.fotoRuta!.isEmpty 
                                              ? const Icon(Icons.chair_alt, color: AppColors.textSecondary, size: 40) 
                                              : null,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        
                                        // Datos
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(child: Text(a.nombre, style: AppTextStyles.heading3, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    onSelected: (val) {
                                                      if (val == 'edit') _openForm(activo: a);
                                                      if (val == 'estado') _cambiarEstadoDialog(a);
                                                      if (val == 'delete') _eliminar(a);
                                                    },
                                                    itemBuilder: (ctx) => [
                                                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                                      const PopupMenuItem(value: 'estado', child: Text('Cambiar Estado')),
                                                      const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                                    ],
                                                  )
                                                ],
                                              ),
                                              Text('Categoría: ${a.categoria ?? "Sin categoría"} • Cantidad: ${a.cantidad}', style: AppTextStyles.bodySmall),
                                              const SizedBox(height: AppSpacing.xs),
                                              Text('Fecha: ${_formatearFecha(a.fechaAdquisicion)}', style: AppTextStyles.bodySmall),
                                              const SizedBox(height: AppSpacing.xs),
                                              Text('${_formatearMoneda(a.costo)} - ${a.condicion}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: AppSpacing.sm),
                                              Wrap(
                                                spacing: AppSpacing.sm,
                                                runSpacing: AppSpacing.xs,
                                                children: [
                                                  AppStatusChip(
                                                    label: a.estado, 
                                                    color: colorEstado
                                                  ),
                                                  if (a.condicion.toLowerCase() == 'alquilado')
                                                    AppStatusChip(
                                                      label: 'Alquilado (${a.metodoPago})', 
                                                      color: AppColors.info
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            onPressed: () => _openForm(),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _OpcionEstado extends StatelessWidget {
  final ActivoFijo activo;
  final String estado;
  final Color color;
  final BuildContext ctx;

  const _OpcionEstado({
    required this.activo,
    required this.estado,
    required this.color,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 8),
      title: Text(estado),
      onTap: () async {
        Navigator.pop(ctx);
        if (activo.id != null) {
          await context.read<ActivoFijoController>().cambiarEstado(activo.id!, estado);
        }
      },
    );
  }
}
