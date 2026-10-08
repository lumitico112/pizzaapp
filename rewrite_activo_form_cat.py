import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add import
import_line = "import 'package:pizzaapp/core/utils/formatters.dart';"
new_import_line = "import 'package:pizzaapp/core/utils/formatters.dart';\nimport 'package:pizzaapp/controllers/categoria_activo_controller.dart';\nimport 'package:pizzaapp/screens/categorias/categorias_activo_screen.dart';"
text = text.replace(import_line, new_import_line)

# Remove text controller
text = text.replace("final _categoriaCtrl = TextEditingController();", "String? _categoriaSeleccionada;")
text = text.replace("_categoriaCtrl.text = a.categoria ?? '';", "_categoriaSeleccionada = a.categoria;")
text = text.replace("_categoriaCtrl.dispose();", "")

# Add init state logic
init_state = "    if (widget.activoAEditar != null) {"
new_init_state = """    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaActivoController>().loadCategorias();
    });
    if (widget.activoAEditar != null) {"""
text = text.replace(init_state, new_init_state)

# Replace obj creation
obj_line = "categoria: _categoriaCtrl.text.trim(),"
new_obj_line = "categoria: _categoriaSeleccionada ?? 'Sin Categoría',"
text = text.replace(obj_line, new_obj_line)

# Replace UI
ui_old = """                  AppTextField(
                    controller: _categoriaCtrl,
                    label: 'Categoría (Ej: Maquinaria, Muebles)',
                  ),"""

ui_new = """                  Row(
                    children: [
                      Expanded(
                        child: Consumer<CategoriaActivoController>(
                          builder: (context, catCtrl, child) {
                            return DropdownButtonFormField<String>(
                              value: (catCtrl.categorias.any((c) => c.nombre == _categoriaSeleccionada)) ? _categoriaSeleccionada : null,
                              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                              items: catCtrl.categorias.map((c) => DropdownMenuItem(value: c.nombre, child: Text(c.nombre))).toList(),
                              onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                            );
                          }
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.brown, size: 32),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriasActivoScreen())).then((_) {
                            if (mounted) context.read<CategoriaActivoController>().loadCategorias();
                          });
                        },
                      ),
                    ],
                  ),"""

text = text.replace(ui_old, ui_new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
