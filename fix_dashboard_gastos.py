import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/dashboard/dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("} else if (title == 'Gastos') {\n        await Navigator.push(context, MaterialPageRoute(builder: (_) => const GastosScreen()));\n        _loadStats();\n      ", "")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
