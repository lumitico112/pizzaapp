import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/preparacion_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/core/widgets/app_confirm_dialog.dart';

class RegistroPreparacionScreen extends StatefulWidget {
  final Map<int, int>? prefilledData;
  const RegistroPreparacionScreen({super.key, this.prefilledData});

  @override
  State<RegistroPreparacionScreen> createState() => _RegistroPreparacionScreenState();
}

class _RegistroPreparacionScreenState extends State<RegistroPreparacionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notaGlobalCtrl = TextEditingController();
  final Map<int, TextEditingController> _cantidadesCtrls = {}; 
  final Map<int, TextEditingController> _notasCtrls = {}; 
  final Map<int, String> _nombresVariantes = {}; 
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final controller = context.read<PreparacionController>();
    await controller.loadHistorial();
    await controller.loadProductosParaPreparacion();
    
    for (var prod in controller.productosPreHechos) {
      final vars = await controller.obtenerVariantesPorProducto(prod.id!);
      for (var v in vars) {
        _cantidadesCtrls[v.id!] = TextEditingController(text: (widget.prefilledData?[v.id!] ?? 0).toString());
        _notasCtrls[v.id!] = TextEditingController();
        _nombresVariantes[v.id!] = '${prod.nombre} - ${v.nombreVariante}';
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notaGlobalCtrl.dispose();
    for (var ctrl in _cantidadesCtrls.values) { ctrl.dispose(); }
    for (var ctrl in _notasCtrls.values) { ctrl.dispose(); }
    super.dispose();
  }

  void _guardarPreparacion() async {
    final List<Map<String, dynamic>> seleccion = [];

    _cantidadesCtrls.forEach((vid, ctrl) {
      int val = int.tryParse(ctrl.text) ?? 0;
      if (val != 0) {
        seleccion.add({
          'varianteId': vid,
          'cantidad': val,
          'notas': _notasCtrls[vid]!.text.trim().isNotEmpty ? _notasCtrls[vid]!.text.trim() : null,
        });
      }
    });

    if (seleccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay cantidades registradas')));
      return;
    }

    final success = await context.read<PreparacionController>().registrarPreparacion(
      nota: _notaGlobalCtrl.text.trim(),
      seleccion: seleccion,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PreparaciÃ³n registrada exitosamente', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
  }

  void _mostrarNotaDialog(int varianteId, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ObservaciÃ³n para $nombre'),
        content: TextField(
          controller: _notasCtrls[varianteId],
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej. Faltante por pedido especial...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PreparacionController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de PreparaciÃ³n'),
        backgroundColor: AppColors.primaryDark,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'PreparaciÃ³n Hoy', icon: Icon(Icons.blender)),
            Tab(text: 'Sobrantes / Merma', icon: Icon(Icons.inventory_2_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlatPreparacionList(ctrl),
          _buildSobrantesTab(ctrl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: ctrl.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
            label: const Text('Guardar PreparaciÃ³n', style: AppTextStyles.buttonLarge),
            onPressed: ctrl.isLoading ? null : _guardarPreparacion,
          ),
        ),
      ),
    );
  }

  Widget _buildFlatPreparacionList(PreparacionController ctrl) {
    if (ctrl.isLoading && _cantidadesCtrls.isEmpty) return const AppLoadingState(message: 'Cargando...');
    
    final varIds = _cantidadesCtrls.keys.toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: varIds.length,
            itemBuilder: (ctx, i) {
              final vid = varIds[i];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nombresVariantes[vid] ?? 'Variante ID: $vid', style: AppTextStyles.labelBold),
                            Text('Toca el icono para aÃ±adir nota', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.note_add_outlined, color: AppColors.primary),
                        onPressed: () => _mostrarNotaDialog(vid, _nombresVariantes[vid] ?? 'Variante $vid'),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                            onPressed: () {
                              int curr = int.tryParse(_cantidadesCtrls[vid]!.text) ?? 0;
                              _cantidadesCtrls[vid]!.text = (curr - 1).toString();
                            },
                          ),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: _cantidadesCtrls[vid],
                              textAlign: TextAlign.center,
                              keyboardType: const TextInputType.numberWithOptions(signed: true),
                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.success),
                            onPressed: () {
                              int curr = int.tryParse(_cantidadesCtrls[vid]!.text) ?? 0;
                              _cantidadesCtrls[vid]!.text = (curr + 1).toString();
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            controller: _notaGlobalCtrl,
            decoration: const InputDecoration(labelText: 'ObservaciÃ³n general del dÃ­a', border: OutlineInputBorder()),
          ),
        )
      ],
    );
  }

  Widget _buildSobrantesTab(PreparacionController ctrl) {
    return const AppEmptyState(message: 'No hay sobrantes registrados pendientes.', icon: Icons.check_circle_outline);
  }
}
