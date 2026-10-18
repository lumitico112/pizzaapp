/// Domain rule for converting between inventory and recipe units.
///
/// This stays independent of Flutter, storage, and presentation code so the
/// same conversion behavior can be used by recipes and preparation.
class UnitConverter {
  static double convert(
    double quantity,
    String fromUnit,
    String toUnit, {
    int packageContent = 1,
  }) {
    final from = _canonical(fromUnit);
    final to = _canonical(toUnit);
    if (from == to) return quantity;
    if (from == 'kg' && to == 'g') return quantity * 1000;
    if (from == 'g' && to == 'kg') return quantity / 1000;
    if (from == 'l' && to == 'ml') return quantity * 1000;
    if (from == 'ml' && to == 'l') return quantity / 1000;
    if (from == 'paquete' && to == 'unidad') {
      return quantity * _validPackageContent(packageContent);
    }
    if (from == 'unidad' && to == 'paquete') {
      return quantity / _validPackageContent(packageContent);
    }
    throw ArgumentError('No se puede convertir $fromUnit a $toUnit.');
  }

  static String _canonical(String unit) {
    final value = unit.trim().toLowerCase().replaceAll('.', '');
    if (['kg', 'kilogramo', 'kilogramos'].contains(value)) return 'kg';
    if (['g', 'gr', 'gramo', 'gramos'].contains(value)) return 'g';
    if (['l', 'lt', 'litro', 'litros'].contains(value)) return 'l';
    if (['ml', 'mililitro', 'mililitros'].contains(value)) return 'ml';
    if (['paquete', 'paquetes', 'pack', 'packs'].contains(value)) {
      return 'paquete';
    }
    if (['un', 'und', 'unidad', 'unidades'].contains(value)) return 'unidad';
    return value;
  }

  static int _validPackageContent(int content) {
    if (content <= 0) {
      throw ArgumentError('El contenido del paquete debe ser mayor a cero.');
    }
    return content;
  }
}
