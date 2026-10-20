import 'package:pizzaapp/features/cash/domain/entities/cash_historical_adjustment.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_payment_method.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';

class CashProductSale {
  final String productName;
  final String variantName;
  final int quantity;
  final int courtesyQuantity;
  final double total;

  const CashProductSale({
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.courtesyQuantity,
    required this.total,
  });
}

class PreparedStockBalance {
  final String productName;
  final String variantName;
  final int quantity;

  const PreparedStockBalance({
    required this.productName,
    required this.variantName,
    required this.quantity,
  });
}

/// Cálculo único del arqueo para la vista previa, el cierre persistido y el PDF.
class CashCloseSummary {
  final double efectivoEsperado;
  final double transferenciasEsperadas;
  final double gastos;
  final double gastosDelCiclo;
  final double ventasEfectivo;
  final double ventasTransferencias;
  final double entradasEfectivo;
  final double entradasTransferencias;
  final double salidasEfectivo;
  final double salidasTransferencias;
  final List<CashProductSale> ventasPorProducto;
  final List<PreparedStockBalance> preparadosRestantes;
  final CashHistoricalAdjustment ajusteHistorico;

  const CashCloseSummary({
    required this.efectivoEsperado,
    required this.transferenciasEsperadas,
    required this.gastos,
    this.gastosDelCiclo = 0,
    this.ventasEfectivo = 0,
    this.ventasTransferencias = 0,
    this.entradasEfectivo = 0,
    this.entradasTransferencias = 0,
    this.salidasEfectivo = 0,
    this.salidasTransferencias = 0,
    this.ventasPorProducto = const [],
    this.preparadosRestantes = const [],
    this.ajusteHistorico = const CashHistoricalAdjustment(),
  });

  static double _money(double value) => (value * 100).roundToDouble() / 100;

  double diferencia({
    required double efectivo,
    required double transferencias,
  }) => _money(
    (efectivo - efectivoEsperado) + (transferencias - transferenciasEsperadas),
  );

  double get totalEsperado => _money(efectivoEsperado + transferenciasEsperadas);

  double get ajusteEfectivo => ajusteHistorico.efectivo;

  double get ajusteDigital => ajusteHistorico.digital;

  int get ventasHistoricas => ajusteHistorico.cantidad;

  bool get tieneAjusteHistorico => ajusteHistorico.tieneVentas;

  double get efectivoEsperadoAjustado =>
      _money(efectivoEsperado + ajusteEfectivo);

  double get transferenciasEsperadasAjustadas =>
      _money(transferenciasEsperadas + ajusteDigital);

  double get totalEsperadoAjustado =>
      _money(efectivoEsperadoAjustado + transferenciasEsperadasAjustadas);

  double get entradasEfectivoAjustadas =>
      _money(entradasEfectivo + ajusteEfectivo);

  double get entradasTransferenciasAjustadas =>
      _money(entradasTransferencias + ajusteDigital);

  double diferenciaEfectivoAjustada({required double efectivo}) =>
      _money(efectivo - efectivoEsperadoAjustado);

  double diferenciaTransferenciaAjustada({required double transferencias}) =>
      _money(transferencias - transferenciasEsperadasAjustadas);

  double diferenciaAjustada({
    required double efectivo,
    required double transferencias,
  }) => _money(
    (efectivo - efectivoEsperadoAjustado) +
        (transferencias - transferenciasEsperadasAjustadas),
  );

  factory CashCloseSummary.calculate(
    SesionCaja sesion,
    Iterable<MovimientoCaja> movimientos, {
    List<CashProductSale> ventasPorProducto = const [],
    List<PreparedStockBalance> preparadosRestantes = const [],
    double gastosDelCiclo = 0,
    CashHistoricalAdjustment ajusteHistorico = const CashHistoricalAdjustment(),
  }) {
    var efectivo = sesion.montoApertura;
    var transferencias = sesion.transferenciasApertura;
    var gastos = 0.0;
    var ventasEfectivo = 0.0;
    var ventasTransferencias = 0.0;
    var entradasEfectivo = 0.0;
    var entradasTransferencias = 0.0;
    var salidasEfectivo = 0.0;
    var salidasTransferencias = 0.0;
    for (final movimiento in movimientos) {
      if (movimiento.tipo == 'apertura') continue;
      final esTransferencia = CashPaymentMethod.esDigital(
        movimiento.metodoPago,
      );
      final esEfectivo = CashPaymentMethod.esEfectivo(movimiento.metodoPago);
      final esEntrada =
          movimiento.tipo == 'entrada' || movimiento.tipo == 'venta';
      final esSalida =
          movimiento.tipo == 'salida' ||
          movimiento.tipo == 'compra' ||
          movimiento.tipo == 'gasto';
      if (esEntrada) {
        if (esTransferencia) {
          transferencias += movimiento.monto;
          entradasTransferencias += movimiento.monto;
        } else if (esEfectivo) {
          efectivo += movimiento.monto;
          entradasEfectivo += movimiento.monto;
        }
        if (movimiento.tipo == 'venta') {
          if (esTransferencia) ventasTransferencias += movimiento.monto;
          if (esEfectivo) ventasEfectivo += movimiento.monto;
        }
      } else if (esSalida) {
        if (esTransferencia) {
          transferencias -= movimiento.monto;
          salidasTransferencias += movimiento.monto;
          gastos += movimiento.monto;
        } else if (esEfectivo) {
          efectivo -= movimiento.monto;
          salidasEfectivo += movimiento.monto;
          gastos += movimiento.monto;
        }
      }
    }
    return CashCloseSummary(
      efectivoEsperado: _money(efectivo),
      transferenciasEsperadas: _money(transferencias),
      gastos: _money(gastos),
      gastosDelCiclo: _money(gastosDelCiclo),
      ventasEfectivo: _money(ventasEfectivo),
      ventasTransferencias: _money(ventasTransferencias),
      entradasEfectivo: _money(entradasEfectivo),
      entradasTransferencias: _money(entradasTransferencias),
      salidasEfectivo: _money(salidasEfectivo),
      salidasTransferencias: _money(salidasTransferencias),
      ventasPorProducto: ventasPorProducto,
      preparadosRestantes: preparadosRestantes,
      ajusteHistorico: ajusteHistorico,
    );
  }
}
