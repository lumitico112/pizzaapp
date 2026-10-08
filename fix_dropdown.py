import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re

old_block = r"""                          builder: \(context, catCtrl, child\) \{
                            return DropdownButtonFormField<String>\(
                              value: \(catCtrl\.categorias\.any\(\(c\) => c\.nombre == _categoriaSeleccionada\)\) \? _categoriaSeleccionada : null,
                              decoration: const InputDecoration\(labelText: '.*?', border: OutlineInputBorder\(\)\),
                              items: catCtrl\.categorias\.map\(\(c\) => DropdownMenuItem\(value: c\.nombre, child: Text\(c\.nombre\)\)\)\.toList\(\),
                              onChanged: \(v\) => setState\(\(\) => _categoriaSeleccionada = v\),
                            \);
                          \}"""

new_block = """                          builder: (context, catCtrl, child) {
                            final uniqueNames = catCtrl.categorias.map((c) => c.nombre).toSet().toList();
                            return DropdownButtonFormField<String>(
                              value: uniqueNames.contains(_categoriaSeleccionada) ? _categoriaSeleccionada : null,
                              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                              items: uniqueNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                              onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                            );
                          }"""

text = re.sub(old_block, new_block, text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
