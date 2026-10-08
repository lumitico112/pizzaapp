import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activos_fijos_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_subtitle = "Text(a.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis)"
new_subtitle = "Text('${a.condicion} - ${a.descripcion}', maxLines: 2, overflow: TextOverflow.ellipsis)"
text = text.replace(old_subtitle, new_subtitle)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
