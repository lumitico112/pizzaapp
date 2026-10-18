import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase 4 (H-07): la venta debe quedar confirmada aunque falle la generación
/// de la boleta. `registrarVenta` no propaga el error del PDF post-commit y el
/// cobro se completa informando "boleta pendiente" (reimprimible).
class _ServicioBoletaFalla extends PosService {
  _ServicioBoletaFalla()
      : super(
          ProductoRepository(),
          VentaRepository(),
          CajaRepository(),
          PromocionRepository(),
        );

  @override
  Future<String?> generarBoletaPDF(
    Venta venta,
    List<DetalleVenta> detalles, [
    List<CartItem>? carrito,
  ]) async {
    throw Exception('Fallo simulado al generar la boleta.');
  }
}

class _ServicioBoletaOk extends PosService {
  _ServicioBoletaOk()
      : super(
          ProductoRepository(),
          VentaRepository(),
          CajaRepository(),
          PromocionRepository(),
        );

  @override
  Future<String?> generarBoletaPDF(
    Venta venta,
    List<DetalleVenta> detalles, [
    List<CartItem>? carrito,
  ]) async {
    return '/tmp/boletas/boleta_${venta.id}.pdf';
  }
}

class _ServicioCobroSimulado extends PosService {
  _ServicioCobroSimulado(this.modo)
      : super(
          ProductoRepository(),
          VentaRepository(),
          CajaRepository(),
          PromocionRepository(),
        );

  /// 'pdf' | 'sin_boleta' | 'falla'
  final String modo;

  @override
  Future<String?> registrarVenta({
    required List<CartItem> carrito,
    required String metodoPago,
    required double totalCalculado,
    required String observaciones,
    String? fechaPersonalizada,
    double? montoRecibido,
  }) async {
    if (modo == 'falla') {
      throw Exception('Abre una caja antes de registrar ventas.');
    }
    return modo == 'pdf' ? '/tmp/boletas/boleta_9.pdf' : null;
  }

  @override
  Future<List<Promocion>> getPromociones() async => [];

  @override
  Future<List<PosItem>> getPosItems(int? categoriaId) async => [];
}

String _fechaAyer() {
  final ayer = DateTime.now().subtract(const Duration(days: 1));
  return '${ayer.year.toString().padLeft(4, '0')}-'
      '${ayer.month.toString().padLeft(2, '0')}-'
      '${ayer.day.toString().padLeft(2, '0')}';
}

void main() {
  group('Fase 4 (H-07): resiliencia de la boleta en el cobro', () {
    late Database db;
    late Producto producto;
    late VarianteProducto variante;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      final prodRepo = ProductoRepository();
      final catId = await prodRepo.insertCategoria(
        Categoria(nombre: 'F4 Test'),
      );
      await prodRepo.guardarProductoCompleto(
        Producto(
          categoriaId: catId,
          nombre: 'PIZZA F4',
          tipoPreparacion: 'momento',
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
      producto = (await prodRepo.getProductos(categoriaId: catId)).first;
      variante = (await prodRepo.getVariantesPorProducto(producto.id!)).first;
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    test(
      'T1: si la boleta falla tras el commit, registrarVenta NO lanza, '
      'devuelve null y la venta + detalle quedan en BD',
      () async {
        final service = _ServicioBoletaFalla();

        final resultado = await service.registrarVenta(
          carrito: [
            CartItem(
              producto: producto,
              variante: variante,
              cantidad: 2,
              esCortesia: true,
            ),
          ],
          metodoPago: 'efectivo',
          totalCalculado: 0.0,
          observaciones: 'prueba H-07',
          fechaPersonalizada: _fechaAyer(),
        );

        expect(resultado, isNull);

        final ventas = await db.query('Ventas');
        expect(ventas, hasLength(1));
        final ventaId = ventas.first['id'] as int;
        final detalles = await db.query(
          'DetalleVenta',
          where: 'venta_id = ?',
          whereArgs: [ventaId],
        );
        expect(detalles, hasLength(1));
        expect(detalles.first['variante_id'], variante.id);
      },
    );

    test('T2: flujo normal devuelve la ruta del PDF generado', () async {
      final service = _ServicioBoletaOk();

      final resultado = await service.registrarVenta(
        carrito: [
          CartItem(
            producto: producto,
            variante: variante,
            cantidad: 1,
            esCortesia: true,
          ),
        ],
        metodoPago: 'efectivo',
        totalCalculado: 0.0,
        observaciones: 'prueba H-07 ok',
        fechaPersonalizada: _fechaAyer(),
      );

      expect(resultado, isNotNull);
      expect(resultado, contains('boleta_'));
      final ventas = await db.query('Ventas');
      expect(ventas, hasLength(1));
    });

    test(
      'T3: procesarCobro distingue "venta sin boleta" (boletaPendiente) '
      'de un fallo total (carrito intacto + error)',
      () async {
        // a) Venta + boleta OK.
        final ctrlOk = PosController(_ServicioCobroSimulado('pdf'));
        expect(ctrlOk.agregarAlCarrito(PosItem(producto, variante), 1), isNull);
        final rOk = await ctrlOk.procesarCobro('efectivo', '');
        expect(rOk, isNotNull);
        expect(rOk!.pdfPath, '/tmp/boletas/boleta_9.pdf');
        expect(rOk.boletaPendiente, isFalse);
        expect(ctrlOk.carrito, isEmpty);

        // b) Venta registrada, boleta fallida: cobro exitoso con pendiente.
        final ctrlPendiente = PosController(
          _ServicioCobroSimulado('sin_boleta'),
        );
        expect(
          ctrlPendiente.agregarAlCarrito(PosItem(producto, variante), 1),
          isNull,
        );
        final rPendiente = await ctrlPendiente.procesarCobro('efectivo', '');
        expect(rPendiente, isNotNull);
        expect(rPendiente!.pdfPath, isNull);
        expect(rPendiente.boletaPendiente, isTrue);
        expect(ctrlPendiente.error, isNull);
        expect(ctrlPendiente.carrito, isEmpty);

        // c) Fallo total previo al commit: sin resultado, error visible y
        //    carrito intacto para que el cajero decida (sin doble venta).
        final ctrlFalla = PosController(_ServicioCobroSimulado('falla'));
        expect(ctrlFalla.agregarAlCarrito(PosItem(producto, variante), 1), isNull);
        final rFalla = await ctrlFalla.procesarCobro('efectivo', '');
        expect(rFalla, isNull);
        expect(ctrlFalla.error, isNotNull);
        expect(ctrlFalla.carrito, hasLength(1));
      },
    );
  });
}
