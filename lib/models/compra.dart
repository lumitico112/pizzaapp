class Compra {
  final int id;
  final String fecha;
  final String insumoNombre;
  final double cantidad;
  final String? unidadMedida;
  final double costoUnitario;
  final String motivo;
  final String? facturaRuta;
  final bool? esPorPagar;
  final String? proveedor;
  final int? proveedorId;
  final int? insumoId;
  final int? movimientoId;
  final int? gastoId;
  final int? cuentaId;
  final String? metodoPago;
  final double? adelanto;
  final int? cuotas;

  Compra({
    required this.id,
    required this.fecha,
    required this.insumoNombre,
    required this.cantidad,
    this.unidadMedida,
    required this.costoUnitario,
    required this.motivo,
    this.facturaRuta,
    this.esPorPagar,
    this.proveedor,
    this.proveedorId,
    this.insumoId,
    this.movimientoId,
    this.gastoId,
    this.cuentaId,
    this.metodoPago,
    this.adelanto,
    this.cuotas,
  });

  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      id: map['id'],
      fecha: map['fecha'],
      insumoNombre: map['insumo_nombre'] ?? 'Desconocido',
      cantidad: (map['cantidad_ajuste'] ?? 0.0).toDouble(),
      unidadMedida: map['unidad_medida'],
      costoUnitario: (map['costo_unitario'] ?? 0.0).toDouble(),
      motivo: map['motivo'] ?? '',
      facturaRuta: map['factura_ruta'],
      esPorPagar: map.containsKey('es_por_pagar')
          ? map['es_por_pagar'] == 1
          : null,
      proveedor: map['proveedor'],
      proveedorId: map['proveedor_id'] as int?,
      insumoId: map['insumo_id'] as int?,
      movimientoId: map['movimiento_id'] as int? ?? map['id'] as int?,
      gastoId: map['gasto_id'] as int?,
      cuentaId: map['cuenta_id'] as int?,
      metodoPago: map['metodo_pago'] as String?,
      adelanto: (map['adelanto'] as num?)?.toDouble(),
      cuotas: (map['cuotas'] as num?)?.toInt(),
    );
  }
}
