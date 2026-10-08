class MovimientoCaja {
  final int? id;
  final int sesionCajaId;
  final String tipo; // 'entrada', 'salida', 'venta', 'compra', 'apertura'
  final String? metodoPago; // 'efectivo', 'yape', 'plin'
  final double monto;
  final String? descripcion;
  final String fecha;

  MovimientoCaja({
    this.id,
    required this.sesionCajaId,
    required this.tipo,
    this.metodoPago,
    required this.monto,
    this.descripcion,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sesion_caja_id': sesionCajaId,
      'tipo': tipo,
      'metodo_pago': metodoPago,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha,
    };
  }

  factory MovimientoCaja.fromMap(Map<String, dynamic> map) {
    return MovimientoCaja(
      id: map['id']?.toInt(),
      sesionCajaId: map['sesion_caja_id']?.toInt() ?? 0,
      tipo: map['tipo'] ?? '',
      metodoPago: map['metodo_pago'],
      monto: map['monto']?.toDouble() ?? 0.0,
      descripcion: map['descripcion'],
      fecha: map['fecha'] ?? '',
    );
  }
}
