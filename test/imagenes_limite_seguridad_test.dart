import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pizzaapp/services/image_service.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

/// Corrección del hallazgo H-4 (SEC-021): las imágenes capturadas o
/// seleccionadas quedan limitadas en dimensiones (downscale en origen) y en
/// tamaño (tope de bytes con descarte seguro).
void main() {
  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
  });

  group('Limite de imagenes capturadas (H-4 / SEC-021)', () {
    late Directory tempDir;
    late _MockImagePicker picker;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kimi_img_limite_');
      picker = _MockImagePicker();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<File> archivoDe(int bytes, String nombre) async {
      final file = File('${tempDir.path}/$nombre');
      await file.writeAsBytes(Uint8List(bytes), flush: true);
      return file;
    }

    void stubPicked(XFile? xfile) {
      when(
        () => picker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => xfile);
    }

    test('T1: una imagen normal se devuelve con downscale aplicado', () async {
      final file = await archivoDe(1024, 'normal.jpg');
      stubPicked(XFile(file.path));

      final ruta = await ImageService(
        picker: picker,
      ).pickImageFromGallery();

      expect(ruta, file.path);
      verify(
        () => picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 70,
        ),
      ).called(1);
    });

    test('T2: una imagen sobredimensionada se descarta y se borra', () async {
      final file = await archivoDe(
        ImageService.maxBytesPorArchivo + 1024,
        'grande.jpg',
      );
      stubPicked(XFile(file.path));

      final ruta = await ImageService(picker: picker).pickImageFromCamera();

      expect(ruta, isNull);
      expect(await file.exists(), isFalse);
    });

    test('T3: la cancelacion devuelve null sin efecto en disco', () async {
      stubPicked(null);

      final ruta = await ImageService(picker: picker).pickImageFromGallery();

      expect(ruta, isNull);
    });

    test('T4: frontera del tope: exacto valido, un byte mas rechazado', () {
      expect(
        ImageService.excedeLimiteBytes(ImageService.maxBytesPorArchivo),
        isFalse,
      );
      expect(
        ImageService.excedeLimiteBytes(ImageService.maxBytesPorArchivo + 1),
        isTrue,
      );
    });

    test('T5: un archivo exacto en el tope se acepta', () async {
      final file = await archivoDe(
        ImageService.maxBytesPorArchivo,
        'limite.jpg',
      );
      stubPicked(XFile(file.path));

      final ruta = await ImageService(picker: picker).pickImageFromGallery();

      expect(ruta, file.path);
      expect(await file.exists(), isTrue);
    });
  });
}
