class CuentaPorPagar {
  final int id;
  final String insumoNombre;
  final String fecha;
  final double costoTotal;
  final double montoPagado;
  final bool pagado;
  final String? proveedor;
  final String? motivo;
  final String? facturaRuta;
  final String? fechaPago;

  CuentaPorPagar({
    required this.id,
    required this.insumoNombre,
    required this.fecha,
    required this.costoTotal,
    this.montoPagado = 0.0,
    required this.pagado,
    this.proveedor,
    this.motivo,
    this.facturaRuta,
    this.fechaPago,
  });

  factory CuentaPorPagar.fromMap(Map<String, dynamic> map) {
    return CuentaPorPagar(
      id: map['id'],
      insumoNombre: map['insumo_nombre'] ?? 'Activo/Insumo',
      fecha: map['fecha'],
      costoTotal: (map['costo_total'] ?? 0.0).toDouble(),
      montoPagado: (map['monto_pagado'] ?? 0.0).toDouble(),
      pagado: (map['pagado'] ?? 0) == 1,
      proveedor: map['proveedor'],
      motivo: map['motivo'],
      facturaRuta: map['factura_ruta'],
      fechaPago: map['fecha_pago'],
    );
  }
}
