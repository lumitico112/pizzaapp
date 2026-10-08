path = "C:/D/ProyectoPizza/pizzaapp/lib/screens/compras/compra_form_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

# Fix 1: Wrong InsumoFormScreen import (screens/inventario → screens/insumos)
text = text.replace(
    "import 'package:pizzaapp/screens/inventario/insumo_form_screen.dart';",
    "import 'package:pizzaapp/screens/insumos/insumo_form_screen.dart';"
)

# Fix 2: AppDatePicker - wrong params (initialDate, onDateSelected → selectedDate, onDateChanged)
text = text.replace(
    """  AppDatePicker(\n                    initialDate: _fechaSeleccionada,\n                    onDateSelected: (date) {\n                      if (date != null) setState(() => _fechaSeleccionada = date);\n                    },\n                  ),""",
    """  AppDatePicker(\n                    selectedDate: _fechaSeleccionada,\n                    onDateChanged: (date) => setState(() => _fechaSeleccionada = date),\n                    label: 'Fecha de compra',\n                  ),"""
)

# Fix 3: AppImagePicker - wrong params (initialImagePath, onImagePicked → currentImagePath, onImageSelected)
text = text.replace(
    """AppImagePicker(\n                    initialImagePath: _facturaRuta,\n                    onImagePicked: (path) => setState(() => _facturaRuta = path),\n                    label: 'Foto de comprobante / factura',\n                  ),""",
    """AppImagePicker(\n                    currentImagePath: _facturaRuta,\n                    onImageSelected: (path) => setState(() => _facturaRuta = path),\n                    label: 'Foto de comprobante / factura',\n                    defaultIcon: Icons.receipt_long_outlined,\n                    size: 100,\n                  ),"""
)

# Fix 4: AppTextField does not have maxLines param - replace with TextFormField
text = text.replace(
    """AppTextField(\n                    controller: _notaCtrl,\n                    label: 'Motivo / Nota',\n                    maxLines: 2,\n                  ),""",
    """TextFormField(\n                    controller: _notaCtrl,\n                    maxLines: 3,\n                    decoration: const InputDecoration(\n                      labelText: 'Motivo / Nota (Opcional)',\n                      border: OutlineInputBorder(),\n                      alignLabelWithHint: true,\n                    ),\n                  ),"""
)

# Fix 5: PrimaryButton - check if it exists, if not replace with ElevatedButton
import os
primary_btn_path = "C:/D/ProyectoPizza/pizzaapp/lib/core/widgets/primary_button.dart"
if os.path.exists(primary_btn_path):
    print("PrimaryButton exists - keeping")
else:
    text = text.replace(
        "import 'package:pizzaapp/core/widgets/primary_button.dart';",
        ""
    )
    text = text.replace(
        """PrimaryButton(\n                    text: 'Guardar Compra',\n                    isLoading: comprasCtrl.isLoading,\n                    onPressed: comprasCtrl.isLoading ? null : _guardar,\n                  ),""",
        """SizedBox(\n                    width: double.infinity,\n                    child: ElevatedButton.icon(\n                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, padding: const EdgeInsets.symmetric(vertical: 14)),\n                      onPressed: comprasCtrl.isLoading ? null : _guardar,\n                      icon: comprasCtrl.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined),\n                      label: const Text('Guardar Compra', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),\n                    ),\n                  ),"""
    )

with open(path, "w", encoding="utf-8") as f:
    f.write(text)
print("Fixed compra_form_screen.dart")
