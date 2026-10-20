import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/models/reporte_periodo.dart';

void main() {
  group('ReportePeriodo', () {
    test('Hoy y Ayer son días exactos y normalizan la hora', () {
      final ahora = DateTime(2026, 10, 19, 18, 45);
      final hoy = ReportePeriodo.hoy(ahora: ahora);
      final ayer = ReportePeriodo.ayer(ahora: ahora);

      expect(hoy.inicio, DateTime(2026, 10, 19));
      expect(hoy.fin, DateTime(2026, 10, 19));
      expect(hoy.inicioSql, '2026-10-19');
      expect(hoy.finExclusivoSql, '2026-10-20');
      expect(hoy.pdfLabel, 'Del 19/10/2026 al 19/10/2026 (Hoy)');

      expect(ayer.inicio, DateTime(2026, 10, 18));
      expect(ayer.fin, DateTime(2026, 10, 18));
      expect(ayer.pdfLabel, 'Del 18/10/2026 al 18/10/2026 (Ayer)');
    });

    test('Ayer cruza correctamente el cambio de año', () {
      final ayer = ReportePeriodo.ayer(ahora: DateTime(2026, 1, 1));

      expect(ayer.inicio, DateTime(2025, 12, 31));
      expect(ayer.fin, DateTime(2025, 12, 31));
      expect(ayer.inicioSql, '2025-12-31');
    });

    test('Esta semana va del lunes al día actual', () {
      final miercoles = ReportePeriodo.semanaActual(
        ahora: DateTime(2026, 10, 21, 9, 30),
      );

      expect(miercoles.inicio, DateTime(2026, 10, 19));
      expect(miercoles.fin, DateTime(2026, 10, 21));
      expect(miercoles.pdfLabel, 'Del 19/10/2026 al 21/10/2026 (Esta semana)');

      final domingo = ReportePeriodo.semanaActual(
        ahora: DateTime(2026, 10, 25),
      );
      expect(domingo.inicio, DateTime(2026, 10, 19));
      expect(domingo.fin, DateTime(2026, 10, 25));
    });

    test('Este mes abarca del día 1 al último día del mes', () {
      final octubre = ReportePeriodo.mesActual(ahora: DateTime(2026, 10, 19));

      expect(octubre.inicio, DateTime(2026, 10, 1));
      expect(octubre.fin, DateTime(2026, 10, 31));
      expect(octubre.finExclusivoSql, '2026-11-01');
      expect(octubre.pdfLabel, 'Del 01/10/2026 al 31/10/2026 (Este mes)');

      final febreroBisiesto = ReportePeriodo.mesActual(
        ahora: DateTime(2024, 2, 10),
      );
      expect(febreroBisiesto.inicio, DateTime(2024, 2, 1));
      expect(febreroBisiesto.fin, DateTime(2024, 2, 29));

      final diciembre = ReportePeriodo.mesActual(ahora: DateTime(2026, 12, 15));
      expect(diciembre.inicio, DateTime(2026, 12, 1));
      expect(diciembre.fin, DateTime(2026, 12, 31));
      expect(diciembre.finExclusivoSql, '2027-01-01');
    });

    test('Personalizado normaliza fechas y conserva el rango elegido', () {
      final periodo = ReportePeriodo.personalizado(
        DateTime(2026, 10, 5, 23, 59),
        DateTime(2026, 10, 12, 0, 1),
      );

      expect(periodo.inicio, DateTime(2026, 10, 5));
      expect(periodo.fin, DateTime(2026, 10, 12));
      expect(periodo.inicioSql, '2026-10-05');
      expect(periodo.finExclusivoSql, '2026-10-13');
      expect(periodo.rangoDisplay, '05/10/2026 - 12/10/2026');
      expect(periodo.pdfLabel, 'Del 05/10/2026 al 12/10/2026 (Personalizado)');
      expect(periodo.esUnSoloDia, isFalse);
    });

    test('Personalizado de un solo día y rango invertido', () {
      final unDia = ReportePeriodo.personalizado(
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 19),
      );
      expect(unDia.esUnSoloDia, isTrue);
      expect(unDia.pdfLabel, 'Del 19/10/2026 al 19/10/2026 (Personalizado)');

      expect(
        () => ReportePeriodo.personalizado(
          DateTime(2026, 10, 20),
          DateTime(2026, 10, 19),
        ),
        throwsArgumentError,
      );
    });
  });
}
