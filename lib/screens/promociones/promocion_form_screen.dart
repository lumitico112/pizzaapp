import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/promocion_controller.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/widgets/primary_button.dart';

class PromocionFormScreen extends StatefulWidget {
  final Promocion? promocionAEditar;

  const PromocionFormScreen({super.key, this.promocionAEditar});

  @override
  State<PromocionFormScreen> createState() => _PromocionFormScreenState();
}

class _PromocionItemUI {
  final PromocionItem item;
  final String nombreProducto;
  final String nombreVariante;

  _PromocionItemUI({
    required this.item,
    required this.nombreProducto,
    required this.nombreVariante,
  });
}

class _PromocionFormScreenState extends State<PromocionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  final List<String> _diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  final List<String> _diasSeleccionados = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  List<_PromocionItemUI> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoController>().loadProductos();
    });

    if (widget.promocionAEditar != null) {
      final p = widget.promocionAEditar!;
      _nombreCtrl.text = p.nombre;
      _precioCtrl.text = p.precio.toString();
      if (p.diasSemana != null) {
        _diasSeleccionados.addAll(p.diasSemana!.split(','));
      }
      if (p.horaInicio != null) {
        final parts = p.horaInicio!.split(':');
        if (parts.length == 2) {
          _horaInicio = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      if (p.horaFin != null) {
        final parts = p.horaFin!.split(':');
        if (parts.length == 2) {
          _horaFin = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      _items = p.items.map((e) => _PromocionItemUI(
        item: e, 
        nombreProducto: 'Producto ${e.varianteId}', 
        nombreVariante: 'Variante'
      )).toList();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _selectTime(bool isInicio) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isInicio ? _horaInicio : _horaFin) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  void _agregarProducto() {
    showDialog(
      context: context,
      builder: (context) {
        return const _AgregarProductoDialog();
      },
    ).then((result) {
      if (result != null && result is _PromocionItemUI) {
        setState(() {
          _items.add(result);
        });
      }
    });
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione al menos un día')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregue al menos un producto')));
      return;
    }

    final p = Promocion(
      id: widget.promocionAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      precio: double.tryParse(_precioCtrl.text) ?? 0.0,
      diasSemana: _diasSeleccionados.join(','),
      horaInicio: _formatTime(_horaInicio),
      horaFin: _formatTime(_horaFin),
      activa: widget.promocionAEditar?.activa ?? 1,
    );

    await context.read<PromocionController>().guardarPromocion(p, _items.map((e) => e.item).toList());
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.promocionAEditar != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Promoción' : 'Nueva Promoción'),
        backgroundColor: AppColors.secondary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de Promoción', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _precioCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio Total (\$)', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Días de la semana:', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8.0,
              children: _diasSemana.map((dia) {
                final isSelected = _diasSeleccionados.contains(dia);
                return FilterChip(
                  label: Text(dia),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _diasSeleccionados.add(dia);
                      } else {
                        _diasSeleccionados.remove(dia);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Horario de Aplicación:', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(true),
                    icon: const Icon(Icons.access_time),
                    label: Text(_horaInicio == null ? 'Hora Inicio' : _formatTime(_horaInicio)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(false),
                    icon: const Icon(Icons.access_time),
                    label: Text(_horaFin == null ? 'Hora Fin' : _formatTime(_horaFin)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Productos Incluidos', style: AppTextStyles.sectionTitle),
                TextButton.icon(
                  onPressed: _agregarProducto,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Producto'),
                )
              ],
            ),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: Text('No hay productos en esta promoción.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final uiItem = _items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${uiItem.nombreProducto} - ${uiItem.nombreVariante}'),
                    subtitle: Text('Cantidad: ${uiItem.item.cantidad}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: PrimaryButton(
            text: 'Guardar Promoción',
            onPressed: _guardar,
            isLoading: context.watch<PromocionController>().isLoading,
          ),
        ),
      ),
    );
  }
}

class _AgregarProductoDialog extends StatefulWidget {
  const _AgregarProductoDialog();

  @override
  State<_AgregarProductoDialog> createState() => _AgregarProductoDialogState();
}

class _AgregarProductoDialogState extends State<_AgregarProductoDialog> {
  Producto? _selectedProducto;
  VarianteProducto? _selectedVariante;
  final _cantidadCtrl = TextEditingController(text: '1');
  List<VarianteProducto> _variantes = [];
  bool _isLoadingVariantes = false;

  Future<void> _loadVariantes(Producto producto) async {
    setState(() {
      _isLoadingVariantes = true;
      _selectedVariante = null;
    });
    final variantes = await context.read<ProductoController>().obtenerVariantes(producto.id!);
    if (mounted) {
      setState(() {
        _variantes = variantes;
        _isLoadingVariantes = false;
        if (_variantes.isNotEmpty) {
          _selectedVariante = _variantes.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir Producto'),
      content: Consumer<ProductoController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Producto>(
                  decoration: const InputDecoration(labelText: 'Producto'),
                  initialValue: _selectedProducto,
                  items: ctrl.productos.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProducto = val;
                      });
                      _loadVariantes(val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_isLoadingVariantes) const LinearProgressIndicator(),
                if (!_isLoadingVariantes && _selectedProducto != null)
                  DropdownButtonFormField<VarianteProducto>(
                    decoration: const InputDecoration(labelText: 'Variante'),
                    initialValue: _selectedVariante,
                    items: _variantes.map((v) => DropdownMenuItem(value: v, child: Text(v.nombreVariante))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedVariante = val;
                      });
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _cantidadCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            if (_selectedProducto != null && _selectedVariante != null) {
              final cant = int.tryParse(_cantidadCtrl.text) ?? 1;
              Navigator.pop(
                context,
                _PromocionItemUI(
                  item: PromocionItem(
                    promocionId: 0,
                    varianteId: _selectedVariante!.id!,
                    cantidad: cant,
                  ),
                  nombreProducto: _selectedProducto!.nombre,
                  nombreVariante: _selectedVariante!.nombreVariante,
                ),
              );
            }
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}
