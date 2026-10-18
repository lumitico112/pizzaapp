import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/controllers/insumo_controller.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/features/preparation/presentation/controllers/preparacion_controller.dart';
import 'package:pizzaapp/features/waste/presentation/controllers/merma_controller.dart';

class GestionSobrantesModal extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool esCierreDeCiclo;
  final String titulo;
  final String subtitulo;

  const GestionSobrantesModal({
    super.key,
    required this.items,
    required this.esCierreDeCiclo,
    required this.titulo,
    required this.subtitulo,
  });

  /// Abre el modal consultando los productos con stock disponible.
  /// Retorna `true` si se aplicaron cambios, `false` en caso contrario.
  static Future<bool> show(
    BuildContext context, {
    required bool esCierreDeCiclo,
    bool soloNoResueltos = false,
    String? titulo,
    String? subtitulo,
  }) async {
    final prepCtrl = context.read<PreparacionController>();
    final items = await prepCtrl.obtenerProductosConStockParaSobrantes(
      soloNoResueltos: soloNoResueltos,
    );
    if (!context.mounted) return false;
    if (items.isEmpty) {
      if (!soloNoResueltos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay productos preparados con stock disponible en este momento.',
            ),
          ),
        );
      }
      return false;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: !soloNoResueltos,
      enableDrag: !soloNoResueltos,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => GestionSobrantesModal(
        items: items,
        esCierreDeCiclo: esCierreDeCiclo,
        titulo:
            titulo ??
            (soloNoResueltos
                ? 'Sobrantes pendientes con stock'
                : 'Gestión de sobrantes y mermas'),
        subtitulo:
            subtitulo ??
            'Indica por cada producto con stock cuánto queda para mañana y cuánto va a merma (sin superar su stock disponible).',
      ),
    );
    return result == true;
  }

  @override
  State<GestionSobrantesModal> createState() => _GestionSobrantesModalState();
}

