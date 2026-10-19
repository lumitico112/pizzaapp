import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';
import 'package:pizzaapp/features/preparation/data/repositories/preparacion_repository.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

void main() {
  group('Fase 1/2 — Cuadre de Caja (C-11)', () {
    test('CashCloseSummary calcula efectivo, transferencias, gastos y diferencias', () {
      final sesion = SesionCaja(
        id: 1,
        fechaApertura: '2026-10-16T18:00:00',
        montoApertura: 100.0,
        transferenciasApertura: 0.0,
      );
      final movimientos = [
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'apertura',
          metodoPago: 'efectivo',
          monto: 100.0,
          fecha: '2026-10-16T18:00:00',
        ),
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'venta',
          metodoPago: 'efectivo',
          monto: 50.0,
          fecha: '2026-10-16T19:00:00',
        ),
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'venta',
          metodoPago: 'yape/plin',
          monto: 35.0,
          fecha: '2026-10-16T19:30:00',
        ),
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'salida',
          metodoPago: 'efectivo',
          monto: 20.0,
          fecha: '2026-10-16T20:00:00',
        ),
      ];

      final summary = CashCloseSummary.calculate(
        sesion,
        movimientos,
        gastosDelCiclo: 20.0,
      );

      expect(summary.efectivoEsperado, 130.0);
      expect(summary.transferenciasEsperadas, 35.0);
      expect(summary.ventasEfectivo, 50.0);
      expect(summary.ventasTransferencias, 35.0);
      expect(summary.gastos, 20.0);
      expect(summary.diferencia(efectivo: 130.0, transferencias: 35.0), 0.0);
      expect(summary.diferencia(efectivo: 125.0, transferencias: 35.0), -5.0);
      expect(summary.diferencia(efectivo: 140.0, transferencias: 35.0), 10.0);
    });
  });

  group('Fase 2 — Integridad en Compras, Cuentas por Pagar y Gastos (C-01, C-02 / RN-01, RN-02)', () {
    late Database db;
    late PurchaseRepository repo;
    late int insumoId;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      repo = PurchaseRepository();
      insumoId = await db.insert('Insumos', {
        'nombre': 'Mozzarella',
        'tipo_insumo': 'Quesos',
        'unidad_medida': 'Kg',
        'stock_actual': 10.0,
        'stock_minimo': 2.0,
        'costo_por_unidad': 20.0,
      });
      await db.insert('SesionesCaja', {
        'fecha_apertura': DateTime.now().toIso8601String(),
        'monto_apertura': 200.0,
        'estado': 'abierta',
      });
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    test('registrarCompra al contado incrementa stock, registra gasto y movimiento de caja', () async {
      await repo.registrarCompra(
        insumoId: insumoId,
        cantidad: 5.0,
        costoTotal: 100.0,
        motivo: 'Compra Mozzarella',
        metodoPago: 'efectivo',
      );

      final insumos = await db.query('Insumos', where: 'id = ?', whereArgs: [insumoId]);
      expect((insumos.first['stock_actual'] as num).toDouble(), 15.0);

      final gastos = await db.query('Gastos');
      expect(gastos.length, 1);
      expect((gastos.first['monto'] as num).toDouble(), 100.0);

      final movs = await db.query('MovimientosCaja', where: "tipo = 'compra'");
      expect(movs.length, 1);
      expect((movs.first['monto'] as num).toDouble(), 100.0);
    });

    test('C-01 / RN-01: corregirCompra preserva abonos posteriores, no duplica adelanto y bloquea total < monto_pagado', () async {
      await repo.registrarCompraPorPagar(
        insumoId: insumoId,
        cantidad: 10.0,
        costoTotal: 200.0,
        adelanto: 50.0,
        proveedor: 'Lácteos Sur',
        factura: 'F001-10',
        metodoPago: 'efectivo',
      );

      final cxpBefore = await db.query('CuentasPorPagar');
      final cuentaId = cxpBefore.first['id'] as int;
      final movId = cxpBefore.first['compra_movimiento_id'] as int;

      // Se registran dos abonos posteriores de S/ 30 cada uno (Total pagado = 50 + 30 + 30 = 110)
      await repo.aplicarPago(cuentaId, 30.0, metodoPago: 'efectivo', nota: 'Abono 1');
      await repo.aplicarPago(cuentaId, 30.0, metodoPago: 'efectivo', nota: 'Abono 2');

      // 1. Intentar bajar el costoTotal a 100 (menor a los S/ 110 ya pagados) debe fallar:
      await expectLater(
        repo.corregirCompra(
          movimientoId: movId,
          cantidad: 10.0,
          costoTotal: 100.0,
          esPorPagar: true,
          adelanto: 50.0,
          motivo: 'F001-10 inválida',
        ),
        throwsA(isA<Exception>()),
      );

      // 2. Corregir el costoTotal a 220 y subir el adelanto inicial de 50 a 60:
      // Nuevo monto_pagado debe ser 60 (adelanto actualizado) + 60 (abonos posteriores) = 120.0
      await repo.corregirCompra(
        movimientoId: movId,
        cantidad: 10.0,
        costoTotal: 220.0,
        esPorPagar: true,
        adelanto: 60.0,
        motivo: 'F001-10 corregida',
      );

      final cxpAfter = await db.query('CuentasPorPagar', where: 'id = ?', whereArgs: [cuentaId]);
      expect((cxpAfter.first['costo_total'] as num).toDouble(), 220.0);
      expect((cxpAfter.first['adelanto'] as num).toDouble(), 60.0);
      expect((cxpAfter.first['monto_pagado'] as num).toDouble(), 120.0);

      // Verificar que NO se duplicaron gastos ni movimientos de caja (1 adelanto + 2 abonos = 3):
      final gastos = await db.query('Gastos');
      final movsCaja = await db.query('MovimientosCaja');
      expect(gastos.length, 3);
      expect(movsCaja.length, 3);
    });

    test('C-02 / RN-02: eliminarGasto bloquea gastos de compras o CxP, y anularPagoCuentaPorPagar revierte por ID exacto', () async {
      await repo.registrarCompraPorPagar(
        insumoId: insumoId,
        cantidad: 5.0,
        costoTotal: 100.0,
        adelanto: 0.0,
        factura: 'F001-20',
      );
      final cuentaId = (await db.query('CuentasPorPagar')).first['id'] as int;

      await repo.aplicarPago(cuentaId, 40.0, metodoPago: 'efectivo', nota: 'Cuota 1');

      final gastos = await db.query('Gastos');
      expect(gastos.length, 1);
      final gastoId = gastos.first['id'] as int;

      // 1. Intentar eliminar directamente desde la bandeja genérica de Gastos debe bloquearse (RN-02):
      await expectLater(
        repo.eliminarGasto(gastoId),
        throwsA(isA<Exception>()),
      );

      // 2. Anular el abono desde Cuentas por Pagar (anularPagoCuentaPorPagar) revierte deuda, gasto y movimiento por ID:
      final pagos = await repo.getPaymentHistory(cuentaId);
      expect(pagos.length, 1);
      final pagoId = pagos.first['id'] as int;

      await repo.anularPagoCuentaPorPagar(pagoId);

      final cxpAfter = await db.query('CuentasPorPagar', where: 'id = ?', whereArgs: [cuentaId]);
      expect((cxpAfter.first['monto_pagado'] as num).toDouble(), 0.0);
      expect((cxpAfter.first['pagado'] as num).toInt(), 0);
      expect(await db.query('Gastos'), isEmpty);
      expect(await db.query('MovimientosCaja'), isEmpty);
    });
  });

  group('Fase 2 — Integridad en Preparación, Sobrantes y Traslados (C-03, C-04, C-10 / RN-03)', () {
    late Database db;
    late PreparacionRepository prepRepo;
    late int varianteId;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      prepRepo = PreparacionRepository();

      await db.insert('SesionesCaja', {
        'fecha_apertura': DateTime.now().toIso8601String(),
        'monto_apertura': 100.0,
        'estado': 'abierta',
      });

      final catProdId = await db.insert('Categorias', {'nombre': 'Pizzas'});
      final prodId = await db.insert('Productos', {
        'nombre': 'Pizza Americana',
        'categoria_id': catProdId,
        'tipo_preparacion': 'anticipado',
      });
      varianteId = await db.insert('VariantesProducto', {
        'producto_id': prodId,
        'nombre_variante': 'Familiar',
        'precio_venta': 35.0,
        'stock': 3,
      });
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    test('C-03 y C-10 / RN-03: procesarSobrantesPendientes rechaza waste > stock y actualiza ItemsPreparacion.sobrante', () async {
      final prepId = await db.insert('PreparacionDiaria', {
        'fecha': '2026-10-15',
        'nota': 'Ayer',
      });
      final itemId = await db.insert('ItemsPreparacion', {
        'preparacion_id': prepId,
        'variante_id': varianteId,
        'cantidad_preparada': 5,
        'enviado_merma': 0,
        'llevado_manana': 0,
        'sobrante': 0,
        'resuelto': 0,
      });

      // 1. El stock actual preparado es 3; intentar mandar 4 a merma debe rechazarse (RN-03):
      await expectLater(
        prepRepo.procesarSobrantesPendientes(
          sobrantesAPreparacion: {},
          sobrantesAMerma: {itemId: 4},
          itemIdsResueltos: [itemId],
        ),
        throwsA(isA<Exception>()),
      );

      // 2. Procesar 1 para mañana y 2 a merma (suma 3 <= stock 3 y <= preparado 5):
      await prepRepo.procesarSobrantesPendientes(
        sobrantesAPreparacion: {itemId: 1},
        sobrantesAMerma: {itemId: 2},
        itemIdsResueltos: [itemId],
      );

      final mermas = await db.query('Merma');
      final items = await db.query('ItemsPreparacion', where: 'id = ?', whereArgs: [itemId]);
      final variantes = await db.query('VariantesProducto', where: 'id = ?', whereArgs: [varianteId]);

      expect((mermas.first['cantidad'] as num).toDouble(), 2.0);
      expect((variantes.first['stock'] as num).toInt(), 1); // 3 - 2 de merma = 1
      expect((items.first['enviado_merma'] as num).toInt(), 2);
      expect((items.first['llevado_manana'] as num).toInt(), 1);
      // Columna sobrante alimentada con enviado_merma + llevado_manana = 3 (C-10 / RN-03):
      expect((items.first['sobrante'] as num).toInt(), 3);
    });

    test('C-04 / RN-03: llevarParaManana hace UPSERT en el día siguiente y actualiza sobrante', () async {
      final prepId = await db.insert('PreparacionDiaria', {
        'fecha': '2026-10-15',
        'nota': 'Ayer',
      });
      final itemId = await db.insert('ItemsPreparacion', {
        'preparacion_id': prepId,
        'variante_id': varianteId,
        'cantidad_preparada': 6,
        'enviado_merma': 0,
        'llevado_manana': 0,
      });

      await prepRepo.llevarParaManana(itemId, 2);
      await prepRepo.llevarParaManana(itemId, 1);

      final nextPrep = await db.query(
        'PreparacionDiaria',
        where: 'fecha = ?',
        whereArgs: ['2026-10-16'],
      );
      final nextItems = await db.query(
        'ItemsPreparacion',
        where: 'preparacion_id = ? AND variante_id = ?',
        whereArgs: [nextPrep.first['id'], varianteId],
      );

      // Debe existir 1 única fila para la variante con cantidad acumulada 2 + 1 = 3:
      expect(nextItems.length, 1);
      expect((nextItems.first['cantidad_preparada'] as num).toInt(), 3);

      final originItem = await db.query('ItemsPreparacion', where: 'id = ?', whereArgs: [itemId]);
      expect((originItem.first['llevado_manana'] as num).toInt(), 3);
      expect((originItem.first['sobrante'] as num).toInt(), 3);
    });
  });

  group('Fase 2 — Autenticación y Bloqueo Efectivo de Usuarios (C-05 / RN-10)', () {
    late Database db;
    late UsuarioRepository userRepo;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
      userRepo = UsuarioRepository();

      await userRepo.createUsuario(
        Usuario(
          nombre: 'Cajero Bloqueado',
          username: 'cajero_bloq',
          passwordHash: HashUtils.hashPassword('Clave1234'),
          rol: 'empleado',
          activo: 1,
          bloqueado: 1,
        ),
      );
      await userRepo.createUsuario(
        Usuario(
          nombre: 'Cajero Activo',
          username: 'cajero_ok',
          passwordHash: HashUtils.hashPassword('Clave1234'),
          rol: 'empleado',
          activo: 1,
          bloqueado: 0,
        ),
      );
      await userRepo.createUsuario(
        Usuario(
          nombre: 'Admin Bloqueado',
          username: 'admin_bloq',
          passwordHash: HashUtils.hashPassword('Admin1234'),
          rol: 'admin',
          activo: 1,
          bloqueado: 1,
        ),
      );
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    test('C-05 / RN-10: authenticate rechaza usuarios con bloqueado=1 y permite usuarios activos no bloqueados', () async {
      final activeAdmin = await userRepo.findActiveAdmin('admin_bloq');
      expect(activeAdmin, isNull);

      final blockedEmployee = await userRepo.authenticate('cajero_bloq', 'Clave1234');
      expect(blockedEmployee, isNull);

      final blockedAdmin = await userRepo.authenticate('admin_bloq', 'Admin1234');
      expect(blockedAdmin, isNull);

      final validEmployee = await userRepo.authenticate('cajero_ok', 'Clave1234');
      expect(validEmployee, isNotNull);
      expect(validEmployee!.username, 'cajero_ok');
    });
  });
}
