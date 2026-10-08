import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/screens/catalogo/producto_form_screen.dart';
import 'package:pizzaapp/screens/catalogo/receta_screen.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/primary_button.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoController>().loadProductos();
    });
  }

  void _showAddProductoModal() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const ProductoFormScreen())
    );
    if (result == true && mounted) {
      context.read<ProductoController>().loadProductos();
    }
  }

  void _editProducto(Producto p) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => ProductoFormScreen(productoAEditar: p))
    );
    if (result == true && mounted) {
      context.read<ProductoController>().loadProductos();
    }
  }

  void _deleteProducto(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('Se eliminará este producto y todas sus variantes. ¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProductoController>().eliminarProducto(id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
            }, 
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      )
    );
  }

  void _verOpciones(Producto prod) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Editar Producto', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(ctx);
                _editProducto(prod);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.success),
              title: const Text('Ficha Técnica (Receta)', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => RecetaScreen(producto: prod)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Eliminar Producto', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteProducto(prod.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductoController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Catálogo de Productos'),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddProductoModal,
              )
            ],
          ),
          body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.productos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No hay productos', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Crear mi primer producto',
                        onPressed: _showAddProductoModal,
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: controller.productos.length,
                  itemBuilder: (context, index) {
                    final Producto prod = controller.productos[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _verOpciones(prod),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  image: prod.fotoRuta != null 
                                    ? DecorationImage(image: FileImage(File(prod.fotoRuta!)), fit: BoxFit.cover)
                                    : null
                                ),
                                child: prod.fotoRuta == null ? const Icon(Icons.fastfood, color: AppColors.primary) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    if (prod.descripcion != null && prod.descripcion!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(prod.descripcion!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                                      ),
                                    const SizedBox(height: 4),
                                    Text('Tipo: ${prod.tipoPreparacion.toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.more_vert, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
