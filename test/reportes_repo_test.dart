import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/features/reporting/application/reportes_pdf.dart';
import 'package:pizzaapp/features/reporting/data/repositories/reportes_repository.dart';
import 'package:pizzaapp/models/reporte_data.dart';
import 'package:pizzaapp/services/reportes_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase 8 (H-04c): caracterización del repositorio de reportes movido desde
/// `ReportesService`, con un dataset fijo y valores esperados escritos a mano
/// (ventas, gastos, COGS por receta RN-05 con respaldo manual, utilidad).
///
/// Nota sobre el PDF: `ReportesPdf.generarPDF` depende del directorio temporal
/// de la plataforma (`path_provider`) y del reloj (fecha de emisión), por lo
/// que no se caracteriza byte a byte; en su lugar se valida que genere un
/// archivo PDF real en un directorio de salida inyectado.
void main() {
  late Database db;

  // Mismo formato de rango que usa ReporteController: 'yyyy-MM-dd' en ambos
  // extremos (las fechas de Ventas/Gastos se guardan sin hora).
  const inicio = '2026-10-16';
  const fin = '2026-10-16';

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Future<void> sembrarDatasetFijo() async {
    // Insumo de la receta: queso a S/ 20.00 por kg.
    final quesoId = await db.insert('Insumos', {
      'nombre': 'Queso Mozzarella F8',
      'unidad_medida': 'kg',
      'costo_por_unidad': 20.0,
      'stock_actual': 50.0,
      'contenido_paquete': 1,
    });

    final catId = await db.insert('Categorias', {'nombre': 'F8 Reportes'});

    final pizzaId = await db.insert('Productos', {
      'nombre': 'Pizza F8',
      'categoria_id': catId,
      'tipo_preparacion': 'momento',
    });
    final bebidaId = await db.insert('Productos', {
      'nombre': 'Bebida F8',
      'categoria_id': catId,
      'tipo_preparacion': 'momento',
    });

    // Pizza con receta: 250 g de queso => 0.25 kg x 20 = S/ 5.00 por unidad.
    // El costo manual (15.00) NO debe usarse porque hay receta activa (RN-05).
    final pizzaVarId = await db.insert('VariantesProducto', {
      'producto_id': pizzaId,
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

    // Bebida sin receta: usa el respaldo costo_estimado_manual = S/ 2.50.
    final bebidaVarId = await db.insert('VariantesProducto', {
      'producto_id': bebidaId,
      'nombre_variante': '500ml',
      'precio_venta': 4.0,
      'costo_estimado_manual': 2.50,
      'active': 1,
    });

    // Venta en rango: 2 pizzas (56.00) + 3 bebidas (12.00) = S/ 68.00.
    final ventaId = await db.insert('Ventas', {
      'fecha': '2026-10-16',
      'hora': '12:00:00',
      'metodo_pago': 'efectivo',
      'subtotal': 68.0,
      'descuento': 0.0,
      'total': 68.0,
      'anulada': 0,
    });
    await db.insert('DetalleVenta', {
      'venta_id': ventaId,
      'variante_id': pizzaVarId,
      'cantidad': 2,
      'precio_unitario': 28.0,
    });
    await db.insert('DetalleVenta', {
      'venta_id': ventaId,
      'variante_id': bebidaVarId,
      'cantidad': 3,
      'precio_unitario': 4.0,
    });

    // Venta anulada en rango: no debe sumar ingresos ni COGS.
    final anuladaId = await db.insert('Ventas', {
      'fecha': '2026-10-16',
      'hora': '18:00:00',
      'metodo_pago': 'efectivo',
      'subtotal': 28.0,
      'descuento': 0.0,
      'total': 28.0,
      'anulada': 1,
    });
    await db.insert('DetalleVenta', {
      'venta_id': anuladaId,
      'variante_id': pizzaVarId,
      'cantidad': 1,
      'precio_unitario': 28.0,
    });

    // Venta fuera de rango: no debe contar.
    await db.insert('Ventas', {
      'fecha': '2026-10-20',
      'hora': '12:00:00',
      'metodo_pago': 'efectivo',
      'subtotal': 100.0,
      'descuento': 0.0,
      'total': 100.0,
      'anulada': 0,
    });

    // Gastos: solo el operativo dentro del rango suma (S/ 10.00).
    await db.insert('Gastos', {
      'fecha': '2026-10-16',
      'categoria': 'Servicios',
      'descripcion': 'Luz F8',
      'monto': 10.0,
    });
    // La categoría 'Compras' está excluida del agregado de gastos operativos.
    await db.insert('Gastos', {
      'fecha': '2026-10-16',
      'categoria': 'Compras',
      'descripcion': 'Compra F8 (excluida del agregado)',
      'monto': 999.0,
    });
    // Fuera de rango.
    await db.insert('Gastos', {
      'fecha': '2026-10-20',
      'categoria': 'Servicios',
      'descripcion': 'Fuera de rango F8',
      'monto': 7.0,
    });
  }

  test(
    'F8 H-04c: dataset fijo caracteriza repo (ingresos/gastos) y servicio '
    '(COGS por receta + manual, utilidad y top productos)',
    () async {
      await sembrarDatasetFijo();
      final repo = ReportesRepository();

      // Agregados directos del repositorio.
      expect(await repo.getTotalIngresos(inicio, fin), 68.0);
      expect(await repo.getTotalGastos(inicio, fin), 10.0);

      // Orquestación completa (mismas fórmulas RN-05, verificado a mano):
      // COGS = 2 x 5.00 (receta) + 3 x 2.50 (manual) = 17.50
      // Utilidad = 68.00 - 10.00 - 17.50 = 40.50
      final servicio = ReportesService();
      final reporte = await servicio.getReporteGlobal(inicio, fin);

      expect(reporte.totalIngresos, 68.0);
      expect(reporte.totalGastos, 10.0);
      expect(reporte.costoMercaderia, closeTo(17.50, 0.0001));
      expect(reporte.beneficioNeto, closeTo(40.50, 0.0001));

      // Top productos ordenado por cantidad DESC: 3 bebidas, luego 2 pizzas.
      expect(
        reporte.productosVendidos.map((p) => p.nombre).toList(),
        ['Bebida F8 500ml', 'Pizza F8 Mediana'],
      );
      expect(
        reporte.productosVendidos.map((p) => p.cantidad).toList(),
        [3, 2],
      );
      expect(
        reporte.productosVendidos.map((p) => p.total).toList(),
        [12.0, 56.0],
      );
    },
  );

  test('F8 H-04c: periodo sin datos devuelve agregados en cero', () async {
    final repo = ReportesRepository();
    expect(await repo.getTotalIngresos(inicio, fin), 0.0);
    expect(await repo.getTotalGastos(inicio, fin), 0.0);
  });

  test(
    'F8 H-04c: ReportesPdf genera un PDF real desde ReporteData con salida '
    'inyectada (no se comparan bytes: fecha de emisión y nombre dependen del reloj)',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('kimi_reporte_f8_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final data = ReporteData(
        totalIngresos: 68.0,
        totalGastos: 10.0,
        costoMercaderia: 17.50,
        beneficioNeto: 40.50,
        productosVendidos: [
          ProductoVendido(nombre: 'Bebida F8 500ml', cantidad: 3, total: 12.0),
          ProductoVendido(nombre: 'Pizza F8 Mediana', cantidad: 2, total: 56.0),
        ],
      );

      final ruta = await ReportesPdf.generarPDF(
        data,
        '16/10/2026 - 16/10/2026',
        outputDirectory: tempDir,
      );

      expect(ruta, isNotNull);
      expect(ruta, endsWith('.pdf'));
      final archivo = File(ruta!);
      expect(archivo.existsSync(), isTrue);
      expect(await archivo.length(), greaterThan(1000));
    },
  );
}
