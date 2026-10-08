import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activos_fijos_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add "reparar" to the popup
old_popup = """                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],"""
new_popup = """                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem(value: 'reparar', child: Text('Registrar Reparación')),
                                const PopupMenuItem(value: 'delete', child: Text('Dar de baja (Eliminar)')),
                              ],"""
text = text.replace(old_popup, new_popup)

# Handle select
old_select = """                            onSelected: (val) {
                              if (val == 'edit') {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ActivoFijoFormScreen(activoAEditar: a))).then((_) {
                                  if (context.mounted) controller.loadActivos();
                                });
                              } else if (val == 'delete') {
                                _eliminarActivo(context, controller, a.id!);
                              }
                            },"""
new_select = """                            onSelected: (val) {
                              if (val == 'edit') {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ActivoFijoFormScreen(activoAEditar: a))).then((_) {
                                  if (context.mounted) controller.loadActivos();
                                });
                              } else if (val == 'reparar') {
                                _mostrarDialogoReparacion(context, controller, a);
                              } else if (val == 'delete') {
                                _eliminarActivo(context, controller, a.id!);
                              }
                            },"""
text = text.replace(old_select, new_select)

# Add the dialog function inside the build or just before build, let's put it before _eliminarActivo
new_dialog = """  void _mostrarDialogoReparacion(BuildContext context, ActivoFijoController controller, ActivoFijo activo) {
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
            onPressed: () async {
              final costo = double.tryParse(costoCtrl.text) ?? 0;
              if (costo > 0) {
                Navigator.pop(ctx);
                final ok = await controller.registrarReparacion(activo, costo, descCtrl.text.trim());
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

  void _eliminarActivo(BuildContext context, ActivoFijoController controller, int id) async {"""

text = text.replace("  void _eliminarActivo(BuildContext context, ActivoFijoController controller, int id) async {", new_dialog)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
