class Merma {
  final int? id;
  final String fecha;
  final String tipo; // quemado, vencido, dañado, otro
  final String? descripcion;
  final int? insumoId;
  final int? varianteId;
  final double cantidad;
  final String? fotoRuta;

  // Campos relacionales para la UI
  final String? insumoNombre;
  final String? varianteNombre;

  Merma({
    this.id,
    required this.fecha,
    required this.tipo,
    this.descripcion,
    this.insumoId,
    this.varianteId,
    required this.cantidad,
    this.fotoRuta,
    this.insumoNombre,
    this.varianteNombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'tipo': tipo,
      'descripcion': descripcion,
      'insumo_id': insumoId,
      'variante_id': varianteId,
      'cantidad': cantidad,
      'foto_ruta': fotoRuta,
    };
  }

  factory Merma.fromMap(Map<String, dynamic> map) {
    return Merma(
      id: map['id'],
      fecha: map['fecha'],
      tipo: map['tipo'],
      descripcion: map['descripcion'],
      insumoId: map['insumo_id'],
      varianteId: map['variante_id'],
      cantidad: (map['cantidad'] ?? 0.0).toDouble(),
      fotoRuta: map['foto_ruta'],
      insumoNombre: map['insumo_nombre'],
      varianteNombre: map['variante_nombre'],
    );
  }
}
