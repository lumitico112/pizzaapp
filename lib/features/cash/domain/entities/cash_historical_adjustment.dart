import 'package:pizzaapp/features/cash/domain/entities/cash_payment_method.dart';

/// Venta retroactiva que se sumó a un ciclo de caja después de su cierre.
class CashHistoricalSale {
  final int ventaId;
  final String fecha;
  final String hora;
  final String metodoPago;
  final double total;

  const CashHistoricalSale({
    required this.ventaId,
    required this.fecha,
    required this.hora,
    required this.metodoPago,
    required this.total,
  });

  bool get esDigital => CashPaymentMethod.esDigital(metodoPago);

  bool get esEfectivo => CashPaymentMethod.esEfectivo(metodoPago);
}

/// Ajuste informativo posterior al cierre de una sesión.
///
/// No modifica `SesionesCaja`, `MovimientosCaja` ni el cierre original. Se
/// calcula a partir de ventas marcadas como históricas para mostrarlas en el
/// arqueo histórico y en su PDF.
class CashHistoricalAdjustment {
  final List<CashHistoricalSale> ventas;

  const CashHistoricalAdjustment({this.ventas = const []});

  static double _money(double value) => (value * 100).roundToDouble() / 100;

  bool get tieneVentas => ventas.isNotEmpty;

  int get cantidad => ventas.length;

  double get efectivo => _money(
    ventas
        .where((venta) => venta.esEfectivo)
        .fold(0.0, (total, venta) => total + venta.total),
  );

  double get digital => _money(
    ventas
        .where((venta) => venta.esDigital)
        .fold(0.0, (total, venta) => total + venta.total),
  );

  double get total => _money(efectivo + digital);
}
