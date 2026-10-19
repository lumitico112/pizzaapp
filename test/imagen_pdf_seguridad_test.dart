import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Caso SEC-021 de la evaluacion FS-2: un logo corrupto o inexistente no
/// rompe la generacion de la boleta; el PDF se emite sin logo (error seguro).
/// H-4 (imagenes sin tope de tamano/dimensiones) queda reportado aparte y no
/// se codifica aqui como comportamiento esperado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  group('Boleta PDF con logo invalido (SEC-021)', () {
    late Database db;
    late Directory tempRoot;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      tempRoot = await Directory.systemTemp.createTemp('kimi_boleta_seg_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => tempRoot.path,
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      await TestDbHarness.closeDb(db);
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    PosService servicio() => PosService(
      ProductoRepository(),
      VentaRepository(),
      CajaRepository(),
      PromocionRepository(),
    );

    Venta ventaDePrueba(int id) => Venta(
      id: id,
      fecha: '2026-10-18',
      hora: '12:00',
      metodoPago: 'efectivo',
      subtotal: 10.0,
      total: 10.0,
    );

    List<DetalleVenta> detalleDePrueba(int ventaId) => [
      DetalleVenta(
        ventaId: ventaId,
        varianteId: 1,
        cantidad: 1,
        precioUnitario: 10.0,
      ),
    ];

    test('T1: un logo corrupto genera la boleta sin logo en lugar de fallar',
        () async {
      final corrupto = File('${tempRoot.path}/logo_corrupto.png');
      await corrupto.writeAsBytes(
        List<int>.generate(96, (i) => i % 251),
      );
      await ConfiguracionRepository().saveConfig('logo_ruta', corrupto.path);

      final ruta = await servicio().generarBoletaPDF(
        ventaDePrueba(1),
        detalleDePrueba(1),
      );

      expect(ruta, isNotNull);
      final archivo = File(ruta!);
      expect(await archivo.exists(), isTrue);
      expect(await archivo.length(), greaterThan(0));
      expect(archivo.path, contains('boletas'));
    });

    test('T2: un logo configurado pero inexistente tambien es error seguro',
        () async {
      await ConfiguracionRepository().saveConfig(
        'logo_ruta',
        '${tempRoot.path}/no_existe.png',
      );

      final ruta = await servicio().generarBoletaPDF(
        ventaDePrueba(2),
        detalleDePrueba(2),
      );

      expect(ruta, isNotNull);
      final archivo = File(ruta!);
      expect(await archivo.exists(), isTrue);
      expect(await archivo.length(), greaterThan(0));
    });
  });
}
