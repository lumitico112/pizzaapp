import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

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

  Future<int> abrirCajaPrueba({
    double aperturaEfectivo = 50.0,
    double aperturaDigital = 0.0,
  }) async {
    final now = DateTime.now().toIso8601String();
    return cajaRepo.abrirSesion(
      SesionCaja(
        fechaApertura: now,
        montoApertura: aperturaEfectivo,
        transferenciasApertura: aperturaDigital,
        estado: 'abierta',
      ),
      MovimientoCaja(
        sesionCajaId: 0,
        tipo: 'apertura',
        metodoPago: 'efectivo',
        monto: aperturaEfectivo,
        fecha: now,
        descripcion: 'Apertura de prueba',
      ),
      userId: null,
    );
  }

  Future<int> seedProductoAnticipado({
    required String nombre,
    required int stockInicial,
    required double precio,
  }) async {
    final catId = await db.insert('Categorias', {'nombre': 'Pizzas'});
    final prodId = await db.insert('Productos', {
      'categoria_id': catId,
      'nombre': nombre,
      'tipo_preparacion': 'anticipado',
      'activo': 1,
    });
    return db.insert('VariantesProducto', {
      'producto_id': prodId,
      'nombre_variante': 'Familiar',
      'precio_venta': precio,
      'costo_estimado_manual': 10.0,
      'stock': stockInicial,
      'active': 1,
    });
  }

  Future<int> seedProductoMomentoConReceta({
    required String nombreInsumo,
    required double stockInsumo,
    required double consumoReceta,
  }) async {
    final insumoId = await db.insert('Insumos', {
      'nombre': nombreInsumo,
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

  test(
    'Cambiar método de pago: actualiza Ventas, MovimientosCaja y recalcula el arqueo de caja',
    () async {
      await abrirCajaPrueba(aperturaEfectivo: 100.0);
      final varId = await seedProductoAnticipado(
        nombre: 'Pizza Suprema',
        stockInicial: 5,
        precio: 30.0,
      );

      // Registrar venta en Efectivo por S/. 30
      final now = DateTime.now();
      final ventaId = await ventaRepo.registrarVentaCompleta(
        Venta(
          fecha: now.toIso8601String().split('T').first,
          hora: '12:00',
          metodoPago: 'efectivo',
          subtotal: 30.0,
          total: 30.0,
        ),
        [
          DetalleVenta(
            ventaId: 0,
            varianteId: varId,
            cantidad: 1,
            precioUnitario: 30.0,
          ),
        ],
      );

      // Verificar arqueo inicial: Efectivo = 100 apertura + 30 venta = 130; Yape = 0
      var sesion = (await cajaRepo.getSesionActiva())!;
      var resumen = await cajaRepo.resumenSesion(sesion);
      expect(resumen.efectivoEsperado, 130.0);
      expect(resumen.transferenciasEsperadas, 0.0);

      // Cambiar método de pago a Yape
      await ventaRepo.actualizarMetodoPagoVenta(
        ventaId: ventaId,
        nuevoMetodo: 'yape',
        usuarioId: null,
      );

      // En base de datos Ventas y MovimientosCaja deben ser 'yape'
      final vRow = await db.query('Ventas', where: 'id = ?', whereArgs: [ventaId]);
      expect(vRow.first['metodo_pago'], 'yape');

      final mRow = await db.query('MovimientosCaja', where: 'venta_id = ?', whereArgs: [ventaId]);
      expect(mRow.first['metodo_pago'], 'yape');

      // Arqueo recalculado: Efectivo = 100 (solo apertura); Yape = 30
      resumen = await cajaRepo.resumenSesion(sesion);
      expect(resumen.efectivoEsperado, 100.0);
      expect(resumen.transferenciasEsperadas, 30.0);
    },
  );

  test(
    'Anular venta de producto preparado (anticipado): devuelve stock, excluye de caja y marca anulada',
    () async {
      await abrirCajaPrueba(aperturaEfectivo: 50.0);
      final varId = await seedProductoAnticipado(
        nombre: 'Pizza Americana',
        stockInicial: 4,
        precio: 25.0,
      );

      // Venta de 2 pizzas -> stock baja a 2
      final now = DateTime.now();
      final ventaId = await ventaRepo.registrarVentaCompleta(
        Venta(
          fecha: now.toIso8601String().split('T').first,
          hora: '14:30',
          metodoPago: 'efectivo',
          subtotal: 50.0,
          total: 50.0,
        ),
        [
          DetalleVenta(
            ventaId: 0,
            varianteId: varId,
            cantidad: 2,
            precioUnitario: 25.0,
          ),
        ],
      );

      var varRow = await db.query('VariantesProducto', where: 'id = ?', whereArgs: [varId]);
      expect(varRow.first['stock'], 2);

      // Arqueo: 50 apertura + 50 venta = 100
      var sesion = (await cajaRepo.getSesionActiva())!;
      var resumen = await cajaRepo.resumenSesion(sesion);
      expect(resumen.efectivoEsperado, 100.0);

      // Anular la venta
      await ventaRepo.anularVenta(
        ventaId: ventaId,
        motivo: 'Cliente canceló antes de entrega',
        usuarioId: null,
      );

      // 1. Stock preparado se devuelve intacto a 4
      varRow = await db.query('VariantesProducto', where: 'id = ?', whereArgs: [varId]);
      expect(varRow.first['stock'], 4);

      // 2. Venta marcada como anulada = 1 y nota actualizada
      final vRow = await db.query('Ventas', where: 'id = ?', whereArgs: [ventaId]);
      expect(vRow.first['anulada'], 1);
      expect(vRow.first['nota'].toString(), contains('[ANULADA: Cliente canceló antes de entrega]'));

      // 3. Movimiento de caja marcado como 'venta_anulada'
      final mRow = await db.query('MovimientosCaja', where: 'venta_id = ?', whereArgs: [ventaId]);
      expect(mRow.first['tipo'], 'venta_anulada');

      // 4. Arqueo de caja excluye la venta anulada: Efectivo vuelve a 50 (solo apertura)
      resumen = await cajaRepo.resumenSesion(sesion);
      expect(resumen.efectivoEsperado, 50.0);

      // 5. Historial devuelve la venta con anulada = 1
      final hist = await ventaRepo.getHistorialVentas();
      expect(hist.length, 1);
      expect(hist.first['anulada'], 1);
    },
  );

  test(
    'Anular venta de producto al momento: devuelve los insumos de receta consumidos',
    () async {
      await abrirCajaPrueba(aperturaEfectivo: 50.0);
      final varId = await seedProductoMomentoConReceta(
        nombreInsumo: 'Pasta Fresca',
        stockInsumo: 5.0,
        consumoReceta: 0.5,
      );

      // Venta de 2 porciones -> descuenta 2 * 0.5 = 1.0 kg -> stock insumo queda en 4.0 kg
      final now = DateTime.now();
      final ventaId = await ventaRepo.registrarVentaCompleta(
        Venta(
          fecha: now.toIso8601String().split('T').first,
          hora: '15:00',
          metodoPago: 'yape',
          subtotal: 40.0,
          total: 40.0,
        ),
        [
          DetalleVenta(
            ventaId: 0,
            varianteId: varId,
            cantidad: 2,
            precioUnitario: 20.0,
          ),
        ],
      );

      var insumoRow = await db.query('Insumos', where: 'nombre = ?', whereArgs: ['Pasta Fresca']);
      expect((insumoRow.first['stock_actual'] as num).toDouble(), 4.0);

      // Anular la venta
      await ventaRepo.anularVenta(
        ventaId: ventaId,
        motivo: 'Error de digitación del cajero',
        usuarioId: null,
      );

      // El stock del insumo debe regresar a 5.0 kg
      insumoRow = await db.query('Insumos', where: 'nombre = ?', whereArgs: ['Pasta Fresca']);
      expect((insumoRow.first['stock_actual'] as num).toDouble(), 5.0);

      // Registro de ajuste de reversión de consumo
      final ajustes = await db.query(
        'AjustesStock',
        where: "tipo_adquisicion = 'reversion_consumo'",
      );
      expect(ajustes.length, 1);
      expect((ajustes.first['cantidad_ajuste'] as num).toDouble(), 1.0);
    },
  );

  test(
    'Protección financiera: rechaza anular o editar una venta si la sesión de caja ya fue cerrada',
    () async {
      final sesionId = await abrirCajaPrueba(aperturaEfectivo: 50.0);
      final varId = await seedProductoAnticipado(
        nombre: 'Pizza Pepperoni',
        stockInicial: 3,
        precio: 28.0,
      );

      final now = DateTime.now();
      final ventaId = await ventaRepo.registrarVentaCompleta(
        Venta(
          fecha: now.toIso8601String().split('T').first,
          hora: '18:00',
          metodoPago: 'efectivo',
          subtotal: 28.0,
          total: 28.0,
        ),
        [
          DetalleVenta(
            ventaId: 0,
            varianteId: varId,
            cantidad: 1,
            precioUnitario: 28.0,
          ),
        ],
      );

      // Cerrar la sesión de caja
      await cajaRepo.cerrarSesion(
        sesionId: sesionId,
        efectivoContado: 78.0,
        transferenciasContadas: 0.0,
        nota: 'Cierre turno noche',
        usuarioId: null,
      );

      // Intentar anular la venta de una caja cerrada debe lanzar excepción
      await expectLater(
        () => ventaRepo.anularVenta(
          ventaId: ventaId,
          motivo: 'Intento de anulación extemporáneo',
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains('ya fue cerrada'),
          ),
        ),
      );

      // Intentar cambiar método de pago también debe ser rechazado
      await expectLater(
        () => ventaRepo.actualizarMetodoPagoVenta(
          ventaId: ventaId,
          nuevoMetodo: 'tarjeta',
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains('ya cerrada'),
          ),
        ),
      );
    },
  );
}
