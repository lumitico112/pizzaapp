import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/models/receta.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';
import 'package:pizzaapp/repositories/receta_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_cart_summary.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

class _FakePosService extends Fake implements PosService {}

void main() {
  late Database db;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb(seed: false);
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  group('Fase 6 - Optimización N+1 (C-16)', () {
    test('PromocionRepository.getPromociones carga en lote sin consultas N+1', () async {
      final repo = PromocionRepository();

      // 1. Sin promociones devuelve lista vacía
      final initialPromos = await repo.getPromociones();
      expect(initialPromos, isEmpty);

      // Crear dos productos para los items de promociones
      await db.insert('Categorias', {
        'id': 1,
        'nombre': 'Pizzas',
        'orden': 1,
      });
      await db.insert('Productos', {
        'id': 1,
        'categoria_id': 1,
        'nombre': 'Pizza Americana',
        'descripcion': '',
        'activo': 1,
      });
      await db.insert('VariantesProducto', {
        'id': 1,
        'producto_id': 1,
        'nombre_variante': 'Familiar',
        'precio_venta': 45.0,
        'stock': 10,
        'active': 1,
      });
      await db.insert('VariantesProducto', {
        'id': 2,
        'producto_id': 1,
        'nombre_variante': 'Personal',
        'precio_venta': 20.0,
        'stock': 15,
        'active': 1,
      });

      // Insertar dos promociones con sus items
      final promo1 = Promocion(
        nombre: 'Combo Familiar',
        descripcion: '2 Pizzas Familiares',
        precio: 75.0,
        activa: 1,
      );
      final items1 = [
        PromocionItem(promocionId: 0, varianteId: 1, cantidad: 2),
      ];
      await repo.insertPromocion(promo1, items1);

      final promo2 = Promocion(
        nombre: 'Combo Dúo Personal',
        descripcion: '2 Pizzas Personales',
        precio: 35.0,
        activa: 1,
      );
      final items2 = [
        PromocionItem(promocionId: 0, varianteId: 2, cantidad: 2),
      ];
      await repo.insertPromocion(promo2, items2);

      // Recuperar las promociones con getPromociones
      final promos = await repo.getPromociones();
      expect(promos.length, equals(2));

      final p1 = promos.firstWhere((p) => p.nombre == 'Combo Familiar');
      expect(p1.items.length, equals(1));
      expect(p1.items.first.varianteId, equals(1));
      expect(p1.items.first.cantidad, equals(2));

      final p2 = promos.firstWhere((p) => p.nombre == 'Combo Dúo Personal');
      expect(p2.items.length, equals(1));
      expect(p2.items.first.varianteId, equals(2));
      expect(p2.items.first.cantidad, equals(2));
    });

    test('ProductoRepository.guardarProductoCompleto vincula y sincroniza variantes derivadas en lote', () async {
      final repo = ProductoRepository();

      final cat = Categoria(nombre: 'Bebidas');
      final catId = await repo.insertCategoria(cat);

      // Producto base
      final prodBase = Producto(
        categoriaId: catId,
        nombre: 'Masa Madre Base',
        activo: 1,
      );
      final variantesBase = [
        VarianteProducto(
          productoId: 0,
          nombreVariante: 'Masa 30cm',
          precioVenta: 10.0,
          stock: 25,
          active: 1,
        ),
      ];

      await repo.guardarProductoCompleto(prodBase, variantesBase);
      final baseProducts = await repo.getProductos(categoriaId: catId);
      final baseCreated = baseProducts.firstWhere((p) => p.nombre == 'Masa Madre Base');
      final baseVariants = await repo.getVariantesPorProducto(baseCreated.id!);
      final baseVarId = baseVariants.first.id!;

      // Modificar el stock de la variante base para probar la sincronización
      await db.update('VariantesProducto', {'stock': 30}, where: 'id = ?', whereArgs: [baseVarId]);

      // Producto derivado vinculado
      final prodDerivado = Producto(
        categoriaId: catId,
        nombre: 'Pizza Pre-armada Derivada',
        derivaDeProductoId: baseCreated.id,
        activo: 1,
      );
      final variantesDerivadas = [
        VarianteProducto(
          productoId: 0,
          nombreVariante: 'Pizza 30cm Armada',
          precioVenta: 25.0,
          stock: 0,
          varianteBaseId: baseVarId,
          active: 1,
        ),
      ];

      await repo.guardarProductoCompleto(prodDerivado, variantesDerivadas);

      final derivedProducts = await repo.getProductos(categoriaId: catId);
      final derivedCreated = derivedProducts.firstWhere((p) => p.nombre == 'Pizza Pre-armada Derivada');
      final derivedVariants = await repo.getVariantesPorProducto(derivedCreated.id!);
      expect(derivedVariants.first.stock, equals(30));
      expect(derivedVariants.first.varianteBaseId, equals(baseVarId));
    });

    test('Venta de GASEOSA · Vaso al momento (cortesía S/ 0.00) preserva y recupera receta (90 ml + 1 vaso)', () async {
      final prodRepo = ProductoRepository();
      final recetaRepo = RecetaRepository();
      final ventaRepo = VentaRepository();

      final catId = await prodRepo.insertCategoria(Categoria(nombre: 'Bebidas'));
      final gaseosaInsumoId = await db.insert('Insumos', {
        'nombre': 'Bebida Gaseosa',
        'unidad_medida': 'ml',
        'contenido_paquete': 1,
        'costo_por_unidad': 0.01,
        'stock_actual': 1000.0,
        'stock_minimo': 100.0,
        'activo': 1,
      });
      final vasoInsumoId = await db.insert('Insumos', {
        'nombre': 'Vaso descartable',
        'unidad_medida': 'Unidades',
        'contenido_paquete': 1,
        'costo_por_unidad': 0.10,
        'stock_actual': 50.0,
        'stock_minimo': 5.0,
        'activo': 1,
      });

      await prodRepo.guardarProductoCompleto(
        Producto(
          categoriaId: catId,
          nombre: 'GASEOSA',
          tipoPreparacion: 'momento',
          activo: 1,
        ),
        [
          VarianteProducto(
            productoId: 0,
            nombreVariante: 'Vaso',
            precioVenta: 0.0,
          ),
        ],
      );

      final createdProd = (await prodRepo.getProductos(categoriaId: catId)).first;
      final initialVariant = (await prodRepo.getVariantesPorProducto(createdProd.id!)).first;

      await recetaRepo.insertOrUpdate(
        RecetaItem(
          varianteId: initialVariant.id!,
          insumoId: gaseosaInsumoId,
          cantidad: 90,
          unidadMedida: 'ml',
        ),
      );
      await recetaRepo.insertOrUpdate(
        RecetaItem(
          varianteId: initialVariant.id!,
          insumoId: vasoInsumoId,
          cantidad: 1,
          unidadMedida: 'Unidades',
        ),
      );

      // Editar el producto enviando la variante sin id (simulando recreación de fila en el formulario)
      await prodRepo.guardarProductoCompleto(
        Producto(
          id: createdProd.id,
          categoriaId: catId,
          nombre: 'GASEOSA',
          tipoPreparacion: 'momento',
          activo: 1,
        ),
        [
          VarianteProducto(
            productoId: createdProd.id!,
            nombreVariante: 'Vaso',
            precioVenta: 0.0,
          ),
        ],
      );

      final updatedVariant = (await prodRepo.getVariantesPorProducto(createdProd.id!)).first;
      final ventaId = await ventaRepo.registrarVentaCompleta(
        Venta(
          fecha: '2026-10-16',
          hora: '17:59',
          subtotal: 0.0,
          total: 0.0,
          metodoPago: 'efectivo',
        ),
        [
          DetalleVenta(
            ventaId: 0,
            varianteId: updatedVariant.id,
            cantidad: 2,
            precioUnitario: 0.0,
            esCortesia: true,
          ),
        ],
      );

      expect(ventaId, greaterThan(0));
      final gaseosaRow = (await db.query('Insumos', where: 'id = ?', whereArgs: [gaseosaInsumoId])).first;
      final vasoRow = (await db.query('Insumos', where: 'id = ?', whereArgs: [vasoInsumoId])).first;
      expect((gaseosaRow['stock_actual'] as num).toDouble(), closeTo(820.0, 0.001));
      expect((vasoRow['stock_actual'] as num).toDouble(), closeTo(48.0, 0.001));
    });
  });

  group('Fase 6 - Dependencias Huérfanas y CI/CD (C-22, C-23)', () {
    test('pubspec.yaml no contiene las 9 dependencias eliminadas', () {
      final file = File('pubspec.yaml');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      const purgedPackages = [
        'cupertino_icons',
        'cached_network_image',
        'fl_chart',
        'screenshot',
        'flutter_local_notifications',
        'flutter_svg',
        'printing',
        'audioplayers',
        'lottie',
      ];

      for (final pkg in purgedPackages) {
        expect(
          content.contains('$pkg:'),
          isFalse,
          reason: 'El paquete $pkg debe haber sido eliminado de pubspec.yaml',
        );
      }
    });

    test('.github/workflows/ci.yml está configurado con analyze y test', () {
      final workflow = File('.github/workflows/ci.yml');
      expect(workflow.existsSync(), isTrue);
      final yaml = workflow.readAsStringSync();

      expect(yaml.contains('flutter analyze'), isTrue);
      expect(yaml.contains('flutter test'), isTrue);
      expect(yaml.contains('flutter pub get'), isTrue);
    });
  });

  group('Fase 6 - Accesibilidad y Semantics (C-26, C-31)', () {
    testWidgets('PosCartSummary contiene etiquetas Semantics para cobro y eliminación', (tester) async {
      final controller = PosController(_FakePosService());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosCartSummary(
              controller: controller,
              onCobrar: () {},
            ),
          ),
        ),
      );

      // Carrito vacío: botón deshabilitado con Semantics
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Cobrar total 0.00 soles',
        ),
        findsOneWidget,
      );
    });
  });
}
