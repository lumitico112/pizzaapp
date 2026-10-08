import os
import re

lib_path = 'C:/D/ProyectoPizza/pizzaapp/lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if r'\${' in content:
                print(f"Fixing {filepath}")
                content = content.replace(r'\${', '${')
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
