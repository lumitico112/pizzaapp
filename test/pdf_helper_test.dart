import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/utils/pdf_helper.dart';

void main() {
  group('PdfHelper.sanitize', () {
    test('remueve tildes de vocales minúsculas y mayúsculas', () {
      expect(PdfHelper.sanitize('América'), equals('America'));
      expect(PdfHelper.sanitize('Árbol'), equals('Arbol'));
      expect(PdfHelper.sanitize('canción'), equals('cancion'));
    });

    test('reemplaza la ñ', () {
      expect(PdfHelper.sanitize('piña'), equals('pina'));
      expect(PdfHelper.sanitize('Ñandú'), equals('Nandu'));
    });

    test('elimina emojis y caracteres no-ASCII que no estén mapeados', () {
      expect(PdfHelper.sanitize('Hola 🍕'), equals('Hola '));
    });

    test('mantiene texto normal sin alterar', () {
      expect(PdfHelper.sanitize('Margarita'), equals('Margarita'));
    });
  });
}
