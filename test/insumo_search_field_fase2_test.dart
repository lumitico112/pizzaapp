import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/screens/compras/widgets/insumo_search_field.dart';

final _insumos = [
  Insumo(
    id: 1,
    nombre: 'Harina de trigo',
    tipoInsumo: 'ingrediente',
    unidadMedida: 'Kg',
  ),
  Insumo(
    id: 2,
    nombre: 'Aceite de girasol',
    tipoInsumo: 'ingrediente',
    unidadMedida: 'Litros',
  ),
  Insumo(
    id: 3,
    nombre: 'Queso mozzarella',
    tipoInsumo: 'ingrediente',
    unidadMedida: 'Kg',
  ),
  Insumo(
    id: 4,
    nombre: 'Caja pizza grande',
    tipoInsumo: 'empaquíe',
    unidadMedida: 'Unidades',
  ),
  Insumo(
    id: 5,
    nombre: 'Jalapeño en rodajas',
    tipoInsumo: 'ingrediente',
    unidadMedida: 'Unidades',
  ),
];

void main() {
  group('filtrarInsumos', () {
    test('filtra por nombre sin distinguir mayusculas ni acentos', () {
      expect(filtrarInsumos(_insumos, 'HARINA').map((i) => i.id), [1]);
      expect(filtrarInsumos(_insumos, 'jalapeno').map((i) => i.id), [5]);
    });

    test('filtra por tipo y unidad', () {
      expect(filtrarInsumos(_insumos, 'empaquie').map((i) => i.id), [4]);
      expect(filtrarInsumos(_insumos, 'litros').map((i) => i.id), [2]);
    });

    test('prioriza coincidencias al inicio del nombre', () {
      final conCoincidenciaAlFinal = [
        ..._insumos,
        Insumo(
          id: 6,
          nombre: 'Salvado de harina',
          tipoInsumo: 'ingrediente',
          unidadMedida: 'Kg',
        ),
      ];

      expect(
        filtrarInsumos(
          conCoincidenciaAlFinal,
          'harina',
        ).map((i) => i.id).toList(),
        [1, 6],
      );
    });

    test('devuelve vacio cuando no hay coincidencias', () {
      expect(filtrarInsumos(_insumos, 'fosforos'), isEmpty);
    });

    test('respeta el limite de sugerencias', () {
      expect(filtrarInsumos(_insumos, '', limit: 2).length, 2);
    });
  });

  group('InsumoSearchField', () {
    testWidgets('selecciona una coincidencia existente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _SearchHarness(insumos: _insumos)),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hari');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('insumo-option-1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('compra-ocasional-option')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('insumo-option-1')));
      await tester.pumpAndSettle();

      final state = tester.state<_SearchHarnessState>(
        find.byType(_SearchHarness),
      );
      expect(state.selectedId, 1);
      expect(state.textController.text, 'Harina de trigo');
    });

    testWidgets('muestra la accion ocasional cuando no hay coincidencias', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _SearchHarness(insumos: _insumos)),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'fosforos');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('compra-ocasional-option')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('compra-ocasional-option')));
      await tester.pumpAndSettle();

      final state = tester.state<_SearchHarnessState>(
        find.byType(_SearchHarness),
      );
      expect(state.occasionalQuery, 'fosforos');
    });

    testWidgets('limpia la seleccion al escribir otro insumo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _SearchHarness(insumos: _insumos)),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hari');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('insumo-option-1')));
      await tester.pumpAndSettle();

      final state = tester.state<_SearchHarnessState>(
        find.byType(_SearchHarness),
      );
      expect(state.selectedId, 1);

      await tester.enterText(find.byType(TextFormField), 'aceite');
      await tester.pumpAndSettle();

      expect(state.selectedId, isNull);
      expect(find.byKey(const ValueKey('insumo-option-2')), findsOneWidget);
    });
  });
}

class _SearchHarness extends StatefulWidget {
  final List<Insumo> insumos;

  const _SearchHarness({required this.insumos});

  @override
  State<_SearchHarness> createState() => _SearchHarnessState();
}

class _SearchHarnessState extends State<_SearchHarness> {
  final textController = TextEditingController();
  final focusNode = FocusNode();

  int? selectedId;
  String? occasionalQuery;

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InsumoSearchField(
            insumos: widget.insumos,
            selectedId: selectedId,
            textController: textController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Buscar insumo por nombre, tipo o unidad',
            ),
            onSelected: (insumo) {
              setState(() => selectedId = insumo.id);
            },
            onQueryChanged: (text) {
              final coincidencias = widget.insumos
                  .where((insumo) => insumo.id == selectedId)
                  .toList();
              final seleccionado = coincidencias.isEmpty
                  ? null
                  : coincidencias.first;
              if (selectedId != null &&
                  text.trim() != (seleccionado?.nombre ?? '').trim()) {
                setState(() => selectedId = null);
              }
            },
            onRegistrarOcasional: (query) {
              setState(() => occasionalQuery = query);
            },
          ),
        ],
      ),
    );
  }
}
