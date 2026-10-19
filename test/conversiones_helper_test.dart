import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/features/inventory/domain/services/unit_converter.dart';

void main() {
  group('UnitConverter', () {
    test('misma unidad retorna la misma cantidad', () {
      expect(UnitConverter.convert(100, 'g', 'g'), equals(100));
      expect(UnitConverter.convert(5, 'Kg', 'Kg'), equals(5));
      expect(UnitConverter.convert(2, 'Litros', 'Litros'), equals(2));
    });

    test('Kg a gr multiplica por 1000', () {
      expect(UnitConverter.convert(1.5, 'Kg', 'gr'), equals(1500));
      expect(UnitConverter.convert(0.5, 'Kg', 'g'), equals(500));
    });

    test('gr a Kg divide por 1000', () {
      expect(UnitConverter.convert(1500, 'gr', 'Kg'), equals(1.5));
      expect(UnitConverter.convert(500, 'g', 'Kg'), equals(0.5));
    });

    test('Litros a ml multiplica por 1000', () {
      expect(UnitConverter.convert(2, 'Litros', 'ml'), equals(2000));
    });

    test('ml a Litros divide por 1000', () {
      expect(UnitConverter.convert(2500, 'ml', 'Litros'), equals(2.5));
    });
  });
}
