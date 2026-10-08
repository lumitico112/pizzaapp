import re

# Fix insumo_form_screen.dart
path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/insumos/insumo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove unused imports
text = text.replace("import 'dart:io';\n", "")
text = text.replace("import 'package:pizzaapp/core/theme/app_text_styles.dart';\n", "")

# Fix unnecessary null comparison (contenidoPaquete is non-nullable int)
# The line is likely: if (i.contenidoPaquete != null) {
text = re.sub(
    r'      if \(i\.contenidoPaquete != null\) \{\n        _contenidoPaqueteCtrl\.text = i\.contenidoPaquete\.toString\(\);\n      \}',
    '      _contenidoPaqueteCtrl.text = i.contenidoPaquete.toString();',
    text
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Fixed insumo_form_screen.dart")
