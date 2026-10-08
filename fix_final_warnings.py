fixes = [
    ("C:/D/ProyectoPizza/pizzaapp/lib/app/app_router.dart", 
     "import 'package:pizzaapp/screens/catalogo/receta_screen.dart';\n", ""),
    
    ("C:/D/ProyectoPizza/pizzaapp/lib/screens/pos/pos_screen.dart",
     "import 'package:pizzaapp/core/widgets/primary_button.dart';\n", ""),
    ("C:/D/ProyectoPizza/pizzaapp/lib/screens/pos/pos_screen.dart",
     "import 'package:pizzaapp/core/widgets/app_text_field.dart';\n", ""),
    ("C:/D/ProyectoPizza/pizzaapp/lib/screens/pos/pos_screen.dart",
     "import 'package:pizzaapp/core/utils/formatters.dart';\n", ""),
    
    ("C:/D/ProyectoPizza/pizzaapp/lib/screens/reportes/reportes_screen.dart",
     "import 'package:pizzaapp/core/theme/app_colors.dart';\n", ""),
    ("C:/D/ProyectoPizza/pizzaapp/lib/screens/reportes/reportes_screen.dart",
     "import 'package:intl/intl.dart';\n", ""),
]

for (path, old, new) in fixes:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    if old in text:
        text = text.replace(old, new)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"Fixed: {path}")
    else:
        print(f"NOT FOUND: {old!r} in {path}")

# Fix unused field in preparacion_repository
path5 = "C:/D/ProyectoPizza/pizzaapp/lib/repositories/preparacion_repository.dart"
with open(path5, "r", encoding="utf-8") as f:
    text5 = f.read()
# Remove the unused _productoRepo field if it's declared but unused
import re
text5 = re.sub(r"  final ProductoRepository _productoRepo;\n?", "", text5)
# Also fix constructor to remove it
text5 = re.sub(r"  PreparacionRepository\(this\._productoRepo\);?\n?", "  PreparacionRepository();\n", text5)
with open(path5, "w", encoding="utf-8") as f:
    f.write(text5)
print(f"Fixed: {path5}")
