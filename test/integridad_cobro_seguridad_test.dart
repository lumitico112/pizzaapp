import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Correccion de hallazgos de FS-2: integridad del cobro.
/// H-1: importes negativos (venta por `-S/ 50` y cantidades negativas).
/// H-3: doble submit concurrente del cobro registraba dos ventas.
void main() {
  group('Integridad del cobro (H-1 / H-3)', () {
    late Database db;
    late Producto producto;
    late VarianteProducto variante;
    late int varianteId;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      final catId = await db.insert('Categorias', {'nombre': 'Seguridad'});
      final prodId = await db.insert('Productos', {
        'categoria_id': catId,
        'nombre': 'Pizza Seguridad',
        'tipo_preparacion': 'anticipado',
        'activo': 1,
      });
      varianteId = await db.insert('VariantesProducto', {
        'producto_id': prodId,
        'nombre_variante': 'Familiar',
        'precio_venta': 10.0,
        'costo_estimado_manual': 4.0,
        'stock': 5,
        'active': 1,
      });
      producto = Producto(
        id: prodId,
        categoriaId: catId,
        nombre: 'Pizza Seguridad',
        tipoPreparacion: 'anticipado',
        activo: 1,
      );
      variante = VarianteProducto(
        id: varianteId,
        productoId: prodId,
        nombreVariante: 'Familiar',
        precioVenta: 10.0,
        stock: 5,
        active: 1,
      );
      await db.insert('SesionesCaja', {
        'fecha_apertura': DateTime.now().toIso8601String(),
        'monto_apertura': 50.0,
        'estado': 'abierta',
      });
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    PosService crearServicio() => PosService(
      ProductoRepository(),
      VentaRepository(),
      CajaRepository(),
      PromocionRepository(),
    );

    Future<int> stockActual() async {
      final rows = await db.query(
        'VariantesProducto',
        where: 'id = ?',
        whereArgs: [varianteId],
      );
      return rows.first['stock'] as int;
    }

    VarianteProducto varianteConPrecio(double precio) => VarianteProducto(
      id: variante.id,
      productoId: variante.productoId,
      nombreVariante: variante.nombreVariante,
      precioVenta: precio,
      stock: variante.stock,
      active: variante.active,
    );

    test('T1a: el servicio rechaza un total negativo sin dejar rastro', () async {
      final service = crearServicio();

      await expectLater(
        service.registrarVenta(
          carrito: [
            CartItem(
              producto: producto,
              variante: varianteConPrecio(-50.0),
              cantidad: 1,
            ),
          ],
          metodoPago: 'efectivo',
          totalCalculado: -50.0,
          observaciones: 'prueba H-1',
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.query('Ventas'), isEmpty);
      expect(
        await db.query(
          'MovimientosCaja',
          where: "tipo IN ('venta','cortesia')",
        ),
        isEmpty,
      );
      expect(await stockActual(), 5);
    });

    test('T1b: el servicio rechaza un precio unitario negativo '
        'aunque el total sea cero', () async {
      final service = crearServicio();

      await expectLater(
        service.registrarVenta(
          carrito: [
            CartItem(
              producto: producto,
              variante: varianteConPrecio(-50.0),
              cantidad: 1,
            ),
          ],
          metodoPago: 'efectivo',
          totalCalculado: 0.0,
          observaciones: 'prueba H-1 precio',
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.query('Ventas'), isEmpty);
      expect(await stockActual(), 5);
    });

    test('T2: el controlador rechaza un precio personalizado negativo', () {
      final ctrl = PosController(crearServicio());

      final error = ctrl.agregarAlCarrito(
        PosItem(producto, variante),
        1,
        precioPersonalizado: -5.0,
      );

      expect(error, 'El precio no puede ser negativo.');
      expect(ctrl.carrito, isEmpty);
    });

    test('T3: el repositorio rechaza cantidad o precio negativos '
        'directos (sin subir stock)', () async {
      final repo = VentaRepository();
      final hoy = DateTime.now().toIso8601String().split('T').first;

      await expectLater(
        repo.registrarVentaCompleta(
          Venta(
            fecha: hoy,
            hora: '12:00',
            metodoPago: 'efectivo',
            subtotal: -50.0,
            total: -50.0,
          ),
          [
            DetalleVenta(
              ventaId: 0,
              varianteId: varianteId,
              cantidad: -2,
              precioUnitario: -25.0,
            ),
          ],
        ),
        throwsA(isA<Exception>()),
      );

      await expectLater(
        repo.registrarVentaCompleta(
          Venta(
            fecha: hoy,
            hora: '12:00',
            metodoPago: 'efectivo',
            subtotal: 50.0,
            total: 50.0,
          ),
          [
            DetalleVenta(
              ventaId: 0,
              varianteId: varianteId,
              cantidad: -2,
              precioUnitario: 25.0,
            ),
          ],
        ),
        throwsA(isA<Exception>()),
      );

      // El defecto original subia el stock 5 -> 7 con cantidad -2.
      expect(await stockActual(), 5);
      expect(await db.query('Ventas'), isEmpty);
      expect(await db.query('DetalleVenta'), isEmpty);
      expect(await db.query('MovimientosStockPreparado'), isEmpty);
    });

    test('T4: doble procesarCobro concurrente registra una sola venta', () async {
      final ctrl = PosController(crearServicio());
      expect(ctrl.agregarAlCarrito(PosItem(producto, variante), 1), isNull);

      final resultados = await Future.wait([
        ctrl.procesarCobro('efectivo', 'doble toque', montoRecibido: 20.0),
        ctrl.procesarCobro('efectivo', 'doble toque', montoRecibido: 20.0),
      ]);

      expect(resultados.where((r) => r != null), hasLength(1));
      expect(await db.query('Ventas'), hasLength(1));
      expect(
        await db.query('MovimientosCaja', where: "tipo = 'venta'"),
        hasLength(1),
      );
      expect(await db.query('DetalleVenta'), hasLength(1));
      expect(await stockActual(), 4);
      expect(ctrl.carrito, isEmpty);
    });
  });
}
