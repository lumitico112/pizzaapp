class Promocion {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String? imagenRuta;
  final double precio;
  final String? diasSemana; // ej. "1,2,3"
  final String? horaInicio; // "18:00"
  final String? horaFin; // "22:00"
  final int activa;
  final List<PromocionItem> items;

  Promocion({
    this.id,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.imagenRuta,
    this.diasSemana,
    this.horaInicio,
    this.horaFin,
    this.activa = 1,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen_ruta': imagenRuta,
      'tipo': 'combo',
      'valor_descuento': 0,
      'precio': precio,
      'dias_semana': diasSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'activa': activa,
    };
  }

  factory Promocion.fromMap(
    Map<String, dynamic> map, [
    List<PromocionItem>? items,
  ]) {
    return Promocion(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      imagenRuta: map['imagen_ruta'],
      precio: map['precio']?.toDouble() ?? 0.0,
      diasSemana: map['dias_semana'],
      horaInicio: map['hora_inicio'],
      horaFin: map['hora_fin'],
      activa: map['activa'] ?? 1,
      items: items ?? [],
    );
  }
}

class PromocionItem {
  final int? id;
  final int promocionId;
  final int? varianteId;
  final int? insumoId;
  final int cantidad;

  PromocionItem({
    this.id,
    required this.promocionId,
    this.varianteId,
    this.insumoId,
    this.cantidad = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'promocion_id': promocionId,
      'variante_id': varianteId,
      'insumo_id': insumoId,
      'cantidad': cantidad,
    };
  }

  factory PromocionItem.fromMap(Map<String, dynamic> map) {
    return PromocionItem(
      id: map['id'],
      promocionId: map['promocion_id'],
      varianteId: map['variante_id'],
      insumoId: map['insumo_id'],
      cantidad: map['cantidad'] ?? 1,
    );
  }
}
