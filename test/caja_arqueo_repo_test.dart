import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase 7 (H-04b): caracterización de los métodos de arqueo movidos de
/// `CajaService` a `CajaRepository` (`getNombreUsuario`, `getItemsPorVenta`)
/// sobre un escenario fijo con números escritos a mano.
void main() {
  late Database db;
  late CajaRepository cajaRepo;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
    cajaRepo = CajaRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  test(
    'F7 H-04b: escenario fijo (apertura 100+50, ventas 20 efectivo + 10 Yape, '
    'salida 15) caracteriza getNombreUsuario, getItemsPorVenta y el arqueo',
    () async {
      // Usuario responsable del turno.
      final cajeroId = await db.insert('Usuarios', {
        'nombre': 'Cajera F7',
        'username': 'cajera_f7',
        'password_hash': HashUtils.hashPassword('ClaveF7Pass', iterations: 1000),
        'rol': 'empleado',
        'activo': 1,
        'bloqueado': 0,
      });

      // Producto y variante para las ventas.
      final prodRepo = ProductoRepository();
      final catId = await prodRepo.insertCategoria(
        Categoria(nombre: 'F7 Caja'),
      );
      await prodRepo.guardarProductoCompleto(
        Producto(
          categoriaId: catId,
          nombre: 'PIZZA F7 ARQUEO',
          tipoPreparacion: 'anticipado',
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
      final variante =
          (await prodRepo.getVariantesPorProducto(producto.id!)).first;

      // Apertura: S/ 100.00 en efectivo + S/ 50.00 digital.
      const fechaApertura = '2026-10-18T09:00:00.000';
      final sesionId = await cajaRepo.abrirSesion(
        SesionCaja(
          fechaApertura: fechaApertura,
          montoApertura: 100.0,
          transferenciasApertura: 50.0,
          usuarioAperturaId: cajeroId,
        ),
        MovimientoCaja(
          sesionCajaId: 0,
          tipo: 'apertura',
          metodoPago: 'efectivo',
          monto: 100.0,
          descripcion: 'Apertura de caja',
          fecha: fechaApertura,
        ),
        userId: cajeroId,
      );

      // Venta #1: 2 x 10.00 = 20.00 en efectivo.
      final ventaEfectivoId = await db.insert(
        'Ventas',
        Venta(
          fecha: '2026-10-18',
          hora: '10:00',
          subtotal: 20.0,
          total: 20.0,
          metodoPago: 'efectivo',
        ).toMap(),
      );
      await db.insert(
        'DetalleVenta',
        DetalleVenta(
          ventaId: ventaEfectivoId,
          varianteId: variante.id,
          cantidad: 2,
          precioUnitario: 10.0,
        ).toMap(),
      );
      await db.insert(
        'MovimientosCaja',
        MovimientoCaja(
          sesionCajaId: sesionId,
          tipo: 'venta',
          metodoPago: 'efectivo',
          monto: 20.0,
          descripcion: 'Venta #$ventaEfectivoId',
          fecha: '2026-10-18T10:00:00.000',
        ).toMap(),
      );

      // Venta #2: 1 x 10.00 = 10.00 por Yape.
      final ventaYapeId = await db.insert(
        'Ventas',
        Venta(
          fecha: '2026-10-18',
          hora: '11:00',
          subtotal: 10.0,
          total: 10.0,
          metodoPago: 'yape',
        ).toMap(),
      );
      await db.insert(
        'DetalleVenta',
        DetalleVenta(
          ventaId: ventaYapeId,
          varianteId: variante.id,
          cantidad: 1,
          precioUnitario: 10.0,
        ).toMap(),
      );
      await db.insert(
        'MovimientosCaja',
        MovimientoCaja(
          sesionCajaId: sesionId,
          tipo: 'venta',
          metodoPago: 'yape',
          monto: 10.0,
          descripcion: 'Venta #$ventaYapeId',
          fecha: '2026-10-18T11:00:00.000',
        ).toMap(),
      );

      // Gasto del ciclo: salida manual de S/ 15.00 en efectivo.
      await cajaRepo.registrarMovimientoManual(
        MovimientoCaja(
          sesionCajaId: sesionId,
          tipo: 'salida',
          metodoPago: 'efectivo',
          monto: 15.0,
          descripcion: 'Servilletas',
          fecha: '2026-10-18T12:00:00.000',
        ),
        userId: cajeroId,
      );

      // getNombreUsuario: nombre existente y usuario inexistente.
      expect(await cajaRepo.getNombreUsuario(cajeroId), 'Cajera F7');
      expect(await cajaRepo.getNombreUsuario(999999), isNull);

      // getItemsPorVenta: una entrada por venta, con la variante entre
      // paréntesis cuando difiere del nombre del producto.
      expect(await cajaRepo.getItemsPorVenta(sesionId), {
        ventaEfectivoId: '2x PIZZA F7 ARQUEO (Unica)',
        ventaYapeId: '1x PIZZA F7 ARQUEO (Unica)',
      });

      // Resumen del arqueo (mismos números a mano, vía repositorio).
      final sesion = (await cajaRepo.getSesionActiva())!;
      final summary = await cajaRepo.resumenSesion(sesion);
      expect(summary.entradasEfectivo, 20.0);
      expect(summary.entradasTransferencias, 10.0);
      expect(summary.salidasEfectivo, 15.0);
      expect(summary.salidasTransferencias, 0.0);
      expect(summary.gastos, 15.0);
      expect(summary.gastosDelCiclo, 15.0);
      // 100.00 + 20.00 - 15.00 = 105.00
      expect(summary.efectivoEsperado, 105.0);
      // 50.00 + 10.00 = 60.00
      expect(summary.transferenciasEsperadas, 60.0);
    },
  );
}
