import 'package:pizzaapp/features/purchases/domain/entities/payable_balance.dart';

abstract interface class PayableRepository {
  Future<PayableBalance?> getBalance(int accountId);
  Future<void> registerPayment(PayablePayment payment);
}
