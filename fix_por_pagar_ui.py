import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/compras/por_pagar_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("void _confirmarPago(int cuentaId, String nombre, double costoTotal) {", "void _confirmarPago(int cuentaId, String nombre, double costoTotal, double montoPagado) {")

old_dialog = """    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Confirmar Pago?'),
        content: Text('¿Confirmas el pago de ${CurrencyFormatter.format(costoTotal)} por $nombre?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<PorPagarController>().pagarCuenta(cuentaId);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado'), backgroundColor: AppColors.success));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<PorPagarController>().error ?? 'Error'), backgroundColor: AppColors.error));
              }
            }, 
            child: const Text('Sí, pagar')
          ),
        ],
      )
    );"""
new_dialog = """    final restante = costoTotal - montoPagado;
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
    );"""
text = text.replace(old_dialog, new_dialog)

text = text.replace("final cuenta = controller.cuentas[index];", "final cuenta = controller.cuentas[index];\n                    final restante = cuenta.costoTotal - cuenta.montoPagado;")
text = text.replace("Text(CurrencyFormatter.format(cuenta.costoTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),", "Text('${CurrencyFormatter.format(restante)} pendiente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),\n                                        Text('Total: ${CurrencyFormatter.format(cuenta.costoTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),")
text = text.replace("onPressed: () => _confirmarPago(cuenta.id!, cuenta.motivo ?? 'Compra', cuenta.costoTotal),", "onPressed: () => _confirmarPago(cuenta.id!, cuenta.motivo ?? 'Compra', cuenta.costoTotal, cuenta.montoPagado),")

# Fix missing import for formatters if needed? Already imported.

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
