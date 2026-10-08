import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';
import 'package:pizzaapp/models/producto.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  DateTime? _fechaVentaAnterior;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosController>().loadInitialData();
    });
  }

  void _showVentasAnterioresModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Ventas Anteriores'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Seleccione la fecha para registrar ventas retroactivas:'),
                const SizedBox(height: 16),
                AppDatePicker(
                  label: 'Fecha Venta',
                  selectedDate: _fechaVentaAnterior ?? DateTime.now(),
                  onDateChanged: (d) {
                    setDialogState(() => _fechaVentaAnterior = d);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Aplicar Fecha'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onPosItemTapped(PosItem item) {
    int cantidad = 1;
    bool deCortesia = false;
    
    // Identificar si la categoria es de bebida
    final categorias = context.read<PosController>().categorias;
    final catIndex = categorias.indexWhere((c) => c.id == item.producto.categoriaId);
    final isBebida = catIndex >= 0 && categorias[catIndex].nombre.toLowerCase().contains('bebida');

    final precioController = TextEditingController(text: item.variante.precioVenta.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final p = double.tryParse(precioController.text) ?? 0.0;
          final precioFinal = deCortesia ? 0.0 : p;
          final subtotal = precioFinal * cantidad;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20, left: 20, right: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.variante.imagen != null || item.producto.fotoRuta != null)
                    ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: Image.file(
                        File(item.variante.imagen ?? item.producto.fotoRuta!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text('${item.producto.nombre} - ${item.variante.nombreVariante}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio (Editable)', border: OutlineInputBorder()),
                    onChanged: (v) => setModalState(() {}),
                  ),
                  if (isBebida) ...[
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('De cortesía'),
                      value: deCortesia,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setModalState(() => deCortesia = v ?? false),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 40, color: AppColors.error),
                        onPressed: () {
                          if (cantidad > 1) setModalState(() => cantidad--);
                        },
                      ),
                      const SizedBox(width: 16),
                      Text('$cantidad', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 40, color: AppColors.success),
                        onPressed: () => setModalState(() => cantidad++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Subtotal: S/ ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      final newVariante = VarianteProducto(
                        id: item.variante.id,
                        productoId: item.variante.productoId,
                        nombreVariante: item.variante.nombreVariante,
                        precioVenta: precioFinal,
                        costoEstimadoManual: item.variante.costoEstimadoManual,
                        empaqueInsumoId: item.variante.empaqueInsumoId,
                        imagen: item.variante.imagen,
                        stock: item.variante.stock,
                      );
                      final customItem = PosItem(item.producto, newVariante);

                      context.read<PosController>().agregarAlCarrito(customItem, cantidad);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Agregar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCobroModal() {
    final controller = context.read<PosController>();
    if (controller.carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El carrito esta vacio')));
      return;
    }

    String metodoSeleccionado = 'efectivo';
    final observacionesCtrl = TextEditingController();
    final pagoConCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isEfectivo = metodoSeleccionado == 'efectivo';
          final pagoCon = double.tryParse(pagoConCtrl.text) ?? 0.0;
          final vuelto = pagoCon - controller.granTotal;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20, left: 20, right: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Procesar Cobro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const Divider(),
                  ...controller.carrito.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${c.cantidad}x ${c.esPromocion ? c.nombrePromocion : c.producto?.nombre}'),
                        Text('S/ ${c.total.toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
                  const Divider(),
                  Text('Total a cobrar: S/ ${controller.granTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success)),
                  const SizedBox(height: 20),
                  const Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEfectivo ? AppColors.primaryDark : Colors.grey.shade300,
                            foregroundColor: isEfectivo ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => metodoSeleccionado = 'efectivo'),
                          icon: const Icon(Icons.money),
                          label: const Text('Efectivo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isEfectivo ? AppColors.primaryDark : Colors.grey.shade300,
                            foregroundColor: !isEfectivo ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setModalState(() => metodoSeleccionado = 'yape/plin'),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Yape/Plin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isEfectivo) ...[
                    TextField(
                      controller: pagoConCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Se pagó con (S/)', border: OutlineInputBorder()),
                      onChanged: (v) => setModalState(() {}),
                    ),
                    const SizedBox(height: 10),
                    if (pagoCon > 0 && vuelto >= 0)
                      Text('Su vuelto es de: S/ ${vuelto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold))
                    else if (pagoCon > 0 && vuelto < 0)
                      const Text('Monto insuficiente', style: TextStyle(color: AppColors.error)),
                  ] else ...[
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_2, size: 100, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text('Pida al cliente que escanee el QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: observacionesCtrl,
                    decoration: const InputDecoration(labelText: 'Observaciones / Notas de venta', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      if (isEfectivo && pagoCon > 0 && vuelto < 0) return;
                      
                      final result = await context.read<PosController>().procesarCobro(
                        metodoSeleccionado,
                        observacionesCtrl.text.trim(),
                        // Opcional: si el controller soporta fecha retroactiva
                        // fecha: _fechaVentaAnterior 
                      );
                      
                      if (!context.mounted) return;
                      if (result == true) {
                        Navigator.pop(ctx); // Cierra modal de cobro
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Row(children: [Icon(Icons.check_circle, color: AppColors.success), SizedBox(width: 8), Text('¡Éxito!')]),
                            content: const Text('Venta registrada con éxito.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                child: const Text('[Ver Boleta PDF]'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<PosController>().error ?? 'Error'), backgroundColor: AppColors.error));
                      }
                    },
                    child: context.watch<PosController>().isLoading 
                      ? const CircularProgressIndicator(color: AppColors.surface)
                      : const Text('CONFIRMAR COBRO', style: TextStyle(fontSize: 18, color: AppColors.surface, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PosController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Ventas (POS)'),
                if (_fechaVentaAnterior != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: AppRadius.smAll),
                    child: Text(
                      AppDateUtils.formatDisplay(_fechaVentaAnterior!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Ventas Anteriores',
                onPressed: _showVentasAnterioresModal,
              ),
              IconButton(
                icon: const Icon(Icons.blender),
                tooltip: 'Pre-preparación',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroPreparacionScreen())),
              ),
            ],
          ),
          body: controller.isLoading && controller.posItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Filtro Categorias
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        ChoiceChip(
                          label: const Text('Promociones'),
                          selected: controller.categoriaSeleccionada == -1,
                          onSelected: (v) => controller.filtrarPorCategoria(-1),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Todo'),
                          selected: controller.categoriaSeleccionada == null,
                          onSelected: (v) => controller.filtrarPorCategoria(null),
                        ),
                        const SizedBox(width: 8),
                        ...controller.categorias.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.nombre),
                            selected: controller.categoriaSeleccionada == c.id,
                            onSelected: (v) => controller.filtrarPorCategoria(c.id),
                          ),
                        )),
                      ],
                    ),
                  ),

                  // Grid de Productos
                  Expanded(
                    child: controller.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : controller.posItems.isEmpty 
                        ? const Center(child: Text('No hay productos en esta categoria.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: controller.posItems.length,
                            itemBuilder: (ctx, i) {
                              final item = controller.posItems[i];
                              return GestureDetector(
                                onTap: () => _onPosItemTapped(item),
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                                  elevation: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: (item.variante.imagen != null) 
                                            ? Image.file(File(item.variante.imagen!), fit: BoxFit.cover)
                                            : (item.producto.fotoRuta != null 
                                              ? Image.file(File(item.producto.fotoRuta!), fit: BoxFit.cover)
                                              : Container(color: AppColors.background, child: const Icon(Icons.fastfood, size: 40, color: AppColors.primary))),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(item.variante.nombreVariante, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('S/ ${item.variante.precioVenta.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15)),
                                                if (item.producto.tipoPreparacion == 'anticipado')
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: item.variante.stock > 0 ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                                    child: Text('Stk: ${item.variante.stock}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.variante.stock > 0 ? Colors.green.shade800 : Colors.red.shade800)),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Resumen de Carrito Fijo Abajo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lista mini de items
                        if (controller.carrito.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              itemCount: controller.carrito.length,
                              itemBuilder: (ctx, i) {
                                final cItem = controller.carrito[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(cItem.esPromocion ? 'PROMO: ${cItem.nombrePromocion}' : '${cItem.producto!.nombre} - ${cItem.variante!.nombreVariante}'),
                                  subtitle: Text(cItem.esPromocion ? '${cItem.cantidad} x S/ ${cItem.precioPromocion?.toStringAsFixed(2)}' : '${cItem.cantidad} x S/ ${cItem.variante!.precioVenta.toStringAsFixed(2)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('S/ ${cItem.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                        onPressed: () => controller.removerDelCarrito(cItem),
                                      )
                                    ],
                                  ),
                                );
                              }
                            ),
                          ),
                        if (controller.carrito.isNotEmpty) const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                Text('S/ ${controller.granTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: controller.carrito.isEmpty ? null : _showCobroModal,
                              icon: const Icon(Icons.payment, color: AppColors.surface),
                              label: const Text('COBRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.surface)),
                            )
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
        );
      },
    );
  }
}
