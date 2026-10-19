import 'dart:math' as math;

import 'unit_converter.dart';

/// Calculates how many portions the current ingredient balances can produce.
class RecipeYieldCalculator {
  static int maxPortions(List<Map<String, dynamic>> requirements) {
    if (requirements.isEmpty) {
      return 0;
    }
    var maximum = 1 << 31;
    for (final requirement in requirements) {
      final amount = (requirement['cantidad'] as num).toDouble();
      if (amount <= 0) {
        throw ArgumentError('La cantidad de receta debe ser mayor a cero.');
      }
      final baseAmount = UnitConverter.convert(
        amount,
        requirement['unidad_receta'] as String,
        requirement['unidad_stock'] as String,
        packageContent:
            (requirement['contenido_paquete'] as num?)?.toInt() ?? 1,
      );
      if (baseAmount <= 0) {
        throw ArgumentError(
          'La receta tiene una conversión de unidad inválida.',
        );
      }
      final stock = (requirement['stock_actual'] as num?)?.toDouble() ?? 0;
      maximum = math.min(maximum, (stock / baseAmount).floor());
    }
    return maximum;
  }
}
