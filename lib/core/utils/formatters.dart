import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Devuelve el monto formateado con la moneda del negocio.
  /// Se asume S/ (Soles) por defecto, pero se podria conectar a una configuracion.
  static String format(double amount) {
    // Usamos NumberFormat para garantizar comas en miles y 2 decimales
    final formatter = NumberFormat.currency(
      symbol: 'S/ ', 
      decimalDigits: 2,
      locale: 'es_PE',
    );
    return formatter.format(amount);
  }
}

class DateFormatter {
  /// Formatea un ISO String a dd/MM/yyyy
  static String formatFecha(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }

  /// Formatea un ISO String a dd/MM/yyyy HH:mm
  static String formatFechaHora(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return isoString;
    }
  }
}
