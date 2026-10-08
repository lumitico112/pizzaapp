import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/sugerencia_controller.dart';
import 'package:pizzaapp/controllers/preparacion_controller.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

class SugerenciasScreen extends StatefulWidget {
  const SugerenciasScreen({super.key});

  @override
  State<SugerenciasScreen> createState() => _SugerenciasScreenState();
}

class _SugerenciasScreenState extends State<SugerenciasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SugerenciaController>().loadSugerencias('hoy');
      context.read<PreparacionController>().loadHistorial();
    });
  }

  void _cambiarFiltro(String filtro) {
    context.read<SugerenciaController>().loadSugerencias(filtro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerencias & Preparación'),
        backgroundColor: AppColors.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Consumer<SugerenciaController>(
            builder: (ctx, controller, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TabBtn(
                      titulo: 'Hoy', 
                      activo: controller.filtroActivo == 'hoy' && controller.filtroActivo != 'historial',
                      onTap: () => _cambiarFiltro('hoy'),
                    ),
                    _TabBtn(
                      titulo: 'Mañana', 
                      activo: controller.filtroActivo == 'manana',
                      onTap: () => _cambiarFiltro('manana'),
                    ),
                    _TabBtn(
                      titulo: 'Semana', 
                      activo: controller.filtroActivo == 'semana',
                      onTap: () => _cambiarFiltro('semana'),
                    ),
                    _TabBtn(
                      titulo: 'Historial', 
                      activo: controller.filtroActivo == 'historial',
                      onTap: () => _cambiarFiltro('historial'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: Consumer<SugerenciaController>(
        builder: (context, sugerenciaCtrl, child) {
          if (sugerenciaCtrl.filtroActivo == 'historial') {
            return const _HistorialView();
          }

          if (sugerenciaCtrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sugerenciaCtrl.sugerencias.isEmpty) {
            return const Center(
              child: Text(
                'No hay datos suficientes para sugerencias.', 
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)
              )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sugerenciaCtrl.sugerencias.length,
            itemBuilder: (context, index) {
              final sug = sugerenciaCtrl.sugerencias[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.background,
                        child: Icon(Icons.auto_graph, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${sug.productoNombre} - ${sug.varianteNombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Promedio Ventas: ${sug.promedioVentas.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const Text(' | ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text('promedioFaltantes: +${sug.promedioFaltantes}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                                const Text(' | ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text('promedioSobrantes: -${sug.promedioSobrantes}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          const Text('Sugerencia', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text(
                            '${sug.sugerenciaFinal}',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'aplicarSugerencias',
            backgroundColor: AppColors.primary,
            onPressed: () {
              // Mock: Aplicar sugerencias a preparación hoy
              // context.read<PreparacionController>().aplicarSugerencias(sugerenciaCtrl.sugerencias);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sugerencias aplicadas a la preparación de hoy')),
              );
            },
            icon: const Icon(Icons.check_circle_outline, color: AppColors.textInverse),
            label: const Text('Aplicar Sugerencias a Preparación Hoy', style: TextStyle(color: AppColors.textInverse)),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'registrarPreparacion',
            backgroundColor: AppColors.secondary,
            onPressed: () async {
              final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroPreparacionScreen()));
              if (!context.mounted) return;
              if (res == true) {
                context.read<PreparacionController>().loadHistorial();
              }
            },
            icon: const Icon(Icons.add, color: AppColors.textInverse),
            label: const Text('Registrar Preparación', style: TextStyle(color: AppColors.textInverse)),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String titulo;
  final bool activo;
  final VoidCallback onTap;

  const _TabBtn({required this.titulo, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          titulo, 
          style: TextStyle(
            color: activo ? AppColors.primary : Colors.white, 
            fontWeight: FontWeight.bold
          )
        ),
      ),
    );
  }
}

class _HistorialView extends StatelessWidget {
  const _HistorialView();

  @override
  Widget build(BuildContext context) {
    return Consumer<PreparacionController>(
      builder: (context, prepCtrl, child) {
        if (prepCtrl.isLoading) return const Center(child: CircularProgressIndicator());
        if (prepCtrl.historial.isEmpty) {
          return const Center(child: Text('Aún no hay preparaciones registradas.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prepCtrl.historial.length,
          itemBuilder: (ctx, i) {
            final h = prepCtrl.historial[i];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: const Icon(Icons.history, color: AppColors.secondary),
                title: Text('Fecha: ${h.fecha}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(h.nota ?? 'Sin nota'),
                children: h.items.map((item) => ListTile(
                  title: Text('${item.productoNombre} - ${item.varianteNombre}'),
                  trailing: Text('+${item.cantidadPreparada}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16)),
                )).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
