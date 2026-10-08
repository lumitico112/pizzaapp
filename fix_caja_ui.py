import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/caja/cierre_caja_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_cerrado = """          if (controller.cierreDiario != null && controller.cierreDiario!.cerrado == 1)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                color: AppColors.error,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: AppColors.surface),
                      SizedBox(width: 16),
                      Expanded(child: Text('CAJA CERRADA. Ya no se pueden realizar más ventas ni gastos hoy.', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
            ),"""

new_cerrado = """          if (controller.cierreDiario != null && controller.cierreDiario!.cerrado == 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: AppColors.error,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock, color: AppColors.surface),
                          SizedBox(width: 16),
                          Expanded(child: Text('CAJA CERRADA. Ya no se pueden realizar ventas ni gastos hoy.', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: AppColors.error),
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Reabrir Caja (Requiere PIN)'),
                        onPressed: () => _mostrarDialogoReabrir(context, controller),
                      )
                    ],
                  ),
                ),
              ),
            ),"""

text = text.replace(old_cerrado, new_cerrado)

dialog_code = """
  void _mostrarDialogoReabrir(BuildContext context, CajaController controller) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir Caja'),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'PIN de Administrador', hintText: 'Ej: 1234'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              // PIN hardcodeado para el admin (se puede conectar a la DB luego)
              if (pinCtrl.text == '1234' || pinCtrl.text == 'admin') {
                Navigator.pop(ctx);
                await controller.reabrirCaja();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caja reabierta. Puedes continuar operando.'), backgroundColor: AppColors.success));
              } else {
                Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
  }

  @override
"""

text = text.replace("  @override\n  Widget build(BuildContext context) {", dialog_code + "  Widget build(BuildContext context) {")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
