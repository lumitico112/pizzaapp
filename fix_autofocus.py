import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/categorias/categorias_activo_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("autofocus: true,", "")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
