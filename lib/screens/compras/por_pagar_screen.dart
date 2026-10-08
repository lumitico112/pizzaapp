import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/por_pagar_controller.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

class PorPagarScreen extends StatefulWidget {
  const PorPagarScreen({super.key});

  @override
  State<PorPagarScreen> createState() => _PorPagarScreenState();
}

class _PorPagarScreenState extends State<PorPagarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PorPagarController>().loadCuentas();
    });
  }

  void _verFactura(String ruta) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: const Text('Factura'), automaticallyImplyLeading: false,
                   actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]),
            InteractiveViewer(child: Image.file(File(ruta))),
          ],
        ),
      )
    );
  }

  void _confirmarPago(int cuentaId, String nombre, double costoTotal, double montoPagado) {
    final restante = costoTotal - montoPagado;
    final ctrl = TextEditingController(text: restante.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Abono/Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deuda total: ${CurrencyFormatter.format(costoTotal)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Falta pagar: ${CurrencyFormatter.format(restante)}', style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Monto a abonar', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final abono = double.tryParse(ctrl.text) ?? 0;
              if (abono <= 0) return;
              
              Navigator.pop(ctx);
              final success = await context.read<PorPagarController>().pagarCuenta(cuentaId, abono);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abono registrado en Gastos'), backgroundColor: AppColors.success));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<PorPagarController>().error ?? 'Error'), backgroundColor: AppColors.error));
              }
            }, 
            child: const Text('Confirmar')
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PorPagarController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cuentas por Pagar'),
            backgroundColor: AppColors.error,
          ),
          body: controller.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : controller.cuentas.isEmpty 
              ? const Center(child: Text('No hay cuentas pendientes.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: controller.cuentas.length,
                  itemBuilder: (context, index) {
                    final c = controller.cuentas[index];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: c.pagado ? AppColors.success : AppColors.error, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('Insumo: ${c.insumoNombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Text(c.pagado ? 'PAGADO' : 'PENDIENTE', 
                                  style: TextStyle(color: c.pagado ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Fecha: ${DateFormatter.formatFechaHora(c.fecha)}'),
                            const SizedBox(height: 4),
                            Text('Deuda Total: ${CurrencyFormatter.format(c.costoTotal)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (c.facturaRuta != null)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.receipt),
                                    label: const Text('Ver Factura'),
                                    onPressed: () => _verFactura(c.facturaRuta!),
                                  ),
                                const SizedBox(width: 8),
                                if (!c.pagado)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                    icon: const Icon(Icons.check_circle, color: Colors.white),
                                    label: const Text('MARCAR PAGADO', style: TextStyle(color: Colors.white)),
                                    onPressed: () => _confirmarPago(c.id, c.insumoNombre, c.costoTotal, c.montoPagado),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      }
    );
  }
}
