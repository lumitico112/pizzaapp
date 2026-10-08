import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/dashboard/dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Remove import
text = text.replace("import 'package:pizzaapp/screens/gastos/gastos_screen.dart';\n", "")

# 2. Update menu items
old_menu = """    final items = [
      {'title': 'POS', 'icon': Icons.point_of_sale, 'color': Colors.green},
      {'title': 'Insumos', 'icon': Icons.inventory, 'color': Colors.orange},
      {'title': 'Catalogo', 'icon': Icons.local_pizza, 'color': Colors.red},
      {'title': 'Compras', 'icon': Icons.receipt_long, 'color': Colors.teal},
      {'title': 'Por Pagar', 'icon': Icons.schedule, 'color': Colors.deepOrange},
      {'title': 'Gastos', 'icon': Icons.money_off, 'color': Colors.redAccent},
      {'title': 'Mermas', 'icon': Icons.delete_sweep, 'color': Colors.grey},
      {'title': 'Activos Fijos', 'icon': Icons.chair, 'color': Colors.brown},
      {'title': 'Preparación', 'icon': Icons.kitchen, 'color': Colors.purple},
      {'title': 'Caja', 'icon': Icons.account_balance_wallet, 'color': Colors.blueGrey},
    ];"""

new_menu = """    final items = [
      {'title': 'POS', 'icon': Icons.point_of_sale, 'color': Colors.green},
      {'title': 'Insumos', 'icon': Icons.inventory, 'color': Colors.orange},
      {'title': 'Catalogo', 'icon': Icons.local_pizza, 'color': Colors.red},
      {'title': 'Compras / Gastos', 'icon': Icons.receipt_long, 'color': Colors.teal},
      {'title': 'Por Pagar', 'icon': Icons.schedule, 'color': Colors.deepOrange},
      {'title': 'Mermas', 'icon': Icons.delete_sweep, 'color': Colors.grey},
      {'title': 'Activos Fijos', 'icon': Icons.chair, 'color': Colors.brown},
      {'title': 'Preparación', 'icon': Icons.kitchen, 'color': Colors.purple},
      {'title': 'Caja', 'icon': Icons.account_balance_wallet, 'color': Colors.blueGrey},
    ];"""
text = text.replace(old_menu, new_menu)

# 3. Update routing
old_routing = """      } else if (title == 'Compras') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ComprasScreen()));
        _loadStats();
      } else if (title == 'Por Pagar') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PorPagarScreen()));
        _loadStats();
      } else if (title == 'Activos Fijos') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivosFijosScreen()));
      } else if (title == 'Gastos') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const GastosScreen()));
        _loadStats();
      } else if (title == 'Mermas') {"""

new_routing = """      } else if (title == 'Compras / Gastos') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ComprasScreen()));
        _loadStats();
      } else if (title == 'Por Pagar') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PorPagarScreen()));
        _loadStats();
      } else if (title == 'Activos Fijos') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivosFijosScreen()));
      } else if (title == 'Mermas') {"""
text = text.replace(old_routing, new_routing)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
