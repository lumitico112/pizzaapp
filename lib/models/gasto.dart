class Gasto {
  final int? id;
  final String fecha;
  final String categoria;
  final String? descripcion;
  final double monto;
  final String? fotoReciboRuta;

  Gasto({
    this.id,
    required this.fecha,
    required this.categoria,
    this.descripcion,
    required this.monto,
    this.fotoReciboRuta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'categoria': categoria,
      'descripcion': descripcion,
      'monto': monto,
      'foto_recibo_ruta': fotoReciboRuta,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'],
      fecha: map['fecha'],
      categoria: map['categoria'],
      descripcion: map['descripcion'],
      monto: (map['monto'] ?? 0.0).toDouble(),
      fotoReciboRuta: map['foto_recibo_ruta'],
    );
  }
}
