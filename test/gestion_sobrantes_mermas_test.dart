import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/features/preparation/data/repositories/preparacion_repository.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

void main() {
  late Database db;
  late PreparacionRepository prepRepo;
  late CajaRepository cajaRepo;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb(seed: false);
    prepRepo = PreparacionRepository();
    cajaRepo = CajaRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<int> seedPizzaAmericana({required int stock}) async {
    final catId = await db.insert('Categorias', {
      'nombre': 'Pizzas',
    });
    final prodId = await db.insert('Productos', {
      'categoria_id': catId,
      'nombre': 'Pizza Americana',
      'tipo_preparacion': 'anticipado',
      'activo': 1,
    });
    return db.insert('VariantesProducto', {
      'producto_id': prodId,
      'nombre_variante': 'Familiar',
      'precio_venta': 25.0,
      'costo_estimado_manual': 10.0,
      'stock': stock,
      'active': 1,
    });
  }

  test(
    'Gestionar sobrantes: rechaza desborde (2 merma + 2 mañana > 3 stock) y aplica 1 merma + 2 mañana correctamente',
    () async {
      final varId = await seedPizzaAmericana(stock: 3);

      final items = await prepRepo.getProductosConStockParaSobrantes();
      expect(items.length, 1);
      expect(items.first['variante_id'], varId);
      expect(items.first['stock'], 3);

      // 1. Intentar 2 para mañana y 2 para merma (total 4 > 3 stock) -> debe fallar
      await expectLater(
        () => prepRepo.procesarGestionSobrantesStock(
          decisiones: {
            varId: {'manana': 2, 'merma': 2},
          },
          esCierreDeCiclo: true,
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains('desborda el stock disponible'),
          ),
        ),
      );

      // El stock sigue intacto en 3
      final rowBefore = await db.query(
        'VariantesProducto',
        where: 'id = ?',
        whereArgs: [varId],
      );
      expect(rowBefore.first['stock'], 3);

      // 2. Enviar 2 para mañana y 1 para merma (total 3 <= 3 stock) -> éxito
      await prepRepo.procesarGestionSobrantesStock(
        decisiones: {
          varId: {'manana': 2, 'merma': 1},
        },
        esCierreDeCiclo: true,
      );

      // Stock físico se reduce en 1 (merma) -> queda en 2 para mañana
      final rowAfter = await db.query(
        'VariantesProducto',
        where: 'id = ?',
        whereArgs: [varId],
      );
      expect(rowAfter.first['stock'], 2);

      // Registro en tabla Merma por 1 unidad
      final mermas = await db.query(
        'Merma',
        where: 'variante_id = ?',
        whereArgs: [varId],
      );
      expect(mermas.length, 1);
      expect((mermas.first['cantidad'] as num).toInt(), 1);

      // Registro en PreparacionDiaria del día siguiente por 2 unidades resueltas
      final tomorrow = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')
          .first;
      final prepTomorrow = await db.rawQuery(
        '''
        SELECT ip.cantidad_preparada, ip.resuelto
        FROM ItemsPreparacion ip
        JOIN PreparacionDiaria pd ON pd.id = ip.preparacion_id
        WHERE pd.fecha = ? AND ip.variante_id = ?
        ''',
        [tomorrow, varId],
      );
      expect(prepTomorrow.length, 1);
      expect(prepTomorrow.first['cantidad_preparada'], 2);
      expect(prepTomorrow.first['resuelto'], 1);
    },
  );

  test(
    'Si se gestiona al cerrar caja, al abrir otro ciclo NO detecta ningún pendiente (modal y banner no aparecen)',
    () async {
      final varId = await seedPizzaAmericana(stock: 3);

      final sesionId1 = await cajaRepo.abrirSesion(
        SesionCaja(
          fechaApertura: DateTime.now().toIso8601String(),
          montoApertura: 50.0,
          estado: 'abierta',
        ),
        null,
        userId: null,
      );

      // El usuario gestiona sobrantes en el cierre de caja (1 merma, 2 mañana)
      await prepRepo.procesarGestionSobrantesStock(
        decisiones: {
          varId: {'manana': 2, 'merma': 1},
        },
        esCierreDeCiclo: true,
      );

      // Cierra la caja
      await cajaRepo.cerrarSesion(
        sesionId: sesionId1,
        efectivoContado: 50.0,
        transferenciasContadas: 0.0,
        nota: 'Cierre ciclo con sobrantes gestionados',
        usuarioId: null,
      );

      // Abre el nuevo ciclo
      await cajaRepo.abrirSesion(
        SesionCaja(
          fechaApertura: DateTime.now()
              .add(const Duration(seconds: 2))
              .toIso8601String(),
          montoApertura: 50.0,
          estado: 'abierta',
        ),
        null,
        userId: null,
      );

      // Al entrar a Preparación, soloNoResueltos debe estar VACÍO
      final noResueltos = await prepRepo.getProductosConStockParaSobrantes(
        soloNoResueltos: true,
      );
      expect(noResueltos, isEmpty);

      // El stock físico es 2
      final row = await db.query(
        'VariantesProducto',
        where: 'id = ?',
        whereArgs: [varId],
      );
      expect(row.first['stock'], 2);
    },
  );

  test(
    'Si no se gestiona al cerrar caja, al abrir otro ciclo y entrar a Preparación detecta el sobrante pendiente, y al resolverlo ya no vuelve a salir',
    () async {
      final varId = await seedPizzaAmericana(stock: 3);

      // Abrir y cerrar sesión de caja dejando 3 unidades con stock sin resolver
      final sesionId1 = await cajaRepo.abrirSesion(
        SesionCaja(
          fechaApertura: DateTime.now().toIso8601String(),
          montoApertura: 50.0,
          estado: 'abierta',
        ),
        null,
        userId: null,
      );
      await cajaRepo.cerrarSesion(
        sesionId: sesionId1,
        efectivoContado: 50.0,
        transferenciasContadas: 0.0,
        nota: 'Cierre ciclo sin gestionar',
        usuarioId: null,
      );

      // Abrir un nuevo ciclo de caja
      await cajaRepo.abrirSesion(
        SesionCaja(
          fechaApertura: DateTime.now()
              .add(const Duration(seconds: 2))
              .toIso8601String(),
          montoApertura: 50.0,
          estado: 'abierta',
        ),
        null,
        userId: null,
      );

      // Al ingresar a Preparación (soloNoResueltos: true), debe detectar las 3 Pizzas Americanas pendientes
      final noResueltos = await prepRepo.getProductosConStockParaSobrantes(
        soloNoResueltos: true,
      );
      expect(noResueltos.length, 1);
      expect(noResueltos.first['variante_id'], varId);
      expect(noResueltos.first['stock'], 3);

      // Al resolver desde Preparación (2 para hoy, 1 para merma)
      await prepRepo.procesarGestionSobrantesStock(
        decisiones: {
          varId: {'manana': 2, 'merma': 1},
        },
        esCierreDeCiclo: false,
      );

      // Ya no debe volver a saltar automáticamente en el mismo ciclo
      final despues = await prepRepo.getProductosConStockParaSobrantes(
        soloNoResueltos: true,
      );
      expect(despues, isEmpty);

      // Guardar preparación del día para ese producto (2 existentes + 3 nuevas = 5)
      final hoy = DateTime.now().toIso8601String().split('T').first;
      await prepRepo.registrarPreparacion(
        fecha: hoy,
        items: [
          {'varianteId': varId, 'cantidad': 5, 'notas': null},
        ],
        trasladadosPorVariante: {varId: 2},
      );

      // Stock físico aumentó solo en las 3 nuevas (2 iniciales + 3 = 5)
      final row = await db.query(
        'VariantesProducto',
        where: 'id = ?',
        whereArgs: [varId],
      );
      expect(row.first['stock'], 5);

      // Sigue sin detectar pendientes al volver a consultar
      final finalCheck = await prepRepo.getProductosConStockParaSobrantes(
        soloNoResueltos: true,
      );
      expect(finalCheck, isEmpty);
    },
  );
}
