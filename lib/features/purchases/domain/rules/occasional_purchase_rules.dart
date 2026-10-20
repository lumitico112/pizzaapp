/// Reglas puras de una compra ocasional, independientes de SQLite y de la UI.
class OccasionalPurchaseRules {
  static const Set<String> categoriasReservadas = {
    'compras',
    'activos fijos',
    'cuentas por pagar',
  };

  /// Categorías sugeridas para la bandeja de gastos. No incluye las categorías
  /// reservadas que los reportes excluyen.
  static const List<String> categoriasSugeridas = [
    'Insumos',
    'Servicios',
    'Mantenimiento',
    'Transporte',
    'Limpieza',
    'Equipamiento',
    'Otros',
  ];

  static const Set<String> metodosPago = {
    'efectivo',
    'yape',
    'plin',
    'yape/plin',
  };

  static String normalizarCategoria(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  static bool categoriaPermitida(String value) {
    final normalizada = normalizarCategoria(value);
    return normalizada.isNotEmpty &&
        !categoriasReservadas.contains(normalizada);
  }

  static void validar({
    required String descripcion,
    required double cantidad,
    required double costoTotal,
    required String categoria,
    required bool esPorPagar,
    required double adelanto,
    required int cuotas,
    required String metodoPago,
  }) {
    if (descripcion.trim().isEmpty) {
      throw Exception('La descripción de la compra ocasional es obligatoria.');
    }
    if (!cantidad.isFinite || cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor a cero.');
    }
    if (!costoTotal.isFinite || costoTotal <= 0) {
      throw Exception('El costo total debe ser mayor a cero.');
    }
    if (!categoriaPermitida(categoria)) {
      throw Exception(
        'La categoría "${categoria.trim()}" no es válida. No uses Compras, '
        'Activos Fijos ni Cuentas por Pagar.',
      );
    }
    if (!adelanto.isFinite || adelanto < 0) {
      throw Exception('El adelanto no puede ser negativo.');
    }
    if (adelanto > costoTotal + 0.000001) {
      throw Exception('El adelanto no puede superar el costo total.');
    }
    if (!esPorPagar && adelanto != 0) {
      throw Exception('Una compra al contado no puede tener adelanto.');
    }
    if (cuotas < 1) {
      throw Exception('Las cuotas deben ser al menos 1.');
    }
    final metodo = metodoPago.trim().toLowerCase();
    if (!metodosPago.contains(metodo)) {
      throw Exception('El método de pago no es válido.');
    }
  }

  static String descripcionEstructurada({
    required String categoria,
    required String descripcion,
    required double cantidad,
    String? unidadMedida,
  }) {
    final unidad = unidadMedida?.trim();
    final sufijoUnidad = (unidad == null || unidad.isEmpty) ? '' : ' $unidad';
    return 'Compra ocasional - ${categoria.trim()}: ${descripcion.trim()} '
        '(${cantidadTexto(cantidad)}$sufijoUnidad)';
  }

  static String cantidadTexto(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
