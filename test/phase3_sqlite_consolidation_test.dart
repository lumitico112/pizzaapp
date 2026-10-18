import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/database/db_schema.dart';
import 'package:pizzaapp/features/assets/application/asset_service.dart';
import 'package:pizzaapp/features/assets/data/repositories/asset_repository.dart';
import 'package:pizzaapp/features/assets/domain/entities/asset.dart';
import 'package:pizzaapp/features/cash/domain/entities/cash_close_summary.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb(seed: true);
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  group('Fase 3 — Consolidación SQLite v23, Foreign Keys e Índices (C-06 a C-09, C-12, C-13)', () {
    test('Esquema v23 activa PRAGMA foreign_keys = ON, crea 23 índices IDX_* y 4 triggers', () async {
      expect(DatabaseHelper.databaseVersion, 23);

      final fkStatus = await db.rawQuery('PRAGMA foreign_keys');
      expect(fkStatus.first['foreign_keys'], 1);

      final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
      expect(fkViolations, isEmpty);

      final indexRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'IDX_%'",
      );
      expect(indexRows.length, 23);
      expect(DbSchema.indexes.length, 23);

      final triggerRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'trigger'",
      );
      expect(triggerRows.length, 4);

      // Verificar que una clave foránea inválida es rechazada en tiempo real
      await expectLater(
        () => db.insert('AjustesStock', {
          'fecha': '2026-10-16T10:00:00',
          'insumo_id': 999999,
          'cantidad_ajuste': 5.0,
          'tipo_adquisicion': 'comprado',
          'costo_unitario': 10.0,
          'motivo': 'FK inválida',
        }),
        throwsA(anything),
      );
    });

    test('Migración v22 -> v23 convierte CuentasPorPagar.insumo_id = 0 a NULL, limpia huérfanos y pasa foreign_key_check', () async {
      // Simular estado legado v22 con foreign_keys = OFF y CuentasPorPagar.insumo_id NOT NULL
      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('DROP TRIGGER IF EXISTS validar_cuenta_por_pagar_insert');
      await db.execute('DROP TRIGGER IF EXISTS validar_cuenta_por_pagar_update');
      await db.execute('DROP TABLE PagosCuentaPorPagar');
      await db.execute('DROP TABLE CuentasPorPagar');
      await db.execute('''
        CREATE TABLE CuentasPorPagar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          insumo_id INTEGER NOT NULL,
          cantidad REAL NOT NULL,
          costo_total REAL NOT NULL,
          proveedor TEXT,
          proveedor_id INTEGER REFERENCES Proveedores(id),
          factura_ruta TEXT,
          motivo TEXT,
          pagado INTEGER DEFAULT 0,
          monto_pagado REAL NOT NULL DEFAULT 0,
          fecha_pago TEXT,
          usuario_id INTEGER,
          cuotas INTEGER DEFAULT 1,
          adelanto REAL DEFAULT 0,
          activo_fijo_id INTEGER REFERENCES ActivosFijos(id),
          fecha_vencimiento TEXT,
          compra_movimiento_id INTEGER REFERENCES AjustesStock(id)
        )
      ''');
      await db.execute(DbSchema.createPagosCuentaPorPagar);

      final activoId = await db.insert('ActivosFijos', {
        'nombre': 'Horno Industrial',
        'categoria': 'Maquinaria',
        'costo': 2500.0,
        'fecha_adquisicion': '2026-10-15',
        'estado': 'En uso',
        'condicion': 'Comprado',
        'metodo_pago': 'Crédito',
        'cuotas': 5,
        'cantidad': 1,
      });

      // Fila legada con centinela insumo_id = 0 y usuario_id huérfano = 777
      final cxpId = await db.insert('CuentasPorPagar', {
        'fecha': '2026-10-15',
        'insumo_id': 0,
        'cantidad': 1.0,
        'costo_total': 2500.0,
        'monto_pagado': 500.0,
        'adelanto': 500.0,
        'cuotas': 5,
        'activo_fijo_id': activoId,
        'usuario_id': 777,
        'motivo': 'Activo: Horno Industrial',
      });

      // Gasto con usuario_id huérfano = 888
      final gastoId = await db.insert('Gastos', {
        'fecha': '2026-10-15',
        'created_at': '2026-10-15T10:00:00',
        'categoria': 'Servicios',
        'descripcion': 'Luz',
        'monto': 120.0,
        'usuario_id': 888,
      });

      // DetalleVenta huérfano apuntando a venta_id inexistente = 999
      await db.insert('DetalleVenta', {
        'venta_id': 999,
        'variante_id': null,
        'es_cortesia': 0,
        'cantidad': 1,
        'precio_unitario': 25.0,
      });

      // Ejecutar migración v22 -> v23 y reactivar foreign_keys
      await DatabaseHelper.instance.upgradeDatabase(
        db,
        22,
        23,
        runSeeder: true,
      );
      await db.execute('PRAGMA foreign_keys = ON');

      final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
      expect(fkViolations, isEmpty);

      final cxpRows = await db.query(
        'CuentasPorPagar',
        where: 'id = ?',
        whereArgs: [cxpId],
      );
      expect(cxpRows.length, 1);
      expect(cxpRows.first['insumo_id'], isNull);
      expect(cxpRows.first['activo_fijo_id'], activoId);
      expect(cxpRows.first['usuario_id'], isNull);

      final gastoRows = await db.query(
        'Gastos',
        where: 'id = ?',
        whereArgs: [gastoId],
      );
      expect(gastoRows.length, 1);
      expect(gastoRows.first['usuario_id'], isNull);

      final orphanDetails = await db.query(
        'DetalleVenta',
        where: 'venta_id = ?',
        whereArgs: [999],
      );
      expect(orphanDetails, isEmpty);
    });

    test('C-09: ActivoFijoService.registrarActivo a crédito funciona con PRAGMA foreign_keys = ON e insumo_id NULL', () async {
      await db.insert('SesionesCaja', {
        'fecha_apertura': DateTime.now().toIso8601String(),
        'monto_apertura': 100.0,
        'transferencias_apertura': 0.0,
        'estado': 'abierta',
      });
      final service = ActivoFijoService(
        ActivoFijoRepository(),
        AuthService(UsuarioRepository()),
      );

      await service.registrarActivo(
        ActivoFijo(
          nombre: 'Amasadora 20L',
          categoria: 'Maquinaria',
          costo: 1800.0,
          fechaAdquisicion: DateTime.now().toIso8601String().split('T').first,
          estado: 'En uso',
          condicion: 'Comprado',
          metodoPago: 'Crédito',
          cuotas: 3,
          cantidad: 1,
        ),
        300.0,
      );

      final cxpRows = await db.query('CuentasPorPagar');
      expect(cxpRows.length, 1);
      expect(cxpRows.first['insumo_id'], isNull);
      expect(cxpRows.first['activo_fijo_id'], isNotNull);
      expect((cxpRows.first['costo_total'] as num).toDouble(), 1800.0);
      expect((cxpRows.first['monto_pagado'] as num).toDouble(), 300.0);

      final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
      expect(fkViolations, isEmpty);
    });

    test('C-11: CashCloseSummary unifica entradas/salidas por canal e incluye tarjeta en digital', () {
      final sesion = SesionCaja(
        id: 1,
        fechaApertura: '2026-10-16T08:00:00',
        montoApertura: 100.0,
        transferenciasApertura: 50.0,
        estado: 'abierta',
      );
      final movimientos = [
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'venta',
          metodoPago: 'efectivo',
          monto: 80.0,
          fecha: '2026-10-16T09:00:00',
        ),
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'entrada',
          metodoPago: 'efectivo',
          monto: 20.0,
          fecha: '2026-10-16T09:15:00',
        ),
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'venta',
          metodoPago: 'tarjeta',
          monto: 60.0,
          fecha: '2026-10-16T09:30:00',
        ),
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'salida',
          metodoPago: 'efectivo',
          monto: 15.0,
          fecha: '2026-10-16T10:00:00',
        ),
        MovimientoCaja(
          sesionCajaId: 1,
          tipo: 'compra',
          metodoPago: 'yape',
          monto: 25.0,
          fecha: '2026-10-16T10:30:00',
        ),
      ];

      final summary = CashCloseSummary.calculate(sesion, movimientos);
      expect(summary.ventasEfectivo, 80.0);
      expect(summary.entradasEfectivo, 100.0);
      expect(summary.salidasEfectivo, 15.0);
      expect(summary.efectivoEsperado, 185.0); // 100 + 100 - 15

      expect(summary.ventasTransferencias, 60.0);
      expect(summary.entradasTransferencias, 60.0);
      expect(summary.salidasTransferencias, 25.0);
      expect(summary.transferenciasEsperadas, 85.0); // 50 + 60 - 25
      expect(summary.gastos, 40.0); // 15 + 25
    });
  });
}
