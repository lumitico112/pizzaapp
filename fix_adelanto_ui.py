import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final _cantidadCtrl = TextEditingController(text: '1');", "final _cantidadCtrl = TextEditingController(text: '1');\n  final _adelantoCtrl = TextEditingController(text: '0');")
text = text.replace("_cantidadCtrl.dispose();", "_cantidadCtrl.dispose();\n    _adelantoCtrl.dispose();")

# the UI field
old_ui = """                        if (_metodoPago == 'Crédito')
                          Expanded(
                            child: AppTextField(
                              controller: _cuotasCtrl,
                              label: 'Cuotas',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          )
                        else
                          const Spacer(),"""
new_ui = """                        if (_metodoPago == 'Crédito') ...[
                          Expanded(
                            child: AppTextField(
                              controller: _cuotasCtrl,
                              label: 'Cuotas',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _adelantoCtrl,
                              label: 'Adelanto',
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          ),
                        ] else
                          const Spacer(),"""
text = text.replace(old_ui, new_ui)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

path2 = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/activo_fijo_controller.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

text2 = text2.replace("Future<bool> agregarActivo(ActivoFijo obj)", "Future<bool> agregarActivo(ActivoFijo obj, double adelanto)")
text2 = text2.replace("await _service.registrarActivo(obj);", "await _service.registrarActivo(obj, adelanto);")

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)

