class AssetAcquisitionRules {
  static const conditions = {'Comprado', 'Alquilado', 'Prestado', 'Regalado'};
  static const paymentMethods = {'Contado', 'Crédito'};

  const AssetAcquisitionRules._();

  static bool countsAsInvestment(String condition) => condition == 'Comprado';

  static void validate({
    required String name,
    required String condition,
    required String paymentMethod,
    required double totalCost,
    required int quantity,
    required int installments,
    required double advance,
    bool forUpdate = false,
  }) {
    if (name.trim().isEmpty) {
      throw const AssetRuleException('El nombre del activo es obligatorio.');
    }
    if (!conditions.contains(condition)) {
      throw const AssetRuleException(
        'La condición de adquisición no es válida.',
      );
    }
    if (!totalCost.isFinite || totalCost < 0) {
      throw const AssetRuleException(
        'El costo del activo no puede ser negativo.',
      );
    }
    if (quantity < 1) {
      throw const AssetRuleException('La cantidad debe ser mayor a cero.');
    }
    if (condition == 'Comprado' && !paymentMethods.contains(paymentMethod)) {
      throw const AssetRuleException(
        'El método de pago del activo no es válido.',
      );
    }
    if (!forUpdate && condition == 'Comprado' && totalCost <= 0) {
      throw const AssetRuleException(
        'El costo debe ser mayor a cero para un activo comprado.',
      );
    }
    if (!forUpdate &&
        condition == 'Comprado' &&
        paymentMethod == 'Crédito' &&
        installments < 1) {
      throw const AssetRuleException(
        'El número de cuotas debe ser al menos uno.',
      );
    }
    if (!advance.isFinite || advance < 0 || advance > totalCost) {
      throw const AssetRuleException(
        'El adelanto debe estar entre cero y el costo total.',
      );
    }
  }
}

class AssetRuleException implements Exception {
  final String message;
  const AssetRuleException(this.message);

  @override
  String toString() => message;
}
