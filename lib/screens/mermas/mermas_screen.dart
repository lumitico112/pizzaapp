import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/merma_controller.dart';
import 'package:pizzaapp/screens/mermas/merma_form_screen.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/utils/formatters.dart';

class MermasScreen extends StatefulWidget {
  const MermasScreen({super.key});

  @override
  State<MermasScreen> createState() => _MermasScreenState();
}

class _MermasScreenState extends State<MermasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MermaController>().loadMermas();
    });
  }

  void _openForm() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MermaFormScreen())
    );
    if (res == true && mounted) {
      context.read<MermaController>().loadMermas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MermaController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Registro de Mermas'),
            backgroundColor: AppColors.error, // Usamos rojo porque es una perdida
          ),
          body: controller.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : controller.mermas.isEmpty 
              ? const Center(child: Text('No hay mermas registradas.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.mermas.length,
                  itemBuilder: (ctx, index) {
                    final m = controller.mermas[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.delete_sweep, color: AppColors.error),
                        ),
                        title: Text(m.insumoNombre ?? m.varianteNombre ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormatter.formatFechaHora(m.fecha)),
                            Text('Tipo: ${m.tipo.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            if (m.descripcion != null && m.descripcion!.isNotEmpty)
                              Text(m.descripcion!, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: Text('-${m.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 16)),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.error,
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Registrar Merma'),
          ),
        );
      },
    );
  }
}
