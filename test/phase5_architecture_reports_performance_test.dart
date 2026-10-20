import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/categoria_insumo_controller.dart';
import 'package:pizzaapp/features/assets/application/asset_service.dart';
import 'package:pizzaapp/features/assets/domain/entities/asset.dart';
import 'package:pizzaapp/features/assets/presentation/controllers/asset_controller.dart';
import 'package:pizzaapp/features/backup/application/backup_service.dart';
import 'package:pizzaapp/models/categoria_insumo.dart';
import 'package:pizzaapp/models/reporte_periodo.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/services/categoria_insumo_service.dart';
import 'package:pizzaapp/services/reportes_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

class _FakeFailingAssetService extends Fake implements ActivoFijoService {
  @override
  double calcularTotalInvertido(List<ActivoFijo> activos) => 0.0;

  @override
  Future<List<ActivoFijo>> obtenerTodos() async => [];

  @override
  Future<int> registrarGastoReparacion(
    ActivoFijo activo,
    double costo,
    String descripcion,
  ) async {
    throw Exception('Fallo simulado en motor de base de datos');
  }
}

class _FakeSuccessAssetService extends Fake implements ActivoFijoService {
  @override
  double calcularTotalInvertido(List<ActivoFijo> activos) => 1500.0;

  @override
  Future<List<ActivoFijo>> obtenerTodos() async => [];

  @override
  Future<int> registrarGastoReparacion(
    ActivoFijo activo,
    double costo,
    String descripcion,
  ) async {
    return 1;
  }
}

class _FakeFailingInsumoRepo extends Fake implements InsumoRepository {
  @override
  Future<List<CategoriaInsumo>> getCategoriasInsumo() async {
    throw Exception('Error simulado de conexion');
  }
}

