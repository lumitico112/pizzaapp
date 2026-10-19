/// Domain representation of a payable's paid amount and remaining balance.
class PayableBalance {
  final int accountId;
  final double total;
  final double paid;
  final int installments;

  const PayableBalance({
    required this.accountId,
    required this.total,
    required this.paid,
    required this.installments,
  });

  double get remaining => (total - paid).clamp(0, double.infinity);
  bool get isSettled => remaining <= 0.000001;

  double balanceAfter(double payment) {
    if (!payment.isFinite || payment <= 0) {
      throw const PayableRuleException('El abono debe ser mayor a cero.');
    }
    if (payment > remaining + 0.000001) {
      throw const PayableRuleException('El abono supera el saldo pendiente.');
    }
    return (remaining - payment).clamp(0, double.infinity);
  }
}

class PayablePayment {
  final int accountId;
  final double amount;
  final String paymentMethod;
  final String? note;
  final int? userId;

  const PayablePayment({
    required this.accountId,
    required this.amount,
    required this.paymentMethod,
    this.note,
    this.userId,
  });
}

class PayableRuleException implements Exception {
  final String message;
  const PayableRuleException(this.message);

  @override
  String toString() => message;
}
