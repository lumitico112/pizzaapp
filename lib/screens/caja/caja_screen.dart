import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/caja_controller.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';
import 'package:pizzaapp/core/widgets/app_confirm_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CajaController>().loadDatosCaja();
    });
  }

  void _abrirCajaDialog() {
    final montoCtrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir Caja'),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto inicial (Efectivo)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(montoCtrl.text) ?? 0;
              await context.read<CajaController>().abrirCaja(val);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Abrir'),
          )
        ],
      )
    );
  }

  void _registrarMovimientoDialog(String tipo) {
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tipo == 'entrada' ? 'Entrada Manual' : 'Salida Manual / Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 10),
            TextField(controller: montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(montoCtrl.text) ?? 0;
              if (val > 0 && descCtrl.text.isNotEmpty) {
                await context.read<CajaController>().registrarMovimientoManual(tipo, descCtrl.text, val, 'efectivo');
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          )
        ],
      )
    );
  }

  void _cerrarCajaDialog(SesionCaja sesion) {
    final efectivoRealCtrl = TextEditingController(text: '0');
    final notaCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final real = double.tryParse(efectivoRealCtrl.text) ?? 0;
          final dif = real - sesion.totalEfectivoSistema;
          final colorDif = dif == 0 ? AppColors.textPrimary : (dif > 0 ? AppColors.success : AppColors.error);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Cerrar Caja', style: AppTextStyles.heading2),
                const SizedBox(height: 10),
                Text('Efectivo Teórico: S/ ${sesion.totalEfectivoSistema.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                Text('Total Yape/Plin: S/ ${sesion.totalYapePlin.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                Text('Total Gastos: S/ ${sesion.totalGastos.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                const Divider(),
                TextField(
                  controller: efectivoRealCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Efectivo Real Contado', border: OutlineInputBorder()),
                  onChanged: (v) => setStateDialog((){}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notaCtrl,
                  decoration: const InputDecoration(labelText: 'Nota (Opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Text('Diferencia: S/ ${dif.toStringAsFixed(2)}', style: AppTextStyles.heading3.copyWith(color: colorDif)),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    await context.read<CajaController>().cerrarCaja(real, notaCtrl.text);
                    if (mounted) {
                      Navigator.pop(ctx);
                      final lastSesion = sesion;
                      final pdfPath = await context.read<CajaController>().generarArqueoPDF(lastSesion);
                      if (pdfPath != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Caja cerrada con éxito'),
                          action: SnackBarAction(label: 'Ver PDF', onPressed: () {
                            OpenFilex.open(pdfPath);
                          }),
                        ));
                      }
                    }
                  },
                  child: const Text('CONFIRMAR CIERRE DE CAJA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CajaController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Caja')),
      body: ctrl.isLoading
        ? const AppLoadingState(message: 'Cargando...')
        : (ctrl.yaEstaCerrado || ctrl.sesionActual == null)
          ? AppEmptyState(
              message: 'La caja se encuentra cerrada.',
              icon: Icons.lock_outline,
              actionLabel: 'Abrir Caja',
              onAction: _abrirCajaDialog,
            )
          : _buildCajaAbierta(ctrl.sesionActual!),
    );
  }

  Widget _buildCajaAbierta(SesionCaja sesion) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppColors.successLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Caja Abierta', style: TextStyle(color: AppColors.success, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Efectivo en Caja (Teórico): S/ ${sesion.totalEfectivoSistema.toStringAsFixed(2)}', style: AppTextStyles.heading3),
                  Text('Gastos Acumulados: S/ ${sesion.totalGastos.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                  Text('Pagos Digitales: S/ ${sesion.totalYapePlin.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _registrarMovimientoDialog('entrada'), 
                  icon: const Icon(Icons.arrow_downward), 
                  label: const Text('Entrada')
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _registrarMovimientoDialog('salida'), 
                  icon: const Icon(Icons.arrow_upward), 
                  label: const Text('Salida / Gasto')
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.all(16)
            ),
            onPressed: () => _cerrarCajaDialog(sesion),
            child: const Text('CERRAR CAJA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
