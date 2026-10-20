/// Cabecera de una compra ocasional: un egreso que no crea ni modifica stock.
class CompraOcasional {
  final int? id;
  final String fecha;
  final String descripcion;
  final double cantidad;
  final String? unidadMedida;
  final double costoTotal;
  final String categoria;
  final String? proveedor;
  final int? proveedorId;
  final String? facturaRuta;
  final bool esPorPagar;
  final double adelanto;
  final int cuotas;
  final String metodoPago;
  final int? usuarioId;
  final String? createdAt;

  const CompraOcasional({
    this.id,
    required this.fecha,
    required this.descripcion,
    required this.cantidad,
    this.unidadMedida,
    required this.costoTotal,
    required this.categoria,
    this.proveedor,
    this.proveedorId,
    this.facturaRuta,
    this.esPorPagar = false,
    this.adelanto = 0,
    this.cuotas = 1,
    this.metodoPago = 'efectivo',
    this.usuarioId,
    this.createdAt,
  });

  factory CompraOcasional.fromMap(Map<String, dynamic> map) {
    return CompraOcasional(
      id: (map['id'] as num?)?.toInt(),
      fecha: map['fecha'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0,
      unidadMedida: map['unidad_medida'] as String?,
      costoTotal: (map['costo_total'] as num?)?.toDouble() ?? 0,
      categoria: map['categoria'] as String? ?? '',
      proveedor: map['proveedor'] as String?,
      proveedorId: (map['proveedor_id'] as num?)?.toInt(),
      facturaRuta: map['factura_ruta'] as String?,
      esPorPagar: ((map['es_por_pagar'] as num?)?.toInt() ?? 0) == 1,
      adelanto: (map['adelanto'] as num?)?.toDouble() ?? 0,
      cuotas: (map['cuotas'] as num?)?.toInt() ?? 1,
      metodoPago: map['metodo_pago'] as String? ?? 'efectivo',
      usuarioId: (map['usuario_id'] as num?)?.toInt(),
      createdAt: map['created_at'] as String?,
    );
  }

  CompraOcasional copyWith({int? id, int? usuarioId}) {
    return CompraOcasional(
      id: id ?? this.id,
      fecha: fecha,
      descripcion: descripcion,
      cantidad: cantidad,
      unidadMedida: unidadMedida,
      costoTotal: costoTotal,
      categoria: categoria,
      proveedor: proveedor,
      proveedorId: proveedorId,
      facturaRuta: facturaRuta,
      esPorPagar: esPorPagar,
      adelanto: adelanto,
      cuotas: cuotas,
      metodoPago: metodoPago,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt,
    );
  }
}
