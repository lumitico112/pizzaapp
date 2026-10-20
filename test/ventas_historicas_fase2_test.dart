import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._user) : super(UsuarioRepository());

  final Usuario? _user;

  @override
  Usuario? get currentUser => _user;
}

void main() {
  late Database db;
  late VentaRepository ventaRepo;
  late CajaRepository cajaRepo;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb(seed: false);
    ventaRepo = VentaRepository();
    cajaRepo = CajaRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> abrirCajaPrueba() async {
    final now = DateTime.now().toIso8601String();
    return cajaRepo.abrirSesion(
      SesionCaja(
        fechaApertura: now,
        montoApertura: 50.0,
        transferenciasApertura: 0,
        estado: 'abierta',
      ),
      MovimientoCaja(
        sesionCajaId: 0,
        tipo: 'apertura',
        metodoPago: 'efectivo',
        monto: 50.0,
        fecha: now,
        descripcion: 'Apertura de prueba',
      ),
      userId: null,
    );
  }

  Future<int> seedProductoConReceta({
    double stockInsumo = 5.0,
    double consumoReceta = 0.5,
  }) async {
    final insumoId = await db.insert('Insumos', {
      'nombre': 'Pasta Fresca',
      'stock_actual': stockInsumo,
      'unidad_medida': 'kg',
      'costo_por_unidad': 10.0,
    });
    final catId = await db.insert('Categorias', {'nombre': 'Pastas'});
    final prodId = await db.insert('Productos', {
      'categoria_id': catId,
      'nombre': 'Lasaña Casera',
      'tipo_preparacion': 'momento',
      'activo': 1,
    });
    final varId = await db.insert('VariantesProducto', {
      'producto_id': prodId,
      'nombre_variante': 'Porción',
      'precio_venta': 20.0,
      'costo_estimado_manual': 8.0,
      'stock': 0,
      'active': 1,
    });
    await db.insert('Recetas', {
      'variante_id': varId,
      'insumo_id': insumoId,
      'cantidad': consumoReceta,
      'unidad_medida': 'kg',
    });
    return varId;
  }

  Future<int> registrarVenta(
    int varianteId, {
    required bool historica,
    required String fecha,
  }) {
    return ventaRepo.registrarVentaCompleta(
      Venta(
        fecha: fecha,
        hora: historica ? '00:00' : '12:00',
        metodoPago: 'efectivo',
        subtotal: 40.0,
        total: 40.0,
        nota: historica ? '[REGISTRO HISTÓRICO]' : null,
      ),
      [
        DetalleVenta(
          ventaId: 0,
          varianteId: varianteId,
          cantidad: 2,
          precioUnitario: 20.0,
        ),
      ],
      historica: historica,
    );
  }

  test(
    'una venta histórica se identifica y no descuenta stock ni alimenta caja',
    () async {
      final varId = await seedProductoConReceta();
      final ayer = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .split('T')
          .first;

      final ventaId = await registrarVenta(varId, historica: true, fecha: ayer);

      final venta = (await db.query(
        'Ventas',
        where: 'id = ?',
        whereArgs: [ventaId],
      )).single;
      expect(venta['es_historica'], 1);
      expect(await db.query('MovimientosCaja'), isEmpty);
      expect(await db.query('AjustesStock'), isEmpty);

      final insumo = (await db.query(
        'Insumos',
        where: 'nombre = ?',
        whereArgs: ['Pasta Fresca'],
      )).single;
      expect((insumo['stock_actual'] as num).toDouble(), 5.0);

      final detalles = await db.query(
        'DetalleVenta',
        where: 'venta_id = ?',
        whereArgs: [ventaId],
      );
      expect(detalles, hasLength(1));
    },
  );

  test('una venta normal vincula el consumo de receta con el id exacto de la venta', () async {
    await abrirCajaPrueba();
    final varId = await seedProductoConReceta();
    final hoy = DateTime.now().toIso8601String().split('T').first;

    final ventaId = await registrarVenta(varId, historica: false, fecha: hoy);

    final venta = (await db.query(
      'Ventas',
      where: 'id = ?',
      whereArgs: [ventaId],
    )).single;
    expect(venta['es_historica'], 0);

    final consumos = await db.query(
      'AjustesStock',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );
    expect(consumos, hasLength(1));
    expect(consumos.single['tipo_adquisicion'], 'consumo');
    expect(
      (consumos.single['cantidad_ajuste'] as num).toDouble(),
      closeTo(-1.0, 0.0001),
    );

    final insumo = (await db.query(
      'Insumos',
      where: 'nombre = ?',
      whereArgs: ['Pasta Fresca'],
    )).single;
    expect((insumo['stock_actual'] as num).toDouble(), 4.0);
  });

  test(
    'solo el admin puede anular una venta histórica; no toca stock ni caja',
    () async {
      final varId = await seedProductoConReceta();
      final ayer = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .split('T')
          .first;
      final ventaId = await registrarVenta(varId, historica: true, fecha: ayer);
      await db.insert('Usuarios', {
        'id': 7,
        'nombre': 'Admin de prueba',
        'username': 'admin7',
        'password_hash': 'no-usado',
        'rol': 'admin',
      });

      await expectLater(
        () => ventaRepo.anularVenta(
          ventaId: ventaId,
          motivo: 'Corrección histórica',
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              'Solo la administradora puede anular una venta histórica',
            ),
          ),
        ),
      );

      var venta = (await db.query(
        'Ventas',
        where: 'id = ?',
        whereArgs: [ventaId],
      )).single;
      expect(venta['anulada'], 0);

      await ventaRepo.anularVenta(
        ventaId: ventaId,
        motivo: 'Corrección histórica',
        esAdmin: true,
        usuarioId: 7,
      );

      venta = (await db.query(
        'Ventas',
        where: 'id = ?',
        whereArgs: [ventaId],
      )).single;
      expect(venta['anulada'], 1);
      expect(
        venta['nota'].toString(),
        contains('[ANULADA: Corrección histórica]'),
      );

      expect(await db.query('MovimientosCaja'), isEmpty);
      expect(await db.query('AjustesStock'), isEmpty);
      final insumo = (await db.query(
        'Insumos',
        where: 'nombre = ?',
        whereArgs: ['Pasta Fresca'],
      )).single;
      expect((insumo['stock_actual'] as num).toDouble(), 5.0);

      final auditoria = await db.query(
        'LogAuditoria',
        where: 'accion = ?',
        whereArgs: ['venta_historica_anulada'],
      );
      expect(auditoria, hasLength(1));
      expect(auditoria.single['usuario_id'], 7);
      expect(auditoria.single['detalle'].toString(), contains('(histórica)'));
    },
  );

  test(
    'anular una venta normal revierte solo su consumo, no el de otra venta',
    () async {
      await abrirCajaPrueba();
      final varId = await seedProductoConReceta();
      final hoy = DateTime.now().toIso8601String().split('T').first;

      final venta1 = await registrarVenta(varId, historica: false, fecha: hoy);
      final venta2 = await registrarVenta(varId, historica: false, fecha: hoy);

      var insumo = (await db.query(
        'Insumos',
        where: 'nombre = ?',
        whereArgs: ['Pasta Fresca'],
      )).single;
      expect((insumo['stock_actual'] as num).toDouble(), 3.0);

      await ventaRepo.anularVenta(
        ventaId: venta1,
        motivo: 'Error de digitación',
      );

      insumo = (await db.query(
        'Insumos',
        where: 'nombre = ?',
        whereArgs: ['Pasta Fresca'],
      )).single;
      expect((insumo['stock_actual'] as num).toDouble(), 4.0);

      final consumosVenta2 = await db.query(
        'AjustesStock',
        where: 'venta_id = ? AND tipo_adquisicion = ?',
        whereArgs: [venta2, 'consumo'],
      );
      expect(consumosVenta2, hasLength(1));
      expect(
        (consumosVenta2.single['cantidad_ajuste'] as num).toDouble(),
        closeTo(-1.0, 0.0001),
      );

      final movimientoVenta2 = await db.query(
        'MovimientosCaja',
        where: 'venta_id = ?',
        whereArgs: [venta2],
      );
      expect(movimientoVenta2.single['tipo'], 'venta');
    },
  );

  test(
    'el fallback legado revierte solo la venta exacta y no confunde #1 con #10',
    () async {
      await abrirCajaPrueba();
      final varId = await seedProductoConReceta();
      final hoy = DateTime.now().toIso8601String().split('T').first;
      final ventaId = await registrarVenta(varId, historica: false, fecha: hoy);

      // Simular datos previos a la v26: el consumo no tiene venta_id.
      await db.update(
        'AjustesStock',
        {'venta_id': null},
        where: 'venta_id = ?',
        whereArgs: [ventaId],
      );
      final insumo = (await db.query(
        'Insumos',
        where: 'nombre = ?',
        whereArgs: ['Pasta Fresca'],
      )).single;
      final insumoId = insumo['id'] as int;

      // Decoy con un id que comparte prefijo: #1 no debe capturar #10.
      await db.insert('AjustesStock', {
        'fecha': hoy,
        'insumo_id': insumoId,
        'cantidad_ajuste': -0.5,
        'tipo_adquisicion': 'consumo',
        'motivo': 'Venta #${ventaId}0, variante 999',
        'venta_id': null,
      });

      await ventaRepo.anularVenta(ventaId: ventaId, motivo: 'Dato legado');

      final insumoFinal = (await db.query(
        'Insumos',
        where: 'id = ?',
        whereArgs: [insumoId],
      )).single;
      expect((insumoFinal['stock_actual'] as num).toDouble(), 5.0);
    },
  );

  test(
    'PosService propaga el rol actual: empleado denegado, admin autorizado',
    () async {
      final varId = await seedProductoConReceta();
      final ayer = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .split('T')
          .first;
      final ventaId = await registrarVenta(varId, historica: true, fecha: ayer);
      await db.insert('Usuarios', {
        'id': 7,
        'nombre': 'Admin de prueba',
        'username': 'admin7',
        'password_hash': 'no-usado',
        'rol': 'admin',
      });

      final posEmpleado = PosService(
        ProductoRepository(),
        ventaRepo,
        cajaRepo,
        PromocionRepository(),
        authService: _FakeAuthService(
          Usuario(
            id: 8,
            nombre: 'Empleado',
            username: 'empleado8',
            passwordHash: 'no-usado',
            rol: 'empleado',
          ),
        ),
      );
      await expectLater(
        () => posEmpleado.anularVenta(
          ventaId: ventaId,
          motivo: 'Intento de empleado',
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              'Solo la administradora puede anular una venta histórica',
            ),
          ),
        ),
      );

      final posAdmin = PosService(
        ProductoRepository(),
        ventaRepo,
        cajaRepo,
        PromocionRepository(),
        authService: _FakeAuthService(
          Usuario(
            id: 7,
            nombre: 'Admin',
            username: 'admin7',
            passwordHash: 'no-usado',
            rol: 'admin',
          ),
        ),
      );
      await posAdmin.anularVenta(
        ventaId: ventaId,
        motivo: 'Corrección autorizada',
      );

      final venta = (await db.query(
        'Ventas',
        where: 'id = ?',
        whereArgs: [ventaId],
      )).single;
      expect(venta['anulada'], 1);

      final auditoria = await db.query(
        'LogAuditoria',
        where: 'accion = ?',
        whereArgs: ['venta_historica_anulada'],
      );
      expect(auditoria, hasLength(1));
      expect(auditoria.single['usuario_id'], 7);
    },
  );
}
