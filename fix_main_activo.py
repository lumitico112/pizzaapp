import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_injection = """  final activoFijoRepo = ActivoFijoRepository();
  final activoFijoService = ActivoFijoService(activoFijoRepo);"""

text = text.replace(old_injection, "")

old_merma = """final mermaService = MermaService(mermaRepo, insumoRepo, productoRepo);"""
new_merma = """final mermaService = MermaService(mermaRepo, insumoRepo, productoRepo);
  final activoFijoRepo = ActivoFijoRepository();
  final activoFijoService = ActivoFijoService(activoFijoRepo, gastoRepo, insumoRepo);"""
text = text.replace(old_merma, new_merma)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
