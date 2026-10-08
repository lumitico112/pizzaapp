class ConversionesHelper {
  static double convertir(double cantidad, String unidadOrigen, String unidadDestino) {
    if (unidadOrigen == unidadDestino) return cantidad;

    // Normalizar a minúsculas
    String origen = unidadOrigen.toLowerCase();
    String destino = unidadDestino.toLowerCase();

    if (origen == destino) return cantidad;

    // Kg a g
    if ((origen == 'kg' || origen == 'kilogramos') && (destino == 'g' || destino == 'gr' || destino == 'gramos')) {
      return cantidad * 1000;
    }
    // g a Kg
    if ((origen == 'g' || origen == 'gr' || origen == 'gramos') && (destino == 'kg' || destino == 'kilogramos')) {
      return cantidad / 1000;
    }

    // Litros a ml
    if ((origen == 'l' || origen == 'litros' || origen == 'litro') && (destino == 'ml' || destino == 'mililitros')) {
      return cantidad * 1000;
    }
    // ml a Litros
    if ((origen == 'ml' || origen == 'mililitros') && (destino == 'l' || destino == 'litros' || destino == 'litro')) {
      return cantidad / 1000;
    }

    // Unidades (ej. un a un)
    if ((origen == 'un' || origen == 'unidad' || origen == 'unidades') && (destino == 'un' || destino == 'unidad' || destino == 'unidades')) {
      return cantidad;
    }

    // No compatibles, retornar 0
    return 0.0;
  }
}
