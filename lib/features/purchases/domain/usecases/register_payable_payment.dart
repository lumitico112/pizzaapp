import 'package:pizzaapp/features/purchases/domain/entities/payable_balance.dart';
import 'package:pizzaapp/features/purchases/domain/repositories/payable_repository.dart';

class RegisterPayablePayment {
  final PayableRepository _repository;

  const RegisterPayablePayment(this._repository);

  Future<void> call(PayablePayment payment) async {
    final balance = await _repository.getBalance(payment.accountId);
    if (balance == null) {
      throw const PayableRuleException('La cuenta por pagar ya no existe.');
    }
    balance.balanceAfter(payment.amount);
    await _repository.registerPayment(payment);
  }
}
