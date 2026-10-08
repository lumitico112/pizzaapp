import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_ui = """                  const SizedBox(height: 32),
                  
                  PrimaryButton(
                    text: widget.activoAEditar == null ? 'REGISTRAR ACTIVO' : 'ACTUALIZAR ACTIVO',
                    color: Colors.brown,
                    isLoading: ctrl.isLoading,
                    onPressed: _guardar,
                  ),
                  
                  if (widget.activoAEditar != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14)
                      ),
                      icon: const Icon(Icons.build),
                      label: const Text('REGISTRAR GASTO DE REPARACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _mostrarDialogoReparacion(context),
                    )
                  ],
                ],
              ),
            ),
          );
        }
      ),
    );
  }
"""

dialog_code = """
  void _mostrarDialogoReparacion(BuildContext context) {
    final costoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Reparación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esto registrará un gasto en la caja de hoy y cambiará el estado a "En reparación".'),
            const SizedBox(height: 16),
            TextField(controller: costoCtrl, decoration: const InputDecoration(labelText: 'Costo (S/)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Detalle del arreglo', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final costo = double.tryParse(costoCtrl.text) ?? 0;
              if (costo > 0) {
                Navigator.pop(ctx);
                final ok = await context.read<ActivoFijoController>().registrarReparacion(widget.activoAEditar!, costo, descCtrl.text.trim());
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reparación y Gasto registrados', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
                  setState(() { _estado = 'En reparación'; });
                }
              }
            },
            child: const Text('Confirmar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {"""

text = text.replace("                  const SizedBox(height: 32),\n                  \n                  PrimaryButton(\n                    text: widget.activoAEditar == null ? 'REGISTRAR ACTIVO' : 'ACTUALIZAR ACTIVO',\n                    color: Colors.brown,\n                    isLoading: ctrl.isLoading,\n                    onPressed: _guardar,\n                  ),\n                ],\n              ),\n            ),\n          );\n        }\n      ),\n    );\n  }", new_ui)

text = text.replace("  @override\n  Widget build(BuildContext context) {", dialog_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
