class ConsumoEstimado {
  final int? id;
  final int varianteId;
  final int insumoId;
  final double cantidadEstimada;

  ConsumoEstimado({
    this.id,
    required this.varianteId,
    required this.insumoId,
    required this.cantidadEstimada,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'variante_id': varianteId,
        'insumo_id': insumoId,
        'cantidad_estimada': cantidadEstimada,
      };

  factory ConsumoEstimado.fromMap(Map<String, dynamic> map) => ConsumoEstimado(
        id: map['id'],
        varianteId: map['variante_id'],
        insumoId: map['insumo_id'],
        cantidadEstimada: (map['cantidad_estimada'] ?? 0.0).toDouble(),
      );
}
