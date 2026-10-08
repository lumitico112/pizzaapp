import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activos_fijos_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_menu = """                                    onSelected: (val) {
                                      if (val == 'edit') _openForm(activo: a);
                                      if (val == 'delete') _eliminar(a);
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                      const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                    ],"""

new_menu = """                                    onSelected: (val) {
                                      if (val == 'edit') _openForm(activo: a);
                                      if (val == 'reparar') _mostrarDialogoReparacion(context, a);
                                      if (val == 'delete') _eliminar(a);
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                      const PopupMenuItem(value: 'reparar', child: Text('Registrar Reparación')),
                                      const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                    ],"""

text = text.replace(old_menu, new_menu)

new_method = """
  void _mostrarDialogoReparacion(BuildContext context, ActivoFijo activo) {
    final costoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Reparación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esto registrará un gasto por mantenimiento.'),
            const SizedBox(height: 16),
            TextField(controller: costoCtrl, decoration: const InputDecoration(labelText: 'Costo (S/)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Detalle del arreglo', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            onPressed: () async {
              final costo = double.tryParse(costoCtrl.text) ?? 0;
              if (costo > 0) {
                Navigator.pop(ctx);
                final ok = await context.read<ActivoFijoController>().registrarReparacion(activo, costo, descCtrl.text.trim());
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reparación y Gasto registrados')));
                }
              }
            },
            child: const Text('Registrar'),
          )
        ],
      ),
    );
  }

  void _eliminar(ActivoFijo activo) async {"""

text = text.replace("  void _eliminar(ActivoFijo activo) async {", new_method)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
