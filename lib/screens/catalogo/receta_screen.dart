import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/models/receta.dart'; // Ensure imported
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/receta_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

class RecetaScreen extends StatefulWidget {
  final Producto producto;
  const RecetaScreen({super.key, required this.producto});

  @override
  State<RecetaScreen> createState() => _RecetaScreenState();
}

class _RecetaScreenState extends State<RecetaScreen> {
  VarianteProducto? _varianteSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoController>().loadInsumos();
      _loadVariantes();
    });
  }

  Future<void> _loadVariantes() async {
    final vars = await context.read<ProductoController>().obtenerVariantes(widget.producto.id!);
    if (vars.isNotEmpty && mounted) {
      setState(() => _varianteSeleccionada = vars.first);
      context.read<RecetaController>().loadReceta(_varianteSeleccionada!.id!);
    }
  }

  void _abrirModalAdd() {
    final insumos = context.read<InsumoController>().insumos.where((i) => i.activo == 1).toList();
    int? insumoSelec;
    final cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Agregar Insumo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Selecciona un insumo'),
                  items: insumos.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.nombre} (${i.unidadMedida})'))).toList(),
                  onChanged: (val) => setDialogState(() => insumoSelec = val),
                  value: insumoSelec,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cantidadCtrl,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (insumoSelec == null || cantidadCtrl.text.isEmpty) return;
                  final insumoUnit = insumos.firstWhere((i) => i.id == insumoSelec).unidadMedida;
                  final success = await context.read<RecetaController>().agregarInsumo(
                    varianteId: _varianteSeleccionada!.id!, 
                    insumoId: insumoSelec!, 
                    cantidadText: cantidadCtrl.text,
                    unidadMedida: insumoUnit, // Using base unit
                  );
                  if (success && mounted) Navigator.pop(ctx);
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final recetaCtrl = context.watch<RecetaController>();

    return Scaffold(
      appBar: AppBar(title: Text('Receta: ${widget.producto.nombre}')),
      body: Column(
        children: [
          Expanded(
            child: recetaCtrl.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: recetaCtrl.recetaActual.length,
                  itemBuilder: (ctx, i) {
                    final item = recetaCtrl.recetaActual[i];
                    return ListTile(
                      title: Text(item.insumoNombre ?? 'Insumo'),
                      subtitle: Text('Cantidad: ${item.cantidad} ${item.unidadMedida}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => recetaCtrl.eliminarInsumo(_varianteSeleccionada!.id!, item.id!),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
