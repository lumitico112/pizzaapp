import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/screens/catalogo/catalogo_screen.dart';
import 'package:pizzaapp/screens/insumos/insumos_screen.dart';
import 'package:pizzaapp/screens/compras/compras_screen.dart';
import 'package:pizzaapp/screens/pos/pos_screen.dart';
import 'package:pizzaapp/screens/compras/por_pagar_screen.dart';
import 'package:pizzaapp/screens/mermas/mermas_screen.dart';
import 'package:pizzaapp/screens/reportes/reportes_screen.dart';
import 'package:pizzaapp/screens/caja/caja_screen.dart';
import 'package:pizzaapp/screens/activos_fijos/activos_fijos_screen.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';
import 'package:pizzaapp/screens/preparacion/sugerencias_screen.dart';
import 'package:pizzaapp/screens/promociones/promociones_screen.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'package:pizzaapp/screens/usuarios/user_profile_dialog.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Vender (POS)', 'icon': Icons.shopping_cart, 'color': Colors.blue},
    {'title': 'Cierre Caja', 'icon': Icons.payments, 'color': Colors.green},
    {'title': 'Insumos', 'icon': Icons.inventory, 'color': Colors.orange},
    {'title': 'Catalogo', 'icon': Icons.local_pizza, 'color': Colors.red},
    {'title': 'Compras / Gastos', 'icon': Icons.receipt_long, 'color': Colors.teal},
    {'title': 'Por Pagar', 'icon': Icons.schedule, 'color': Colors.deepOrange},
    {'title': 'Mermas', 'icon': Icons.delete_sweep, 'color': Colors.grey},
    {'title': 'Activos Fijos', 'icon': Icons.chair, 'color': Colors.brown},
    {'title': 'Reportes', 'icon': Icons.bar_chart, 'color': Colors.indigo},
    {'title': 'Promociones', 'icon': Icons.local_offer, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadDashboard();
    });
  }

  void _loadStats() {
    context.read<DashboardController>().loadDashboard();
  }

  void _navigateTo(String title) async {
    if (title == 'Catalogo') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogoScreen()));
      _loadStats();
    } else if (title == 'Vender (POS)') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
      _loadStats();
    } else if (title == 'Insumos') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const InsumosScreen()));
    } else if (title == 'Compras / Gastos') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ComprasScreen()));
      _loadStats();
    } else if (title == 'Por Pagar') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const PorPagarScreen()));
      _loadStats();
    } else if (title == 'Activos Fijos') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivosFijosScreen()));
    } else if (title == 'Mermas') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const MermasScreen()));
    } else if (title == 'Gestión de Caja' || title == 'Cierre Caja') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CajaScreen()));
    } else if (title == 'Reportes') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportesScreen()));
    } else if (title == 'Promociones') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const PromocionesScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modulo $title en desarrollo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final summary = controller.summary;
        final diaStr = _getDiaSemana(DateTime.now().weekday);
        final cuentasPorPagar = summary.cuentasPendientes;
        final totalDeuda = summary.montoPendiente;

        return Scaffold(
          appBar: AppBar(
            title: const Text('PizzApp Dashboard'),
            actions: [
              IconButton(
                icon: Builder(
                  builder: (ctx) {
                    final user = ctx.watch<AuthController>().currentUser;
                    if (user?.fotoRuta != null) {
                      return CircleAvatar(backgroundImage: FileImage(File(user!.fotoRuta!)), radius: 14);
                    }
                    return const Icon(Icons.person);
                  }
                ), 
                onPressed: () {
                  showDialog(context: context, builder: (_) => const UserProfileDialog());
                }
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header con stats del dia
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hoy - $diaStr', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(summary.ventas),
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem('Ventas', CurrencyFormatter.format(summary.ventas), Colors.greenAccent),
                          _buildSummaryItem('Gastos', CurrencyFormatter.format(summary.gastos), Colors.redAccent),
                          _buildSummaryItem('Ganancia', CurrencyFormatter.format(summary.ganancia), Colors.blueAccent),
                        ],
                      ),
                    ],
                  ),
                ),

                // === BOTONES DE ACCESO RAPIDO ===
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Column(
                    children: [
                      // Fila 1: Registrar Preparacion | Sugerencias
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickButton(
                              icon: Icons.edit_note,
                              label: 'Pre-Preparacion',
                              color: Colors.blue.shade700,
                              subtitle: 'Registrar hoy',
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroPreparacionScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickButton(
                              icon: Icons.lightbulb,
                              label: 'Sugerencias',
                              color: Colors.orange.shade700,
                              subtitle: 'Ventas historicas',
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SugerenciasScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                      // Alerta de deuda si hay cuentas pendientes
                      if (cuentasPorPagar > 0) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const PorPagarScreen()));
                            _loadStats();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber, color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$cuentasPorPagar cuenta(s) pendiente(s) de pago - ${CurrencyFormatter.format(totalDeuda)} total',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 8),

                // Grid del menu
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final esPorPagar = item['title'] == 'Por Pagar';
                      return InkWell(
                        onTap: () => _navigateTo(item['title']),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: esPorPagar && cuentasPorPagar > 0
                                ? const BorderSide(color: Colors.orange, width: 2)
                                : BorderSide.none,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(item['icon'], size: 48, color: item['color']),
                                    const SizedBox(height: 12),
                                    Text(
                                      item['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              if (esPorPagar && cuentasPorPagar > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$cuentasPorPagar',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getDiaSemana(int weekday) {
    const dias = ['', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    return weekday < dias.length ? dias[weekday] : '';
  }
}



