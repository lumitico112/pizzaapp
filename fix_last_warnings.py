# Fix 1: preparacion_repository - remove unused _productoRepo field
path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/preparacion_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace("import 'package:pizzaapp/repositories/producto_repository.dart';\n", "")
text = text.replace("  final _productoRepo = ProductoRepository();\n", "")
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Fixed preparacion_repository")

# Fix 2: cierre_caja_screen - the _mostrarDialogoReabrir is actually useful but not wired up yet
# We will wire it to the button instead of removing it. For now just suppress with a comment
# Actually it is good code needed for Fase 8, so we leave it and ignore the warning
# The flutter analyze still warns but it is intentionally kept for future use
print("Kept _mostrarDialogoReabrir - needed for Fase 8 cash reopening")
