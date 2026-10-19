import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/features/purchases/application/compra_service.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/features/purchases/domain/usecases/register_payable_payment.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Casos SEC-018 y SEC-019 de la evaluacion FS-2.
/// SEC-018: entradas malformadas o de tipo incorrecto se rechazan por dominio
/// sin crash y sin dejar estado parcial.
/// SEC-019: importes extremos (infinito/NaN, frontera del hallazgo H-1).
void main() {
  group('Venta: entradas invalidas (SEC-018 / SEC-019)', () {
    late Database db;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    PosService servicio() => PosService(
      ProductoRepository(),
      VentaRepository(),
      CajaRepository(),
      PromocionRepository(),
    );

    final producto = Producto(
      id: 1,
      nombre: 'Pizza Entradas',
      tipoPreparacion: 'anticipado',
      activo: 1,
    );
    final variante = VarianteProducto(
      id: 1,
      productoId: 1,
      nombreVariante: 'Unica',
      precioVenta: 10.0,
      stock: 5,
      active: 1,
    );

    List<CartItem> carrito(double? precioPersonalizado) => [
      CartItem(
        producto: producto,
        variante: variante,
        cantidad: 1,
        precioPersonalizado: precioPersonalizado,
      ),
    ];

    test('T1: un carrito vacio se rechaza y no deja venta', () async {
      await expectLater(
        servicio().registrarVenta(
          carrito: const [],
          metodoPago: 'efectivo',
          totalCalculado: 10.0,
          observaciones: 'carrito vacio',
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.query('Ventas'), isEmpty);
      expect(await db.query('DetalleVenta'), isEmpty);
    });

    test('T2: fecha malformada o futura se rechaza sin registrar', () async {
      Future<void> intentar(String fecha) => expectLater(
        servicio().registrarVenta(
          carrito: carrito(null),
          metodoPago: 'efectivo',
          totalCalculado: 10.0,
          observaciones: 'fecha invalida',
          fechaPersonalizada: fecha,
        ),
        throwsA(isA<Exception>()),
      );

      await intentar('no-es-fecha');
      await intentar(
        DateTime.now()
            .add(const Duration(days: 2))
            .toIso8601String()
            .split('T')
            .first,
      );

      expect(await db.query('Ventas'), isEmpty);
      expect(await db.query('DetalleVenta'), isEmpty);
    });

    test('T3: importes no finitos (infinito/NaN) se rechazan', () async {
      // Total infinito:
      await expectLater(
        servicio().registrarVenta(
          carrito: carrito(null),
          metodoPago: 'efectivo',
          totalCalculado: double.infinity,
          observaciones: 'total infinito',
        ),
        throwsA(isA<Exception>()),
      );

      // Total NaN:
      await expectLater(
        servicio().registrarVenta(
          carrito: carrito(null),
          metodoPago: 'efectivo',
          totalCalculado: double.nan,
          observaciones: 'total NaN',
        ),
        throwsA(isA<Exception>()),
      );

      // Precio personalizado infinito con total finito:
      await expectLater(
        servicio().registrarVenta(
          carrito: carrito(double.infinity),
          metodoPago: 'efectivo',
          totalCalculado: 10.0,
          observaciones: 'precio infinito',
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.query('Ventas'), isEmpty);
      expect(await db.query('MovimientosStockPreparado'), isEmpty);
    });

    test('T4: un monto recibido que no cubre el total se rechaza', () async {
      await expectLater(
        servicio().registrarVenta(
          carrito: carrito(null),
          metodoPago: 'efectivo',
          totalCalculado: 10.0,
          observaciones: 'monto insuficiente',
          montoRecibido: 5.0,
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.query('Ventas'), isEmpty);
      expect(await db.query('MovimientosCaja'), isEmpty);
    });
  });

  group('Compra: entradas invalidas (SEC-018)', () {
    late Database db;
    late CompraService service;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      final repo = PurchaseRepository();
      service = CompraService(
        repo,
        GastoRepository(),
        AuthService(UsuarioRepository()),
        RegisterPayablePayment(repo),
      );
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    test('T5: cantidad o costo invalidos, e insumo inexistente, se rechazan '
        'sin dejar ajuste ni gasto', () async {
      await expectLater(
        service.registrarCompraDirecta(
          insumoId: 1,
          cantidad: 0,
          costoTotal: 10.0,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.registrarCompraDirecta(
          insumoId: 1,
          cantidad: 1,
          costoTotal: -5.0,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.registrarCompraDirecta(
          insumoId: 1,
          cantidad: double.infinity,
          costoTotal: 10.0,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.registrarCompraDirecta(
          insumoId: 999999,
          cantidad: 1,
          costoTotal: 10.0,
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.query('AjustesStock'), isEmpty);
      expect(await db.query('Gastos'), isEmpty);
      expect(await db.query('MovimientosCaja'), isEmpty);
    });

    test('T6: adelanto fuera de rango o cuotas invalidas no crean cuenta '
        'por pagar', () async {
      await expectLater(
        service.registrarCompraPorPagar(
          insumoId: 1,
          cantidad: 1,
          costoTotal: 20.0,
          adelanto: 30.0,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.registrarCompraPorPagar(
          insumoId: 1,
          cantidad: 1,
          costoTotal: 20.0,
          adelanto: -1.0,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.registrarCompraPorPagar(
          insumoId: 1,
          cantidad: 1,
          costoTotal: 20.0,
          adelanto: 0,
          cuotas: 0,
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.query('CuentasPorPagar'), isEmpty);
      expect(await db.query('PagosCuentaPorPagar'), isEmpty);
      expect(await db.query('AjustesStock'), isEmpty);
    });
  });
}
