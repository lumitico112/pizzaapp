class PdfHelper {
  static String sanitize(String input) {
    const withDia = 'áéíóúÁÉÍÓÚñÑüÜ';
    const withoutDia = 'aeiouAEIOUnNuU';
    
    String str = input;
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    
    // Quitar caracteres raros que rompen Helvetica
    return str.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }
}
