import sys
import re

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add _condicion to State
old_state = """  String _estado = 'Bueno';
  final List<String> _estados = ['Nuevo', 'Bueno', 'Regular', 'Malo'];
"""
new_state = """  String _estado = 'Bueno';
  final List<String> _estados = ['Nuevo', 'Bueno', 'Regular', 'Malo'];
  String _condicion = 'Comprado';
  final List<String> _condiciones = ['Comprado', 'Alquilado', 'Prestado'];
"""
text = text.replace(old_state, new_state)

# Init _condicion
old_init = """      _estado = widget.activoToEdit!.estado;
    }
  }"""
new_init = """      _estado = widget.activoToEdit!.estado;
      _condicion = widget.activoToEdit!.condicion;
    }
  }"""
text = text.replace(old_init, new_init)

# Create object
old_obj = """      estado: _estado,
      observaciones: _obsCtrl.text.trim(),
    );"""
new_obj = """      estado: _estado,
      condicion: _condicion,
      observaciones: _obsCtrl.text.trim(),
    );"""
text = text.replace(old_obj, new_obj)

# Add UI Dropdown for condicion
old_ui = """                DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: const InputDecoration(labelText: 'Estado Físico'),
                  items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),"""
new_ui = """                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _estado,
                        decoration: const InputDecoration(labelText: 'Estado Físico'),
                        items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _estado = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _condicion,
                        decoration: const InputDecoration(labelText: 'Condición'),
                        items: _condiciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _condicion = v!),
                      ),
                    ),
                  ],
                ),"""
text = text.replace(old_ui, new_ui)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
