import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# I need to ensure GastoRepository is initialized before CompraService.
# Let's find where CompraService is initialized.
old_compra = "final compraService = CompraService(insumoRepo);"
new_compra = "final compraService = CompraService(insumoRepo, gastoRepo);"

if "CompraService(insumoRepo);" in text:
    # First remove it
    text = text.replace(old_compra, "")
    
    # Now place it AFTER gastoRepo
    old_gasto = "final gastoService = GastoService(gastoRepo);"
    new_gasto = "final gastoService = GastoService(gastoRepo);\n  final compraService = CompraService(insumoRepo, gastoRepo);"
    text = text.replace(old_gasto, new_gasto)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
