import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';

class DashboardSummary {
  final double ventas;
  final double gastos;
  final double ganancia;
  final int cuentasPendientes;
  final double montoPendiente;

  DashboardSummary({
    this.ventas = 0.0,
    this.gastos = 0.0,
    this.ganancia = 0.0,
    this.cuentasPendientes = 0,
    this.montoPendiente = 0.0,
  });
}

class DashboardService {
  final VentaRepository _ventaRepo;
  final InsumoRepository _insumoRepo;

  DashboardService(this._ventaRepo, this._insumoRepo);

  Future<DashboardSummary> obtenerResumenDelDia() async {
    final stats = await _ventaRepo.getResumenHoy();
    
    final cuentas = await _insumoRepo.getCuentasPorPagar();
    final pendientes = cuentas.where((c) => c['pagado'] == 0).toList();
    final totalDeuda = pendientes.fold(0.0, (sum, c) => sum + (c['costo_total'] as num).toDouble());

    return DashboardSummary(
      ventas: stats['ventas'] ?? 0.0,
      gastos: stats['gastos'] ?? 0.0,
      ganancia: stats['ganancia'] ?? 0.0,
      cuentasPendientes: pendientes.length,
      montoPendiente: totalDeuda,
    );
  }
}
