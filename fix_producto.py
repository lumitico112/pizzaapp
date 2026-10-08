import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/catalogo/producto_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Change default from 'momento' to 'anticipado'
text = text.replace("String _tipoPreparacion = 'momento';", "String _tipoPreparacion = 'anticipado';")

# Find the dropdown block and remove it
import re
dropdown_pattern = re.compile(r'DropdownButtonFormField<String>\(.*?\),\s*', re.DOTALL)
text = dropdown_pattern.sub('', text)

# Just in case there is a SizedBox(height: 16) left before the Title:
# The UI has:
#   ),
#   const SizedBox(height: 16),
#   DropdownButtonFormField<String>(...
#   ),
#   
#   const SizedBox(height: 32),
#   const Text('TAMAÑOS / VARIANTES', ...

# I'll specifically replace the whole block exactly if regex doesn't match perfectly.
text = re.sub(r'const SizedBox\(height: 16\);\s*DropdownButtonFormField<String>\(.*?\);\s*', '', text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
