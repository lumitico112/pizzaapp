import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_imports = """import 'package:pizzaapp/repositories/categoria_activo_repository.dart';
import 'package:pizzaapp/services/categoria_activo_service.dart';
import 'package:pizzaapp/controllers/categoria_activo_controller.dart';
"""
if "categoria_activo_repository" not in text:
    text = text.replace("import 'package:pizzaapp/core/theme/app_theme.dart';", "import 'package:pizzaapp/core/theme/app_theme.dart';\n" + new_imports)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
