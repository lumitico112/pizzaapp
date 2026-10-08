import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("ok = await ctrl.agregarActivo(obj);", "double adelanto = double.tryParse(_adelantoCtrl.text) ?? 0;\n      ok = await ctrl.agregarActivo(obj, adelanto);")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
