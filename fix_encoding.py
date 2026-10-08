import re

path = r'C:\D\ProyectoPizza\pizzaapp\lib\screens\activos_fijos\activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

content = content.replace('Categora', 'Categoría')
content = content.replace('Condicin', 'Condición')
content = content.replace('Adquisicin', 'Adquisición')
content = content.replace('Mtodo', 'Método')
content = content.replace('Crdito', 'Crédito')
content = content.replace('REPARACIN', 'REPARACIÓN')
content = content.replace('Reparacin', 'Reparación')
content = content.replace('reparacin', 'reparación')
content = content.replace('.withOpacity(', '.withValues(alpha: ')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done encoding fixes')
