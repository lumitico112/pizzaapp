import re

path = r'C:\D\ProyectoPizza\pizzaapp\lib\screens\activos_fijos\activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

content = content.replace('Categora', 'Categoría')
content = content.replace('Categora', 'Categoría')
content = content.replace('Condicin', 'Condición')
content = content.replace('Condicin', 'Condición')
content = content.replace('Adquisicin', 'Adquisición')
content = content.replace('Adquisicin', 'Adquisición')
content = content.replace('Mtodo', 'Método')
content = content.replace('Mtodo', 'Método')
content = content.replace('Crdito', 'Crédito')
content = content.replace('Crdito', 'Crédito')
content = content.replace('REPARACIN', 'REPARACIÓN')
content = content.replace('REPARACIN', 'REPARACIÓN')
content = content.replace('Reparacin', 'Reparación')
content = content.replace('reparacin', 'reparación')
content = content.replace('.withOpacity(', '.withValues(alpha: ')

content = content.replace(
    \"final _cantidadCtrl = TextEditingController(text: '1');\",
    \"final _cantidadCtrl = TextEditingController(text: '1');\\n  final _valorUnitarioCtrl = TextEditingController();\"
)

init_state_replacement = '''
  bool _isCalculating = false;

  void _calcularCostoTotal() {
    if (_isCalculating) return;
    _isCalculating = true;
    final condicionValida = _condicion == 'Prestado' || _condicion == 'Alquilado';
    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (condicionValida && cantidad > 1) {
      final valorUnitario = double.tryParse(_valorUnitarioCtrl.text) ?? 0;
      if (valorUnitario > 0) {
        _costoCtrl.text = (valorUnitario * cantidad).toStringAsFixed(2);
      }
    }
    _isCalculating = false;
  }

  @override
  void initState() {'''
content = content.replace('  @override\\n  void initState() {', init_state_replacement)

super_init_replace = '''    super.initState();
    _cantidadCtrl.addListener(() {
      setState(() {});
      _calcularCostoTotal();
    });
    _valorUnitarioCtrl.addListener(_calcularCostoTotal);'''
content = content.replace('    super.initState();', super_init_replace)

content = content.replace('    _cantidadCtrl.dispose();', '    _cantidadCtrl.dispose();\\n    _valorUnitarioCtrl.dispose();')

content = content.replace(
    'onChanged: (v) => setState(() => _condicion = v!),',
    'onChanged: (v) => setState(() { _condicion = v!; _calcularCostoTotal(); }),'
)

ui_replacement = '''
                  if ((_condicion == 'Prestado' || _condicion == 'Alquilado') && (int.tryParse(_cantidadCtrl.text) ?? 1) > 1) ...[
                    AppTextField(
                      controller: _valorUnitarioCtrl,
                      label: 'Valor por unidad (Opcional)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  
                  if (_condicion == 'Comprado' || _condicion == 'Alquilado' || _condicion == 'Prestado') ...['''
content = content.replace(\"                  if (_condicion == 'Comprado' || _condicion == 'Alquilado') ...[\", ui_replacement)

content = content.replace(
    \"label: _condicion == 'Comprado' ? 'Costo Total de Adquisición' : 'Costo de Alquiler',\",
    \"label: _condicion == 'Comprado' ? 'Costo Total de Adquisición' : (_condicion == 'Alquilado' ? 'Costo de Alquiler' : 'Valor Total (Opcional)'),\"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