class _GestionSobrantesModalState extends State<GestionSobrantesModal> {
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _successDark = Color(0xFF059669);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  final Map<int, TextEditingController> _mananaCtrls = {};
  final Map<int, TextEditingController> _mermaCtrls = {};
  final Map<int, int> _stockPorVariante = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      final vid = item['variante_id'] as int;
      final stock = (item['stock'] as num?)?.toInt() ?? 0;
      _stockPorVariante[vid] = stock;
      _mananaCtrls[vid] = TextEditingController(text: '0');
      _mermaCtrls[vid] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (final c in _mananaCtrls.values) {
      c.dispose();
    }
    for (final c in _mermaCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _getVal(TextEditingController? ctrl) {
    if (ctrl == null) return 0;
    final parsed = int.tryParse(ctrl.text.trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  bool get _hayDesborde {
    for (final vid in _stockPorVariante.keys) {
      final stock = _stockPorVariante[vid] ?? 0;
      final manana = _getVal(_mananaCtrls[vid]);
      final merma = _getVal(_mermaCtrls[vid]);
      if (manana + merma > stock) return true;
    }
    return false;
  }

  bool get _hayAlgunaAccion {
    for (final vid in _stockPorVariante.keys) {
      final manana = _getVal(_mananaCtrls[vid]);
      final merma = _getVal(_mermaCtrls[vid]);
      if (manana > 0 || merma > 0) return true;
    }
    return false;
  }

  void _stepValue(int vid, {required bool esManana, required int delta}) {
    final stock = _stockPorVariante[vid] ?? 0;
    final targetCtrl = esManana ? _mananaCtrls[vid]! : _mermaCtrls[vid]!;
    final otherCtrl = esManana ? _mermaCtrls[vid]! : _mananaCtrls[vid]!;
    final current = _getVal(targetCtrl);
    final other = _getVal(otherCtrl);
    final maxAllowed = (stock - other).clamp(0, stock);
    final next = (current + delta).clamp(0, maxAllowed);
    targetCtrl.text = next.toString();
    setState(() {});
  }

  Future<void> _confirmar() async {
    if (_hayDesborde) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Corrige las cantidades que superan el stock disponible antes de guardar.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_hayAlgunaAccion) {
      if (!widget.esCierreDeCiclo) {
        // En nuevo ciclo de preparación: si no hay mermas asignadas,
        // todo el stock pendiente se conserva para la preparación de hoy y queda resuelto.
        final decisiones = <int, Map<String, int>>{};
        for (final vid in _stockPorVariante.keys) {
          final stock = _stockPorVariante[vid] ?? 0;
          if (stock > 0) {
            decisiones[vid] = {'paraManana': stock, 'merma': 0};
          }
        }
        setState(() => _isSaving = true);
        final prepCtrl = context.read<PreparacionController>();
        final err = await prepCtrl.procesarGestionSobrantesStock(
          decisiones: decisiones,
          esCierreDeCiclo: false,
        );
        if (!mounted) return;
        if (err != null) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
          return;
        }
        context.read<MermaController>().loadMermas();
        context.read<InsumoController>().loadInsumos();
        context.read<CajaController>().loadDatosCaja();
        context.read<PosController>().loadInitialData();
        context.read<DashboardController>().refreshDashboard();
        FocusManager.instance.primaryFocus?.unfocus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todo el stock conservado para la preparación de hoy.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pop(context, false);
      return;
    }

    final decisiones = <int, Map<String, int>>{};
    for (final vid in _stockPorVariante.keys) {
      final manana = _getVal(_mananaCtrls[vid]);
      final merma = _getVal(_mermaCtrls[vid]);
      if (manana > 0 || merma > 0) {
        decisiones[vid] = {'paraManana': manana, 'merma': merma};
      }
    }

    setState(() => _isSaving = true);
    final prepCtrl = context.read<PreparacionController>();
    final err = await prepCtrl.procesarGestionSobrantesStock(
      decisiones: decisiones,
      esCierreDeCiclo: widget.esCierreDeCiclo,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
      return;
    }

    // Sincronizar controladores globales
    context.read<MermaController>().loadMermas();
    context.read<InsumoController>().loadInsumos();
    context.read<CajaController>().loadDatosCaja();
    context.read<PosController>().loadInitialData();
    context.read<DashboardController>().refreshDashboard();

    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gestión de sobrantes y mermas aplicada con éxito.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 4, 18, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: _secondaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitulo,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final vid = item['variante_id'] as int;
                  final prodName = item['producto_nombre'] as String? ?? '';
                  final varName = item['nombre_variante'] as String? ?? '';
                  final stock = _stockPorVariante[vid] ?? 0;
                  final manana = _getVal(_mananaCtrls[vid]);
                  final merma = _getVal(_mermaCtrls[vid]);
                  final asignado = manana + merma;
                  final desborda = asignado > stock;
                  final porAsignar = (stock - asignado).clamp(0, stock);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: desborda
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: desborda ? const Color(0xFFEF4444) : _cardBorder,
                        width: desborda ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '$prodName · $varName',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Stock: $stock ud.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              desborda
                                  ? 'Exceso: +${asignado - stock} ud. sobre el stock'
                                  : 'Asignado: $asignado de $stock ud. · Sin asignar: $porAsignar ud.',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: desborda
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: desborda
                                    ? const Color(0xFFDC2626)
                                    : _textMuted,
                              ),
                            ),
                            const Spacer(),
                            if (porAsignar > 0 && !desborda)
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  _mananaCtrls[vid]!.text = (manana + porAsignar)
                                      .toString();
                                  setState(() {});
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Resto a mañana',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _successDark,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Acción 1: Para mañana
                            Expanded(
                              child: _buildActionCounter(
                                label: 'Para mañana',
                                icon: Icons.event_repeat_rounded,
                                accentColor: _successDark,
                                bgColor: const Color(0xFFECFDF5),
                                borderColor: const Color(0xFFA7F3D0),
                                controller: _mananaCtrls[vid]!,
                                canDecrement: manana > 0,
                                canIncrement: asignado < stock,
                                onDecrement: () => _stepValue(
                                  vid,
                                  esManana: true,
                                  delta: -1,
                                ),
                                onIncrement: () => _stepValue(
                                  vid,
                                  esManana: true,
                                  delta: 1,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Acción 2: Merma
                            Expanded(
                              child: _buildActionCounter(
                                label: 'Merma',
                                icon: Icons.delete_outline_rounded,
                                accentColor: const Color(0xFFDC2626),
                                bgColor: const Color(0xFFFEF2F2),
                                borderColor: const Color(0xFFFECACA),
                                controller: _mermaCtrls[vid]!,
                                canDecrement: merma > 0,
                                canIncrement: asignado < stock,
                                onDecrement: () => _stepValue(
                                  vid,
                                  esManana: false,
                                  delta: -1,
                                ),
                                onIncrement: () => _stepValue(
                                  vid,
                                  esManana: false,
                                  delta: 1,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        if (desborda) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'No se puede asignar $manana para mañana y $merma a merma (total $asignado). El stock máximo es $stock.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.pop(context, false);
                        },
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: (_hayDesborde || _isSaving)
                          ? null
                          : const LinearGradient(
                              colors: [_primaryOrange, _secondaryRed],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      color: (_hayDesborde || _isSaving)
                          ? const Color(0xFFD1D5DB)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: (_hayDesborde || _isSaving) ? null : _confirmar,
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _hayAlgunaAccion
                                          ? 'Guardar decisiones'
                                          : (widget.esCierreDeCiclo
                                              ? 'Continuar sin cambios'
                                              : 'Mantener todo en preparación hoy'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCounter({
    required String label,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required TextEditingController controller,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStepBtn(
                icon: Icons.remove_rounded,
                enabled: canDecrement,
                color: accentColor,
                onTap: onDecrement,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      onChanged: onChanged,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
              _miniStepBtn(
                icon: Icons.add_rounded,
                enabled: canIncrement,
                color: accentColor,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStepBtn({
    required IconData icon,
    required bool enabled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? color : Colors.black26,
          ),
        ),
      ),
    );
  }
}
