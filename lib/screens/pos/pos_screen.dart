import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/widgets/app_date_picker.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_cart_summary.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_product_grid.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_category_filter.dart';

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
                      title: const Text('De cortesÃ­a'),
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

    void _showCobroModal() async {
    final controller = context.read<PosController>();
    if (controller.carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El carrito esta vacio')));
      return;
    }

    final configRepo = ConfiguracionRepository();
    final qrRuta = await configRepo.getConfig('qr_ventas_ruta');

    String metodoSeleccionado = 'efectivo';
    final observacionesCtrl = TextEditingController();
    final pagoConCtrl = TextEditingController();

    if (!mounted) return;

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
                          onPressed: () => setModalState(() => metodoSeleccionado = 'yape'),
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
                    if (qrRuta != null)
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: ctx,
                              builder: (c) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.file(File(qrRuta), fit: BoxFit.contain),
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Image.file(File(qrRuta), height: 150, fit: BoxFit.contain),
                              const SizedBox(height: 8),
                              const Text('Toque el QR para ampliar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.warning, size: 50, color: Colors.orange),
                            SizedBox(height: 8),
                            Text('El QR de ventas no está configurado.\nEl administrador debe agregarlo en su perfil.', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange)),
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
                        metodoSeleccionado == 'yape/plin' ? 'yape' : metodoSeleccionado,
                        observacionesCtrl.text.trim(),
                      );
                      
                      if (!mounted) return;
                      if (!ctx.mounted) return;
                      if (result != null) {
                        Navigator.pop(ctx); 
                        _mostrarAnimacionExito();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<PosController>().error ?? 'Error'), backgroundColor: AppColors.error));
                      }
                    },
                    child: context.watch<PosController>().isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CONFIRMAR PAGO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarAnimacionExito() async {
    // Audio removido temporalmente porque en Android tira error el UrlSource

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/success.json',
              width: 200,
              height: 200,
              repeat: false,
            ),
            const SizedBox(height: 16),
            const Text('¡Pago Confirmado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(c);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
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
                tooltip: 'Pre-preparaciÃ³n',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroPreparacionScreen())),
              ),
            ],
          ),
          body: controller.isLoading && controller.posItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Filtro Categorias
                  PosCategoryFilter(controller: controller),
                  
                  // Grid de Productos
                  Expanded(
                    child: PosProductGrid(
                      controller: controller,
                      onItemTapped: _onPosItemTapped,
                    ),
                  ),

                  // Resumen de Carrito Fijo Abajo
                  PosCartSummary(
                    controller: controller,
                    onCobrar: _showCobroModal,
                  ),
                ],
              ),
        );
      },
    );
  }
}



