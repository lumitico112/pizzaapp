/// Clasificación oficial de medios de pago para el arqueo (RN-04).
///
/// La caja consolida únicamente dos rubros:
/// - efectivo;
/// - digital/bancario (`yape`, `plin`, `yape/plin`, `transferencia`, `tarjeta`).
class CashPaymentMethod {
  const CashPaymentMethod._();

  static String normalize(String? metodoPago) {
    return (metodoPago ?? '')
        .toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll('_', '/');
  }

  static bool esEfectivo(String? metodoPago) {
    return normalize(metodoPago) == 'efectivo';
  }

  static bool esDigital(String? metodoPago) {
    final metodo = normalize(metodoPago);
    return metodo == 'yape' ||
        metodo == 'plin' ||
        metodo == 'yape/plin' ||
        metodo == 'transferencia' ||
        metodo == 'tarjeta';
  }
}
