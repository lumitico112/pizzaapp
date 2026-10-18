import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/controllers/pos_controller.dart';
import 'package:pizzaapp/core/theme/app_theme.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_cart_summary.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_cobro_sheet.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_historial_boletas_sheet.dart';
import 'package:pizzaapp/screens/pos/widgets/pos_item_detail_sheet.dart';
import 'package:pizzaapp/services/pos_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Fase 13 (H-12): semántica y escalado de texto en pantallas de operación
/// diaria. Alcance: POS (cobrar, eliminar ítem, cortesía), Caja
/// (abrir/cerrar/salida manual), diálogo de anulación de venta y bandeja de
/// gastos. Las correcciones de la auditoría (etiquetas Semantics, áreas
/// táctiles >= 48 y ExcludeSemantics contra dobles anuncios) viven en:
/// pos_cart_summary.dart, pos_item_detail_sheet.dart, pos_historial_boletas_sheet.dart,
/// caja_screen.dart y compras_screen.dart.
class _FakePosService extends Fake implements PosService {
  @override
  Future<List<Map<String, dynamic>>> getHistorialVentas() async => [
    {
      'id': 1,
      'fecha': '2026-10-18',
      'hora': '12:30',
      'total': 25.0,
      'metodo_pago': 'efectivo',
      'items_count': 1,
      'anulada': 0,
      'nota': '',
    },
  ];
}

PosItem _itemTest() {
  final producto = Producto(
    id: 1,
    nombre: 'Pizza Margarita',
    tipoPreparacion: 'momento',
  );
  final variante = VarianteProducto(
    id: 1,
    productoId: 1,
    nombreVariante: 'Familiar',
    precioVenta: 25,
    stock: 10,
  );
  return PosItem(producto, variante);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Igual que en las pruebas de la Fase 9: en los widget tests el estilo por
  // defecto usa una fuente de prueba con métricas anchas; se registra la
  // Poppins real (la que empaqueta la app) para que el layout no difiera de
  // producción (crítico al medir áreas táctiles y escalado de texto).
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fontLoader = FontLoader('Poppins');
    for (final file in const [
      'Poppins-Thin',
      'Poppins-ExtraLight',
      'Poppins-Light',
      'Poppins-Regular',
      'Poppins-Italic',
      'Poppins-Medium',
      'Poppins-SemiBold',
      'Poppins-Bold',
      'Poppins-ExtraBold',
      'Poppins-Black',
    ]) {
      fontLoader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await fontLoader.load();

    final estilosPoppins = [
      GoogleFonts.poppins(),
      GoogleFonts.poppins(fontWeight: FontWeight.w500),
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.bold),
      GoogleFonts.poppins(fontWeight: FontWeight.w800),
      GoogleFonts.poppins(fontWeight: FontWeight.w900),
    ];
    await GoogleFonts.pendingFonts(estilosPoppins);
  });

  late Database db;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb(seed: false);
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );

  PosController nuevoController({bool conItem = true}) {
    final controller = PosController(_FakePosService());
    if (conItem) {
      expect(controller.agregarAlCarrito(_itemTest(), 1), isNull);
    }
    return controller;
  }

  Future<void> verificarGuiasDeAccesibilidad(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  }

  Future<void> abrirDialogoAnulacion(WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        PosHistorialBoletasSheet(
          controller: nuevoController(conItem: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Anular venta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Anular Venta #1'), findsOneWidget);
  }

  group('T1 - guías de accesibilidad en widgets críticos (H-12)', () {
    testWidgets('PosCartSummary vacío cumple guías de toque', (tester) async {
      await tester.pumpWidget(
        wrap(
          PosCartSummary(
            controller: nuevoController(conItem: false),
            onCobrar: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await verificarGuiasDeAccesibilidad(tester);
    });

    testWidgets('PosCartSummary con ítem: quitar y cobrar etiquetados', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(PosCartSummary(controller: nuevoController(), onCobrar: () {})),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('Quitar'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('Cobrar total'),
        ),
        findsOneWidget,
      );

      await verificarGuiasDeAccesibilidad(tester);
    });

    testWidgets('Hoja de detalle (cortesía) cumple guías', (tester) async {
      await tester.pumpWidget(
        wrap(
          PosItemDetailSheet(
            item: _itemTest(),
            controller: PosController(_FakePosService()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await verificarGuiasDeAccesibilidad(tester);
    });

    testWidgets('Hoja de cobro cumple guías', (tester) async {
      await tester.pumpWidget(
        wrap(PosCobroSheet(controller: nuevoController())),
      );
      await tester.pumpAndSettle();
      await verificarGuiasDeAccesibilidad(tester);
    });

    testWidgets('Diálogo de anulación de venta cumple guías', (tester) async {
      await abrirDialogoAnulacion(tester);
      await verificarGuiasDeAccesibilidad(tester);
    });
  });

  group('T2 - escalado de texto 2.0x sin excepciones de layout', () {
    testWidgets('PosCartSummary con ítem a 2.0x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        wrap(PosCartSummary(controller: nuevoController(), onCobrar: () {})),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Hoja de detalle a 2.0x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        wrap(
          PosItemDetailSheet(
            item: _itemTest(),
            controller: PosController(_FakePosService()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Hoja de cobro a 2.0x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        wrap(PosCobroSheet(controller: nuevoController())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Diálogo de anulación a 2.0x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await abrirDialogoAnulacion(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
