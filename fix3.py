import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/catalogo/producto_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('const SizedBox(height: 16),\n              ,', '')
text = text.replace('const SizedBox(height: 16);\n              ,', '')
text = text.replace('const SizedBox(height: 16);\r\n              ,', '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
