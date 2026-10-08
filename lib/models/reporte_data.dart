class ProductoVendido {
  final String nombre;
  final int cantidad;
  final double total;

  ProductoVendido({
    required this.nombre,
    required this.cantidad,
    required this.total,
  });
}

class ReporteData {
  final double totalIngresos;
  final double totalGastos;
  final double costoMercaderia;
  final double beneficioNeto;
  final List<ProductoVendido> productosVendidos;

  ReporteData({
    required this.totalIngresos,
    required this.totalGastos,
    required this.costoMercaderia,
    required this.beneficioNeto,
    required this.productosVendidos,
  });
}
