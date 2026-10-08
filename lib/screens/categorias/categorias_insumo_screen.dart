import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/categoria_insumo.dart';
import 'package:pizzaapp/controllers/categoria_insumo_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/core/widgets/app_confirm_dialog.dart';

class CategoriasInsumoScreen extends StatefulWidget {
  const CategoriasInsumoScreen({super.key});

  @override
  State<CategoriasInsumoScreen> createState() => _CategoriasInsumoScreenState();
}

class _CategoriasInsumoScreenState extends State<CategoriasInsumoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaInsumoController>().loadCategorias();
    });
  }

  void _abrirFormulario() {
    final nameCtrl = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nueva Categoría de Insumo'),
              content: TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (Ej: Ingrediente)'),
                autofocus: true,
                enabled: !isSaving,
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx), 
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                  onPressed: isSaving ? null : () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setState(() => isSaving = true);
                    
                    final controller = context.read<CategoriaInsumoController>();
                    final errorMsg = await controller.guardarCategoria(nameCtrl.text.trim());
                    
                    if (!mounted) return;
                    
                    if (errorMsg == null) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Categoría creada'), backgroundColor: AppColors.success)
                      );
                    } else {
                      setState(() => isSaving = false);
                      if (errorMsg == 'La categoría ya existe.') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.warning)
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error)
                        );
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text('Guardar', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _eliminar(CategoriaInsumo cat) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Eliminar Categoría',
      message: '¿Seguro que deseas eliminar \${cat.nombre}?',
      confirmLabel: 'Eliminar',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline,
    );
    
    if (confirm) {
      if (!mounted) return;
      await context.read<CategoriaInsumoController>().eliminarCategoria(cat.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriaInsumoController>(
      builder: (context, controller, child) {
        final categorias = controller.categorias;
        final isLoading = controller.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Categorías de Insumos'),
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
          body: isLoading 
            ? const AppLoadingState(message: 'Cargando categorías...')
            : categorias.isEmpty 
              ? const AppEmptyState(
                  message: 'No hay categorías registradas.', 
                  icon: Icons.category_outlined,
                )
              : ListView.separated(
                  itemCount: categorias.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                  itemBuilder: (ctx, i) {
                    final cat = categorias[i];
                    return ListTile(
                      title: Text(cat.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => _eliminar(cat),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            onPressed: _abrirFormulario,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
