class Venta {
  final int? id;
  final String fecha;
  final String hora;
  final int? usuarioId;
  final String metodoPago; // efectivo, yape, plin, tarjeta, mixto
  final double? montoRecibido;
  final double? vuelto;
  final double subtotal;
  final double descuento;
  final double total;
  final int anulada;
  final String? nota;
  final int? promocionId;

  Venta({
    this.id,
    required this.fecha,
    required this.hora,
    this.usuarioId,
    required this.metodoPago,
    this.montoRecibido,
    this.vuelto,
    required this.subtotal,
    this.descuento = 0.0,
    required this.total,
    this.anulada = 0,
    this.nota,
    this.promocionId,
  });

  Map<String, dynamic> toMap() {
    String mPago = metodoPago.toLowerCase().trim();
    if (mPago == 'cortesia' || mPago == 'cortesía') {
      mPago = 'efectivo';
    } else if (mPago == 'yape/plin') {
      mPago = 'yape';
    } else if (mPago == 'mixto') {
      throw ArgumentError(
        'El método de pago mixto se encuentra temporalmente deshabilitado.',
      );
    } else if (!const ['efectivo', 'yape', 'plin', 'tarjeta', 'transferencia'].contains(mPago)) {
      mPago = 'efectivo';
    }

    return {
      'id': id,
      'fecha': fecha,
      'hora': hora,
      'usuario_id': usuarioId,
      'metodo_pago': mPago,
      'monto_recibido': montoRecibido,
      'vuelto': vuelto,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'anulada': anulada,
      'nota': nota,
      'promocion_id': promocionId,
    };
  }
}

class DetalleVenta {
  final int? id;
  final int ventaId;
  final int? varianteId;
  final int? promocionId;
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final bool esCortesia;

  DetalleVenta({
    this.id,
    required this.ventaId,
    this.varianteId,
    this.promocionId,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0.0,
    this.esCortesia = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'venta_id': ventaId,
    'variante_id': varianteId,
    'promocion_id': promocionId,
    'cantidad': cantidad,
    'precio_unitario': precioUnitario,
    'descuento': descuento,
    'es_cortesia': esCortesia ? 1 : 0,
  };
}
