import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/core/theme/app_theme.dart';
import 'package:pizzaapp/features/purchases/application/compra_service.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/features/purchases/domain/entities/compra_ocasional.dart';
import 'package:pizzaapp/features/purchases/domain/usecases/register_payable_payment.dart';
import 'package:pizzaapp/features/purchases/presentation/controllers/compras_controller.dart';
import 'package:pizzaapp/models/cuenta_por_pagar.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/screens/compras/compra_ocasional_form_screen.dart';
import 'package:pizzaapp/screens/compras/compras_screen.dart';
import 'package:pizzaapp/screens/compras/widgets/nueva_compra_sheet.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

String _soloFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

String _hoy() => _soloFecha(DateTime.now());

CompraOcasional _ocasional({
  int? id,
  bool esPorPagar = false,
  double adelanto = 0,
  double total = 120,
  double cantidad = 2,
  String descripcion = 'Flete refrigerado',
  String categoria = 'Transporte',
  String? fecha,
  int cuotas = 1,
  String metodoPago = 'yape',
}) {
  return CompraOcasional(
    id: id,
    fecha: fecha ?? _hoy(),
    descripcion: descripcion,
    cantidad: cantidad,
    unidadMedida: 'caja',
    costoTotal: total,
    categoria: categoria,
    proveedor: 'Transportes del Sur',
    esPorPagar: esPorPagar,
    adelanto: adelanto,
    cuotas: cuotas,
    metodoPago: metodoPago,
  );
}

CompraService _crearServicio() {
  final repo = PurchaseRepository();
  return CompraService(
    repo,
    GastoRepository(),
    AuthService(UsuarioRepository()),
    RegisterPayablePayment(repo),
  );
}

ComprasController _crearControlador() => ComprasController(_crearServicio());

class _HistorialCargadoController extends ComprasController {
  // El parametro del constructor base es privado (`_service`), por lo que no
  // puede declararse como super parametro desde otra libreria.
  // ignore: use_super_parameters
  _HistorialCargadoController(CompraService service) : super(service);

  Future<void> cargarInicial() => super.loadHistorial();

  @override
  Future<void> loadHistorial() async {}
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

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
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.poppins(fontWeight: FontWeight.w500),
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.bold),
    ]);
  });

  late Database db;
  late PurchaseRepository repo;

  setUp(() async {
    db = await TestDbHarness.openFreshInMemoryDb();
    repo = PurchaseRepository();
  });

  tearDown(() async {
    await TestDbHarness.closeDb(db);
  });

  group('Fase 4: integracion de compras ocasionales', () {
    test(
      'getGastosRaw excluye gastos ocasionales y conserva los normales',
      () async {
        await db.insert('Gastos', {
          'fecha': _hoy(),
          'categoria': 'Servicios',
          'descripcion': 'Luz del local',
          'monto': 40.0,
        });
        await repo.registrarCompraOcasional(
          _ocasional(descripcion: 'Fósforos', categoria: 'Limpieza', total: 15),
        );

        final gastos = await GastoRepository().getGastosRaw();

        expect(gastos, hasLength(1));
        expect(gastos.single['descripcion'], 'Luz del local');
        expect(gastos.single['compra_ocasional_id'], isNull);
        expect(await db.query('Gastos'), hasLength(2));
      },
    );

    test(
      'getCuentasPorPagar muestra descripcion y categoria ocasional',
      () async {
        final compraId = await repo.registrarCompraOcasional(
          _ocasional(
            esPorPagar: true,
            adelanto: 20,
            cuotas: 2,
            descripcion: 'Flete refrigerado',
            categoria: 'Transporte',
          ),
        );

        final filas = await repo.getCuentasPorPagar();
        final cuenta = CuentaPorPagar.fromMap(filas.single);

        expect(cuenta.compraOcasionalId, compraId);
        expect(cuenta.esCompraOcasional, isTrue);
        expect(cuenta.insumoNombre, 'Flete refrigerado');
        expect(cuenta.compraOcasionalCategoria, 'Transporte');
        expect(cuenta.proveedor, 'Transportes del Sur');
        expect(cuenta.saldoPendiente, 100.0);
      },
    );

    testWidgets('el selector Nueva compra ofrece las dos modalidades', (
      tester,
    ) async {
      TipoNuevaCompra? seleccion;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    seleccion = await showNuevaCompraSheet(context);
                  },
                  child: const Text('Abrir selector'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir selector'));
      await tester.pumpAndSettle();

      expect(find.text('Insumo inventariable'), findsOneWidget);
      expect(find.text('Compra ocasional'), findsOneWidget);
      expect(find.textContaining('no modifica el inventario'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nueva-compra-ocasional')));
      await tester.pumpAndSettle();

      expect(seleccion, TipoNuevaCompra.ocasional);
    });

    testWidgets('el formulario en edicion precarga y bloquea la modalidad', (
      tester,
    ) async {
      final compra = _ocasional(
        id: 7,
        esPorPagar: true,
        adelanto: 20,
        cuotas: 2,
        total: 120,
        descripcion: 'Flete refrigerado',
      );
      final controller = _crearControlador();

      await tester.pumpWidget(
        ChangeNotifierProvider<ComprasController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CompraOcasionalFormScreen(compra: compra),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar compra ocasional'), findsOneWidget);
      expect(find.text('Flete refrigerado'), findsOneWidget);
      expect(find.text('120.00'), findsOneWidget);

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Compra a crédito'),
        250,
        scrollable: scrollable,
      );
      expect(find.textContaining('no se puede cambiar'), findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
      expect(switchTile.onChanged, isNull);

      await tester.scrollUntilVisible(
        find.text('Guardar cambios'),
        250,
        scrollable: scrollable,
      );
      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets('el historial muestra el distintivo y no menciona stock', (
      tester,
    ) async {
      final controller = _HistorialCargadoController(_crearServicio());
      await tester.runAsync(() async {
        await repo.registrarCompraOcasional(
          _ocasional(esPorPagar: true, adelanto: 20, cuotas: 2),
        );
        await controller.cargarInicial();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<ComprasController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ComprasScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMPRA OCASIONAL'), findsOneWidget);
      expect(find.text('Flete refrigerado'), findsOneWidget);
      expect(find.text('S/ 120.00'), findsOneWidget);
      expect(find.text('Por pagar'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar compra ocasional'), findsOneWidget);
      expect(find.textContaining('no modificó el inventario'), findsOneWidget);
      expect(find.textContaining('Reversión de stock'), findsNothing);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });
  });
}
