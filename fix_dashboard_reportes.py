import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/dashboard/dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_str = "import 'package:pizzaapp/screens/reportes/reportes_screen.dart';\n"
if "reportes_screen.dart" not in text:
    text = text.replace("import 'package:pizzaapp/screens/caja/cierre_caja_screen.dart';", import_str + "import 'package:pizzaapp/screens/caja/cierre_caja_screen.dart';")

menu_old = """    {'title': 'Mermas', 'icon': Icons.delete_sweep, 'color': Colors.grey},
    {'title': 'Activos Fijos', 'icon': Icons.chair, 'color': Colors.brown},
  ];"""
menu_new = """    {'title': 'Mermas', 'icon': Icons.delete_sweep, 'color': Colors.grey},
    {'title': 'Activos Fijos', 'icon': Icons.chair, 'color': Colors.brown},
    {'title': 'Reportes', 'icon': Icons.bar_chart, 'color': Colors.indigo},
  ];"""
if "Reportes" not in text:
    text = text.replace(menu_old, menu_new)

routing_old = """    } else if (title == 'Cierre Caja') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CierreCajaScreen()));
    } else {"""
routing_new = """    } else if (title == 'Cierre Caja') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CierreCajaScreen()));
    } else if (title == 'Reportes') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportesScreen()));
    } else {"""
if "ReportesScreen()" not in text:
    text = text.replace(routing_old, routing_new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
