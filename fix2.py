import sys, re

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/catalogo/producto_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r'const SizedBox\(height: 16\);\s*items: const \[\s*DropdownMenuItem.*?\}\s*\),\s*},\s*\)\s*\]\s*,\s*onChanged.*?,\s*\)', '', text, flags=re.DOTALL)
# Actually, let's just find "items: const [" and delete until the first "const SizedBox(height: 32)"

text = re.sub(r'items: const \[\s*DropdownMenuItem.*?onChanged:.*?,\s*\)', '', text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
