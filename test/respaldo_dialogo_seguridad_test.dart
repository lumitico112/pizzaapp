import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/core/theme/app_theme.dart';
import 'package:pizzaapp/features/backup/presentation/backup_screen.dart';
import 'package:pizzaapp/features/backup/presentation/widgets/backup_password_dialog.dart';

/// FS-7A: ciclo de vida del diálogo de contraseña de la copia portátil.
///
/// Regresión de DEF-FS7-01: liberar los `TextEditingController` justo al
/// cerrar el diálogo (`showDialog` ya retornó pero la ruta sigue animando la
/// salida) provoca "A TextEditingController was used after being disposed",
/// seguido de la aserción `_dependents.isEmpty` y del pantallazo rojo.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Poppins real del bundle: evita overflow por métricas de la fuente de test.
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
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.bold),
    ]);
  });

  Future<void> pumpBackupScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const BackupScreen()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openExportDialog(WidgetTester tester) async {
    final card = find.text('Exportar copia para transferir');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Proteger copia portátil'), findsOneWidget);
  }

  Future<void> pumpDialogHost(
    WidgetTester tester, {
    required ValueChanged<String?> onResult,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: _DialogHost(onResult: onResult),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openHostDialog(WidgetTester tester) async {
    await tester.tap(find.text('Abrir diálogo'));
    await tester.pumpAndSettle();
    expect(find.text('Proteger copia portátil'), findsOneWidget);
  }

  testWidgets('cancelar el diálogo de exportación no deja excepciones', (
    tester,
  ) async {
    await pumpBackupScreen(tester);
    await openExportDialog(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Proteger copia portátil'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar tras contraseñas dispares no deja excepciones', (
    tester,
  ) async {
    await pumpBackupScreen(tester);
    await openExportDialog(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'KimiBackup2026');
    await tester.enterText(fields.at(1), 'OtraClave2026');

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(find.text('Proteger copia portátil'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Proteger copia portátil'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el diálogo devuelve la contraseña válida y se cierra limpio', (
    tester,
  ) async {
    String? result = 'sin-resultado';
    await pumpDialogHost(tester, onResult: (value) => result = value);
    await openHostDialog(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'KimiBackup2026');
    await tester.enterText(fields.at(1), 'KimiBackup2026');

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(result, 'KimiBackup2026');
    expect(find.text('Proteger copia portátil'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el diálogo cancelado devuelve null y no deja excepciones', (
    tester,
  ) async {
    String? result = 'sin-resultado';
    await pumpDialogHost(tester, onResult: (value) => result = value);
    await openHostDialog(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Proteger copia portátil'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el diálogo pide la contraseña antes de continuar', (
    tester,
  ) async {
    String? result = 'sin-resultado';
    await pumpDialogHost(tester, onResult: (value) => result = value);
    await openHostDialog(tester);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe la contraseña.'), findsOneWidget);
    expect(find.text('Proteger copia portátil'), findsOneWidget);
    expect(result, 'sin-resultado');

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}

class _DialogHost extends StatelessWidget {
  const _DialogHost({required this.onResult});

  final ValueChanged<String?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final value = await BackupPasswordDialog.show(
              context,
              title: 'Proteger copia portátil',
              help: 'Usa una contraseña de al menos 12 caracteres.',
              confirm: true,
            );
            onResult(value);
          },
          child: const Text('Abrir diálogo'),
        ),
      ),
    );
  }
}
