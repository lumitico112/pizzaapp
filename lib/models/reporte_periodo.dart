import 'package:intl/intl.dart';

/// Periodo inclusivo usado por el módulo de reportes.
///
/// Centraliza el cálculo de fechas para que la pantalla, la consulta SQL y el
/// PDF usen exactamente el mismo rango. Las fechas se normalizan a medianoche
/// para evitar diferencias por hora.
class ReportePeriodo {
  final String etiqueta;
  final DateTime inicio;
  final DateTime fin;

  ReportePeriodo._({
    required this.etiqueta,
    required DateTime inicio,
    required DateTime fin,
  }) : inicio = _soloFecha(inicio),
       fin = _soloFecha(fin) {
    if (this.fin.isBefore(this.inicio)) {
      throw ArgumentError.value(
        fin,
        'fin',
        'La fecha final no puede ser anterior a la fecha inicial.',
      );
    }
  }

  /// Día actual.
  factory ReportePeriodo.hoy({DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    return ReportePeriodo._(etiqueta: 'Hoy', inicio: hoy, fin: hoy);
  }

  /// Día anterior al actual.
  factory ReportePeriodo.ayer({DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);
    return ReportePeriodo._(etiqueta: 'Ayer', inicio: ayer, fin: ayer);
  }

  /// Semana en curso: desde el lunes hasta el día actual.
  factory ReportePeriodo.semanaActual({DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    final lunes = DateTime(hoy.year, hoy.month, hoy.day - (hoy.weekday - 1));
    return ReportePeriodo._(etiqueta: 'Esta semana', inicio: lunes, fin: hoy);
  }

  /// Mes calendario actual: desde el día 1 hasta el último día del mes.
  factory ReportePeriodo.mesActual({DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    final inicio = DateTime(hoy.year, hoy.month, 1);
    final fin = DateTime(hoy.year, hoy.month + 1, 0);
    return ReportePeriodo._(etiqueta: 'Este mes', inicio: inicio, fin: fin);
  }

  /// Rango elegido por el usuario.
  factory ReportePeriodo.personalizado(DateTime inicio, DateTime fin) {
    return ReportePeriodo._(
      etiqueta: 'Personalizado',
      inicio: inicio,
      fin: fin,
    );
  }

  /// Fecha inicial en el formato usado por SQLite (`yyyy-MM-dd`).
  String get inicioSql => _sql(inicio);

  /// Fecha final inclusiva en el formato usado por SQLite (`yyyy-MM-dd`).
  String get finSql => _sql(fin);

  /// Siguiente día al final del periodo.
  ///
  /// Se usa para consultar con `fecha < finExclusivoSql` y cubrir tanto fechas
  /// puras (`yyyy-MM-dd`) como fechas con hora (`yyyy-MM-dd HH:mm:ss`).
  String get finExclusivoSql => _sql(_siguienteDia(fin));

  String get inicioDisplay => _display(inicio);

  String get finDisplay => _display(fin);

  /// Texto corto para la pantalla: `dd/MM/yyyy - dd/MM/yyyy`.
  String get rangoDisplay => '$inicioDisplay - $finDisplay';

  /// Texto explícito para el PDF: `Del dd/MM/yyyy al dd/MM/yyyy (Etiqueta)`.
  String get pdfLabel => 'Del $inicioDisplay al $finDisplay ($etiqueta)';

  bool get esUnSoloDia => inicio.isAtSameMomentAs(fin);

  static DateTime _soloFecha(DateTime valor) {
    return DateTime(valor.year, valor.month, valor.day);
  }

  static DateTime _siguienteDia(DateTime valor) {
    return DateTime(valor.year, valor.month, valor.day + 1);
  }

  static String _sql(DateTime valor) {
    return DateFormat('yyyy-MM-dd').format(valor);
  }

  static String _display(DateTime valor) {
    return DateFormat('dd/MM/yyyy').format(valor);
  }
}