void main() {
  late Database db;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  group('Fase 5 — Arquitectura, Reportes COGS por Receta, Isolate y Limpieza', () {
    test(
      'RN-05 / C-15: ReportesService calcula COGS priorizando el costo de receta activa sobre costo manual',
      () async {
        final today = '2026-10-16';

        // 1. Insertar Insumos
        final quesoId = await db.insert('Insumos', {
          'nombre': 'Queso Mozzarella',
          'unidad_medida': 'kg',
          'costo_por_unidad': 20.0,
          'stock_actual': 50.0,
          'contenido_paquete': 1,
        });
        final salsaId = await db.insert('Insumos', {
          'nombre': 'Salsa de Tomate Especial',
          'unidad_medida': 'kg',
          'costo_por_unidad': 6.0,
          'stock_actual': 50.0,
          'contenido_paquete': 1,
        });

        // 2. Insertar Categoría y Productos
        final catId = await db.insert('Categorias', {'nombre': 'Pizzas'});
        final prodPizzaId = await db.insert('Productos', {
          'nombre': 'Pizza Clásica',
          'categoria_id': catId,
          'tipo_preparacion': 'momento',
        });
        final prodBebidaId = await db.insert('Productos', {
          'nombre': 'Gaseosa Personal',
          'categoria_id': catId,
          'tipo_preparacion': 'momento',
        });

        // 3. Variante 1 con receta activa:
        // 250 g Queso (0.25 kg * 20 = 5.0) + 150 g Salsa (0.15 kg * 6 = 0.90) = 5.90 costo receta.
        // Costo manual configurado en 15.00 (el reporte debe ignorar 15.00 y usar 5.90).
        final pizzaVarId = await db.insert('VariantesProducto', {
          'producto_id': prodPizzaId,
          'nombre_variante': 'Mediana',
          'precio_venta': 28.0,
          'costo_estimado_manual': 15.0,
          'active': 1,
        });

        await db.insert('Recetas', {
          'variante_id': pizzaVarId,
          'insumo_id': quesoId,
          'cantidad': 250.0,
          'unidad_medida': 'g',
        });
        await db.insert('Recetas', {
          'variante_id': pizzaVarId,
          'insumo_id': salsaId,
          'cantidad': 150.0,
          'unidad_medida': 'g',
        });

        // 4. Variante 2 sin receta:
        // Costo manual = 2.50 (el reporte debe usar 2.50 como fallback defensivo).
        final bebidaVarId = await db.insert('VariantesProducto', {
          'producto_id': prodBebidaId,
          'nombre_variante': 'Inca Kola 500ml',
          'precio_venta': 4.0,
          'costo_estimado_manual': 2.50,
          'active': 1,
        });

        // 5. Registrar sesión de caja y venta
        await db.insert('SesionesCaja', {
          'fecha_apertura': '$today 10:00:00',
          'monto_apertura': 100.0,
          'estado': 'abierta',
        });

        final ventaId = await db.insert('Ventas', {
          'fecha': '$today 12:00:00',
          'hora': '12:00:00',
          'metodo_pago': 'efectivo',
          'subtotal': 68.0,
          'descuento': 0.0,
          'total': 68.0,
          'anulada': 0,
        });

        // 2 pizzas medianas (COGS = 2 * 5.90 = 11.80)
        await db.insert('DetalleVenta', {
          'venta_id': ventaId,
          'variante_id': pizzaVarId,
          'cantidad': 2,
          'precio_unitario': 28.0,
        });

        // 3 bebidas (COGS = 3 * 2.50 = 7.50)
        await db.insert('DetalleVenta', {
          'venta_id': ventaId,
          'variante_id': bebidaVarId,
          'cantidad': 3,
          'precio_unitario': 4.0,
        });

        // 6. Consultar reporte global
        final reporteService = ReportesService();
        final periodo = ReportePeriodo.personalizado(
          DateTime.parse(today),
          DateTime.parse(today),
        );
        final reporte = await reporteService.getReporteGlobal(periodo);

        expect(reporte.totalIngresos, equals(68.0));
        // COGS esperado = 11.80 + 7.50 = 19.30
        // (Si hubiera usado costo_estimado_manual para la pizza, habría sido 2*15 + 3*2.5 = 37.50)
        expect(reporte.costoMercaderia, closeTo(19.30, 0.001));
        expect(reporte.beneficioNeto, closeTo(68.0 - 19.30, 0.001));
      },
    );

    test(
      'RN-04: Método de pago mixto está deshabilitado en modelo y repositorio',
      () async {
        // En modelo toMap()
        final venta = Venta(
          fecha: '2026-10-16',
          hora: '14:00',
          metodoPago: 'mixto',
          subtotal: 50.0,
          total: 50.0,
        );

        expect(
          () => venta.toMap(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('deshabilitado'),
            ),
          ),
        );

        // En repositorio registrarVentaCompleta
        final repo = VentaRepository();

        // Caja abierta
        await db.insert('SesionesCaja', {
          'fecha_apertura': '2026-10-16 10:00:00',
          'monto_apertura': 100.0,
          'estado': 'abierta',
        });

        // Intento directo con mapa alterado o método mixto
        expect(
          () => repo.registrarVentaCompleta(
            Venta(
              fecha: '2026-10-16',
              hora: '14:00',
              metodoPago: 'mixto',
              subtotal: 50.0,
              total: 50.0,
            ),
            [],
          ),
          throwsA(anything),
        );
      },
    );

    test(
      'RN-07: Venta de producto momento sin stock suficiente rechaza e incluye el nombre del insumo faltante',
      () async {
        // Insumo con stock casi nulo (0.05 kg)
        final insumoId = await db.insert('Insumos', {
          'nombre': 'Harina Especial 000',
          'unidad_medida': 'kg',
          'costo_por_unidad': 3.0,
          'stock_actual': 0.05,
          'contenido_paquete': 1,
        });

        final catId = await db.insert('Categorias', {'nombre': 'Pastas'});
        final prodId = await db.insert('Productos', {
          'nombre': 'Pasta Artesanal',
          'categoria_id': catId,
          'tipo_preparacion': 'momento',
        });

        final varId = await db.insert('VariantesProducto', {
          'producto_id': prodId,
          'nombre_variante': 'Porción 500g',
          'precio_venta': 20.0,
          'active': 1,
        });

        // Requiere 0.5 kg (500g) de harina
        await db.insert('Recetas', {
          'variante_id': varId,
          'insumo_id': insumoId,
          'cantidad': 0.5,
          'unidad_medida': 'kg',
        });

        await db.insert('SesionesCaja', {
          'fecha_apertura': '2026-10-16 10:00:00',
          'monto_apertura': 50.0,
          'estado': 'abierta',
        });

        final repo = VentaRepository();
        final venta = Venta(
          fecha: '2026-10-16',
          hora: '14:00',
          metodoPago: 'efectivo',
          subtotal: 20.0,
          total: 20.0,
        );

        final item = DetalleVenta(
          ventaId: 0,
          varianteId: varId,
          cantidad: 1,
          precioUnitario: 20.0,
        );

        expect(
          () => repo.registrarVentaCompleta(venta, [item]),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Stock insuficiente para "Harina Especial 000"'),
            ),
          ),
        );
      },
    );

    test(
      'C-29: ActivoFijoController asegura que isLoading se restablece en finally tras éxito o fallo',
      () async {
        final activoDummy = ActivoFijo(
          id: 1,
          nombre: 'Horno Pizzero',
          costo: 3000.0,
          fechaAdquisicion: '2026-01-01',
          estado: 'En uso',
          condicion: 'Comprado',
          metodoPago: 'Contado',
          cuotas: 1,
          cantidad: 1,
        );

        // 1. Caso de fallo
        final failingController = ActivoFijoController(_FakeFailingAssetService());
        expect(failingController.isLoading, isFalse);

        final resFallo = await failingController.registrarReparacion(
          activoDummy,
          250.0,
          'Cambio de termostato',
        );

        expect(resFallo, isFalse);
        expect(failingController.isLoading, isFalse);
        expect(failingController.error, contains('Fallo simulado'));

        // 2. Caso de éxito
        final successController = ActivoFijoController(_FakeSuccessAssetService());
        expect(successController.isLoading, isFalse);

        final resExito = await successController.registrarReparacion(
          activoDummy,
          100.0,
          'Mantenimiento preventivo',
        );

        expect(resExito, isTrue);
        expect(successController.isLoading, isFalse);
        expect(successController.error, isNull);
      },
    );

    test(
      'C-25: Controladores formatean excepciones reales sin literales escapados "\$e"',
      () async {
        final controller = CategoriaInsumoController(
          CategoriaInsumoService(_FakeFailingInsumoRepo()),
        );

        await controller.loadCategorias();

        expect(controller.isLoading, isFalse);
        expect(controller.error, isNotNull);
        expect(controller.error, isNot(contains(r'$e')));
        expect(controller.error, contains('Error simulado de conexion'));
      },
    );

    test(
      'C-17: BackupService ejecuta cifrado y descifrado PBKDF2 en Isolate.run correctamente',
      () async {
        // Sembrar datos básicos en la BD de prueba
        await db.insert('Usuarios', {
          'nombre': 'Admin Backup Test',
          'username': 'admin_test',
          'password_hash': 'pbkdf2\$10000\$dummy\$dummy',
          'rol': 'admin',
          'activo': 1,
          'bloqueado': 0,
        });

        final backupService = BackupService();
        final password = 'ClaveDeCopiaSegura123!';

        // 1. Crear respaldo cifrado portátil
        final bytes = await backupService.createEncryptedBackupForTesting(password);
        expect(bytes, isNotNull);
        expect(bytes.length, greaterThan(32));
        // Encabezado KPZB v1
        expect(bytes[0], equals(0x4B)); // 'K'
        expect(bytes[1], equals(0x50)); // 'P'
        expect(bytes[2], equals(0x5A)); // 'Z'
        expect(bytes[3], equals(0x42)); // 'B'
        expect(bytes[4], equals(0x01)); // Version 1

        // 2. Descifrar y verificar payload vía Isolate.run
        final payload = await backupService.decryptAndReadBackupForTesting(
          bytes,
          password,
        );

        expect(payload['tables'], isA<Map>());
        final tables = payload['tables'] as Map<String, dynamic>;
        expect(tables.containsKey('Usuarios'), isTrue);
      },
    );
  });
}
