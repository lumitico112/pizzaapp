import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/features/preparation/data/repositories/preparacion_repository.dart';
import 'package:pizzaapp/features/waste/application/merma_service.dart';
import 'package:pizzaapp/features/waste/data/repositories/merma_repository.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Caso SEC-028 de la evaluacion FS-2: venta, merma y transformacion
/// concurrentes sobre el mismo stock descuentan una sola vez por operacion
/// (fuente unica `StockMovementWriter`), y un reintento tras un fallo no
/// duplica movimientos.
void main() {
  group('Integridad de inventario (SEC-028)', () {
    late Database db;
    late int origenId;
    late int destinoId;
    late int reglaId;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();

      final catId = await db.insert('Categorias', {'nombre': 'Inventario'});
      final origenProd = await db.insert('Productos', {
        'categoria_id': catId,
        'nombre': 'Pizza Origen',
        'tipo_preparacion': 'anticipado',
        'activo': 1,
      });
      origenId = await db.insert('VariantesProducto', {
        'producto_id': origenProd,
        'nombre_variante': 'Entera',
        'precio_venta': 10.0,
        'costo_estimado_manual': 4.0,
        'stock': 10,
        'active': 1,
      });
      final destinoProd = await db.insert('Productos', {
        'categoria_id': catId,
        'nombre': 'Pizza Transformada',
        'tipo_preparacion': 'anticipado',
        'activo': 1,
      });
      destinoId = await db.insert('VariantesProducto', {
        'producto_id': destinoProd,
        'nombre_variante': 'Unica',
        'precio_venta': 12.0,
        'costo_estimado_manual': 5.0,
        'stock': 0,
        'active': 1,
      });
      reglaId = await db.insert('Transformaciones', {
        'variante_origen_id': origenId,
        'variante_destino_id': destinoId,
        'rendimiento': 1.0,
        'activa': 1,
      });
      await db.insert('SesionesCaja', {
        'fecha_apertura': DateTime.now().toIso8601String(),
        'monto_apertura': 50.0,
        'estado': 'abierta',
      });
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    Future<int> stockDe(int varianteId) async {
      final rows = await db.query(
        'VariantesProducto',
        where: 'id = ?',
        whereArgs: [varianteId],
      );
      return rows.first['stock'] as int;
    }

    test('T1: venta, merma y transformacion concurrentes descuentan '
        'exactamente una vez cada una', () async {
      final ventaRepo = VentaRepository();
      final mermaService = MermaService(MermaRepository());
      final prepRepo = PreparacionRepository();
      final hoy = DateTime.now().toIso8601String().split('T').first;

      await Future.wait([
        ventaRepo
            .registrarVentaCompleta(
              Venta(
                fecha: hoy,
                hora: '12:00',
                metodoPago: 'efectivo',
                subtotal: 10.0,
                total: 10.0,
              ),
              [
                DetalleVenta(
                  ventaId: 0,
                  varianteId: origenId,
                  cantidad: 1,
                  precioUnitario: 10.0,
                ),
              ],
            )
            .then((_) {}),
        mermaService.registrarMerma(
          tipo: 'vencido',
          cantidad: 2,
          varianteId: origenId,
          descripcion: 'concurrencia SEC-028',
        ),
        prepRepo.aplicarTransformacion(reglaId: reglaId, cantidadOrigen: 4),
      ]);

      // 10 = 1 venta + 2 merma + 4 transformacion + 3 restantes.
      expect(await stockDe(origenId), 3);
      expect(await stockDe(destinoId), 4);
      expect(await db.query('Ventas'), hasLength(1));
      expect(await db.query('Merma'), hasLength(1));

      final movimientos = await db.query('MovimientosStockPreparado');
      expect(movimientos, hasLength(4));
      final tipos = movimientos.map((m) => m['tipo'] as String).toList()..sort();
      expect(tipos, [
        'merma',
        'transformacion_entrada',
        'transformacion_salida',
        'venta',
      ]);

      final deltaOrigen = movimientos
          .where((m) => m['variante_id'] == origenId)
          .fold<int>(0, (total, m) => total + (m['cantidad'] as num).toInt());
      expect(deltaOrigen, -7);
      final deltaDestino = movimientos
          .where((m) => m['variante_id'] == destinoId)
          .fold<int>(0, (total, m) => total + (m['cantidad'] as num).toInt());
      expect(deltaDestino, 4);
    });

    test('T2: una transformacion fallida no descuenta y el reintento '
        'aplica una sola vez', () async {
      final prepRepo = PreparacionRepository();
      await db.update(
        'VariantesProducto',
        {'stock': 2},
        where: 'id = ?',
        whereArgs: [origenId],
      );

      await expectLater(
        prepRepo.aplicarTransformacion(reglaId: reglaId, cantidadOrigen: 4),
        throwsA(anything),
      );

      expect(await stockDe(origenId), 2);
      expect(await stockDe(destinoId), 0);
      expect(await db.query('MovimientosStockPreparado'), isEmpty);

      await prepRepo.aplicarTransformacion(reglaId: reglaId, cantidadOrigen: 2);

      expect(await stockDe(origenId), 0);
      expect(await stockDe(destinoId), 2);
      final movimientos = await db.query('MovimientosStockPreparado');
      expect(movimientos, hasLength(2));
      final tipos = movimientos.map((m) => m['tipo'] as String).toList()..sort();
      expect(tipos, ['transformacion_entrada', 'transformacion_salida']);
    });
  });
}
