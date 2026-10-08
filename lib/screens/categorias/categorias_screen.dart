import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/categoria_producto_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_text_field.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaProductoController>().loadCategorias();
    });
  }

  void _abrirFormulario({Categoria? categoria}) {
    final nameCtrl = TextEditingController(text: categoria?.nombre ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
        content: AppTextField(
          controller: nameCtrl,
          label: 'Nombre de la Categoría',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final controller = context.read<CategoriaProductoController>();
              final success = await controller.guardarCategoria(
                id: categoria?.id, 
                nombre: nameCtrl.text.trim()
              );
              
              if (!mounted) return;
              if (success) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado correctamente'), backgroundColor: AppColors.success));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.error ?? 'Error'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  void _eliminar(Categoria cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Seguro que deseas eliminar "${cat.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );
    if (confirm == true && mounted) {
      await context.read<CategoriaProductoController>().eliminarCategoria(cat.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriaProductoController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Categorías de Productos'),
            backgroundColor: AppColors.secondary,
          ),
          body: controller.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : controller.categorias.isEmpty 
              ? const Center(child: Text('No hay categorías registradas.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: controller.categorias.length,
                  itemBuilder: (ctx, i) {
                    final cat = controller.categorias[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.category, color: AppColors.secondary),
                        ),
                        title: Text(cat.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () => _abrirFormulario(categoria: cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _eliminar(cat),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.secondary,
            onPressed: () => _abrirFormulario(),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
