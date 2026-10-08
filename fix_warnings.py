# Fix 1: Remove unused imports from main.dart
path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace("import 'package:pizzaapp/screens/auth/login_screen.dart';\n", "")
text = text.replace("import 'package:pizzaapp/screens/auth/onboarding_screen.dart';\n", "")
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

# Fix 2: Remove unused imports from repositories
path2 = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/preparacion_repository.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()
text2 = text2.replace("import 'package:flutter/material.dart';\n", "")
text2 = text2.replace("import 'package:pizzaapp/models/producto.dart';\n", "")
with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)

path3 = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/venta_repository.dart'
with open(path3, 'r', encoding='utf-8') as f:
    text3 = f.read()
text3 = text3.replace("import 'package:sqflite_sqlcipher/sqflite.dart';\n", "")
with open(path3, 'w', encoding='utf-8') as f:
    f.write(text3)

path4 = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/insumo_controller.dart'
with open(path4, 'r', encoding='utf-8') as f:
    text4 = f.read()
text4 = text4.replace("import 'package:pizzaapp/models/categoria_insumo.dart';\n", "")
with open(path4, 'w', encoding='utf-8') as f:
    f.write(text4)

print("Done")
