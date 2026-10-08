import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/categoria_activo_controller.dart';
import 'package:pizzaapp/models/categoria_activo.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_text_field.dart';

class CategoriasActivoScreen extends StatefulWidget {
  const CategoriasActivoScreen({super.key});

  @override
  State<CategoriasActivoScreen> createState() => _CategoriasActivoScreenState();
}

class _CategoriasActivoScreenState extends State<CategoriasActivoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaActivoController>().loadCategorias();
    });
  }

  void _mostrarFormulario([CategoriaActivo? categoria]) {
    final nombreCtrl = TextEditingController(text: categoria?.nombre);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
        content: AppTextField(
          controller: nombreCtrl,
          label: 'Nombre de la categoría',
          
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isNotEmpty) {
                final cat = CategoriaActivo(id: categoria?.id, nombre: nombre);
                Navigator.pop(ctx);
                final res = await context.read<CategoriaActivoController>().guardarCategoria(cat);
                if (!res && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<CategoriaActivoController>().error ?? 'Error')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminar(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: const Text('¿Estás seguro de eliminar esta categoría?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (conf == true && mounted) {
      await context.read<CategoriaActivoController>().eliminarCategoria(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Activos'),
        backgroundColor: Colors.brown,
      ),
      body: Consumer<CategoriaActivoController>(
        builder: (context, ctrl, child) {
          if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
          if (ctrl.categorias.isEmpty) return const Center(child: Text('No hay categorías registradas'));

          return ListView.builder(
            itemCount: ctrl.categorias.length,
            itemBuilder: (ctx, i) {
              final cat = ctrl.categorias[i];
              return ListTile(
                title: Text(cat.nombre),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _mostrarFormulario(cat)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminar(cat.id!)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
