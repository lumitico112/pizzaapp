class Promocion {
  final int? id;
  final String nombre;
  final double precio;
  final String? diasSemana; // ej. "1,2,3"
  final String? horaInicio; // "18:00"
  final String? horaFin;    // "22:00"
  final int activa;
  final List<PromocionItem> items;

  Promocion({
    this.id,
    required this.nombre,
    required this.precio,
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
      'precio': precio,
      'dias_semana': diasSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'activa': activa,
    };
  }

  factory Promocion.fromMap(Map<String, dynamic> map, [List<PromocionItem>? items]) {
    return Promocion(
      id: map['id'],
      nombre: map['nombre'],
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
  final int varianteId;
  final int cantidad;

  PromocionItem({
    this.id,
    required this.promocionId,
    required this.varianteId,
    this.cantidad = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'promocion_id': promocionId,
      'variante_id': varianteId,
      'cantidad': cantidad,
    };
  }

  factory PromocionItem.fromMap(Map<String, dynamic> map) {
    return PromocionItem(
      id: map['id'],
      promocionId: map['promocion_id'],
      varianteId: map['variante_id'],
      cantidad: map['cantidad'] ?? 1,
    );
  }
}
