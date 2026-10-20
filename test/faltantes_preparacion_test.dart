import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/utils/sugerencias_algoritmo.dart';
import 'package:pizzaapp/features/inventory/data/stock_movement_writer.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase 5 (H-03): la demanda no satisfecha por falta de stock preparado se
/// registra en `FaltantesPreparacion` (fuera de la transacción de venta, para
/// sobrevivir al rollback) y alimenta `SugerenciasAlgoritmo` (weekday-aware).
void main() {
  late Database db;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<VarianteProducto> crearProductoConVariante({
    required String nombre,
    required String tipoPreparacion,
  }) async {
    final prodRepo = ProductoRepository();
    final catId = await prodRepo.insertCategoria(Categoria(nombre: 'F5 $nombre'));
    await prodRepo.guardarProductoCompleto(
      Producto(
        categoriaId: catId,
        nombre: nombre,
        tipoPreparacion: tipoPreparacion,
        activo: 1,
      ),
      [
        VarianteProducto(
          productoId: 0,
          nombreVariante: 'Unica',
          precioVenta: 10.0,
        ),
      ],
    );
    final producto = (await prodRepo.getProductos(categoriaId: catId)).first;
    return (await prodRepo.getVariantesPorProducto(producto.id!)).first;
  }

  group('Fase 5 (H-03): faltantes de preparación', () {
    test(
      'T1: venta anticipado sin stock preparado lanza StockPreparadoInsuficiente '
      'y deja el faltante registrado (sin rollback)',
      () async {
        final variante = await crearProductoConVariante(
          nombre: 'PIZZA F5 A',
          tipoPreparacion: 'anticipado',
        );
        expect(variante.stock, 0);

        final venta = Venta(
          fecha: '2026-10-16',
          hora: '10:00',
          subtotal: 0.0,
          total: 0.0,
          metodoPago: 'efectivo',
        );
        final detalles = [
          DetalleVenta(
            ventaId: 0,
            varianteId: variante.id,
            cantidad: 3,
            precioUnitario: 0.0,
            esCortesia: true,
          ),
        ];

        await expectLater(
          VentaRepository().registrarVentaCompleta(venta, detalles),
          throwsA(isA<StockPreparadoInsuficiente>()),
        );

        // Anti-rollback: la transacción no dejó venta ni detalle...
        expect(await db.query('Ventas'), isEmpty);
        expect(await db.query('DetalleVenta'), isEmpty);

        // ...pero la señal de demanda no satisfecha sí quedó registrada.
        final faltantes = await db.query('FaltantesPreparacion');
        expect(faltantes, hasLength(1));
        expect(faltantes.first['variante_id'], variante.id);
        expect(faltantes.first['cantidad'], 3);
        expect(faltantes.first['fecha'], '2026-10-16');
      },
    );

    test(
      'T1b: venta ambos sin receta reporta el faltante tipado con la cantidad '
      'no cubierta por stock preparado',
      () async {
        final variante = await crearProductoConVariante(
          nombre: 'PIZZA F5 B',
          tipoPreparacion: 'ambos',
        );

        final venta = Venta(
          fecha: '2026-10-16',
          hora: '11:00',
          subtotal: 0.0,
          total: 0.0,
          metodoPago: 'efectivo',
        );
        final detalles = [
          DetalleVenta(
            ventaId: 0,
            varianteId: variante.id,
            cantidad: 2,
            precioUnitario: 0.0,
            esCortesia: true,
          ),
        ];

        await expectLater(
          VentaRepository().registrarVentaCompleta(venta, detalles),
          throwsA(
            isA<StockPreparadoInsuficiente>()
                .having((e) => e.cantidadFaltante, 'cantidadFaltante', 2)
                .having((e) => e.varianteId, 'varianteId', variante.id),
          ),
        );

        expect(await db.query('Ventas'), isEmpty);
        final faltantes = await db.query('FaltantesPreparacion');
        expect(faltantes, hasLength(1));
        expect(faltantes.first['cantidad'], 2);
      },
    );

    test(
      'T2: faltantes del mismo día de la semana suben promedioFaltantes y la '
      'sugerencia (weekday-aware)',
      () async {
        final variante = await crearProductoConVariante(
          nombre: 'PIZZA F5 C',
          tipoPreparacion: 'anticipado',
        );

        // 2026-10-14 es miércoles (weekday SQLite 3); ventana > 2026-09-16.
        final mismoDia = [
          ('2026-10-07', 3),
          ('2026-09-30', 3),
          ('2026-09-23', 2),
        ];
        for (final fila in mismoDia) {
          await db.insert('FaltantesPreparacion', {
            'variante_id': variante.id,
            'fecha': fila.$1,
            'cantidad': fila.$2,
            'motivo': 'prueba',
          });
        }
        // Ruido que NO debe contar: otro día de la semana y fuera de ventana.
        await db.insert('FaltantesPreparacion', {
          'variante_id': variante.id,
          'fecha': '2026-10-08',
          'cantidad': 100,
          'motivo': 'otro weekday',
        });
        await db.insert('FaltantesPreparacion', {
          'variante_id': variante.id,
          'fecha': '2026-09-01',
          'cantidad': 200,
          'motivo': 'fuera de ventana',
        });

        final res = await SugerenciasAlgoritmo.calcularSugerencia(
          db: db,
          varianteId: variante.id!,
          fechaSugerencia: DateTime(2026, 10, 14),
        );

        // (3 + 3 + 2) / 4 semanas = 2.0; sin ventas ni sobrantes.
        expect(res['promedioFaltantes'], 2.0);
        expect(res['sugerenciaFinal'], 2);
      },
    );

    test(
      'T3: sin faltantes el promedio vuelve a 0 y la fórmula sigue usando '
      'ventas (no regresión)',
      () async {
        final variante = await crearProductoConVariante(
          nombre: 'PIZZA F5 D',
          tipoPreparacion: 'anticipado',
        );

        // Venta de 8 unidades el mismo weekday (miércoles) en la ventana.
        final ventaId = await db.insert(
          'Ventas',
          Venta(
            fecha: '2026-10-07',
            hora: '12:00',
            subtotal: 80.0,
            total: 80.0,
            metodoPago: 'efectivo',
          ).toMap(),
        );
        await db.insert(
          'DetalleVenta',
          DetalleVenta(
            ventaId: ventaId,
            varianteId: variante.id,
            cantidad: 8,
            precioUnitario: 10.0,
          ).toMap(),
        );

        final res = await SugerenciasAlgoritmo.calcularSugerencia(
          db: db,
          varianteId: variante.id!,
          fechaSugerencia: DateTime(2026, 10, 14),
        );

        expect(res['promedioVentas'], 2.0);
        expect(res['promedioFaltantes'], 0.0);
        expect(res['sugerenciaFinal'], 2);
      },
    );

    test(
      'T4: migración v24 -> v27 crea FaltantesPreparacion + índice y '
      'foreign_key_check queda limpio',
      () async {
        // Simular un estado v24: la tabla nueva no existe.
        await db.execute('DROP TABLE IF EXISTS FaltantesPreparacion');

        await DatabaseHelper.instance.upgradeDatabase(
          db,
          24,
          DatabaseHelper.databaseVersion,
        );

        expect(DatabaseHelper.databaseVersion, 27);

        final tablas = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'FaltantesPreparacion'",
        );
        expect(tablas, hasLength(1));

        final indices = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'IDX_FaltantesPreparacion_variante_fecha'",
        );
        expect(indices, hasLength(1));

        expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);

        // FK en tiempo real: una variante inexistente es rechazada.
        await expectLater(
          () => db.insert('FaltantesPreparacion', {
            'variante_id': 999999,
            'fecha': '2026-10-17',
            'cantidad': 1,
          }),
          throwsA(anything),
        );
      },
    );
  });
}
