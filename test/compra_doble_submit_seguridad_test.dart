import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/features/purchases/application/compra_service.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/features/purchases/domain/usecases/register_payable_payment.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/compras_controller.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Correccion del hallazgo H-2 de FS-2: el doble submit de una compra
/// (doble toque o reintento) duplicaba stock, gasto, movimiento de caja y,
/// en compras a credito, la cuenta por pagar y su adelanto.
void main() {
  group('Doble submit de compras (H-2)', () {
    late Database db;
    late int insumoId;
    late ComprasController ctrl;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      insumoId = await db.insert('Insumos', {
        'nombre': 'Harina Seguridad',
        'stock_actual': 0.0,
        'unidad_medida': 'kg',
        'costo_por_unidad': 5.0,
      });
      await db.insert('SesionesCaja', {
        'fecha_apertura': DateTime.now().toIso8601String(),
        'monto_apertura': 100.0,
        'estado': 'abierta',
      });

      final repo = PurchaseRepository();
      final service = CompraService(
        repo,
        GastoRepository(),
        AuthService(UsuarioRepository()),
        RegisterPayablePayment(repo),
      );
      ctrl = ComprasController(service);
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    Future<double> stockInsumo() async {
      final rows = await db.query(
        'Insumos',
        where: 'id = ?',
        whereArgs: [insumoId],
      );
      return (rows.first['stock_actual'] as num).toDouble();
    }

    test('T1: registrarCompra concurrente solo aplica una compra directa',
        () async {
      final resultados = await Future.wait([
        ctrl.registrarCompra(
          false,
          insumoId: insumoId,
          cantidadText: '2',
          costoText: '20',
          nota: 'Compra doble',
          metodoPago: 'efectivo',
        ),
        ctrl.registrarCompra(
          false,
          insumoId: insumoId,
          cantidadText: '2',
          costoText: '20',
          nota: 'Compra doble',
          metodoPago: 'efectivo',
        ),
      ]);

      expect(resultados, [true, false]);
      expect(await db.query('AjustesStock'), hasLength(1));
      expect(
        await db.query('Gastos', where: "categoria = 'Compras'"),
        hasLength(1),
      );
      expect(
        await db.query('MovimientosCaja', where: "tipo = 'compra'"),
        hasLength(1),
      );
      expect(await stockInsumo(), 2.0);
    });

    test('T2: registrarCompraPorPagar concurrente solo crea una cuenta '
        'y un adelanto', () async {
      final resultados = await Future.wait([
        ctrl.registrarCompra(
          true,
          insumoId: insumoId,
          cantidadText: '2',
          costoText: '20',
          adelanto: 5.0,
          cuotas: 2,
          proveedor: 'Proveedor Seguridad',
          metodoPago: 'efectivo',
        ),
        ctrl.registrarCompra(
          true,
          insumoId: insumoId,
          cantidadText: '2',
          costoText: '20',
          adelanto: 5.0,
          cuotas: 2,
          proveedor: 'Proveedor Seguridad',
          metodoPago: 'efectivo',
        ),
      ]);

      expect(resultados, [true, false]);
      expect(await db.query('AjustesStock'), hasLength(1));
      expect(await db.query('CuentasPorPagar'), hasLength(1));
      expect(await db.query('PagosCuentaPorPagar'), hasLength(1));
      expect(await stockInsumo(), 2.0);
    });
  });
}
