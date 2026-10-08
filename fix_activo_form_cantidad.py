import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final _obsCtrl = TextEditingController();", "final _obsCtrl = TextEditingController();\n  final _cantidadCtrl = TextEditingController(text: '1');")
text = text.replace("_obsCtrl.dispose();", "_obsCtrl.dispose();\n    _cantidadCtrl.dispose();")

# Inject _cantidadCtrl.text = a.cantidad.toString();
text = text.replace("_cuotasCtrl.text = a.cuotas.toString();", "_cuotasCtrl.text = a.cuotas.toString();\n      _cantidadCtrl.text = a.cantidad.toString();")

# the object creation
old_obj = """      metodoPago: _metodoPago,
      cuotas: cuotas,"""
new_obj = """      metodoPago: _metodoPago,
      cuotas: cuotas,
      cantidad: int.tryParse(_cantidadCtrl.text) ?? 1,"""
text = text.replace(old_obj, new_obj)

# The UI field
old_ui = """                  AppTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre del Activo (Ej: Horno pizzero)',
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),"""
new_ui = """                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppTextField(
                          controller: _nombreCtrl,
                          label: 'Nombre del Activo',
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: AppTextField(
                          controller: _cantidadCtrl,
                          label: 'Cant.',
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Req' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),"""
text = text.replace(old_ui, new_ui)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
