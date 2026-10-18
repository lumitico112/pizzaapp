import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Devuelve el monto formateado con la moneda del negocio.
  /// Se asume S/ (Soles) por defecto, pero se podria conectar a una configuracion.
  static String format(double amount) {
    // Especificamos el símbolo como prefijo; NumberFormat.currency adapta
    // la posición a la localidad y algunas configuraciones lo colocan detrás.
    final formatter = NumberFormat('#,##0.00;−#,##0.00', 'en_US');
    return 'S/. ${formatter.format(amount)}';
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
