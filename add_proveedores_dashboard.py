path = "C:/D/ProyectoPizza/pizzaapp/lib/screens/dashboard/dashboard_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

# Add to AppRoutes if necessary, or just navigate directly using AppRoutes.proveedores
# Looking for a menu item to insert it after. Let's find "Insumos" or "Compras"
# Example of existing block:
# _buildMenuCard(context, 'Insumos', Icons.inventory_2, Colors.teal, () => AppRouter.push(context, AppRoutes.insumos)),

text = text.replace(
    "_buildMenuCard(context, 'Compras', Icons.shopping_cart, Colors.purple, () => AppRouter.push(context, AppRoutes.compras)),",
    "_buildMenuCard(context, 'Compras', Icons.shopping_cart, Colors.purple, () => AppRouter.push(context, AppRoutes.compras)),\n                          _buildMenuCard(context, 'Proveedores', Icons.local_shipping, Colors.indigo, () => AppRouter.push(context, AppRoutes.proveedores)),"
)

with open(path, "w", encoding="utf-8") as f:
    f.write(text)
print("Added Proveedores to Dashboard")
