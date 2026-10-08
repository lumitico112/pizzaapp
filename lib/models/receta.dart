class RecetaItem {
  final int? id;
  final int varianteId;
  final int insumoId;
  final double cantidad;
  final String unidadMedida;

  // Campos extra para mostrar en UI
  final String? insumoNombre;
  final double? insumoCostoUnidad;
  final String? insumoUnidadBase;
  final double? costoCalculado;

  RecetaItem({
    this.id,
    required this.varianteId,
    required this.insumoId,
    required this.cantidad,
    required this.unidadMedida,
    this.insumoNombre,
    this.insumoCostoUnidad,
    this.insumoUnidadBase,
    this.costoCalculado,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'variante_id': varianteId,
      'insumo_id': insumoId,
      'cantidad': cantidad,
      'unidad_medida': unidadMedida,
    };
  }

  factory RecetaItem.fromMap(Map<String, dynamic> map) {
    return RecetaItem(
      id: map['id'],
      varianteId: map['variante_id'],
      insumoId: map['insumo_id'],
      cantidad: map['cantidad'],
      unidadMedida: map['unidad_medida'],
      insumoNombre: map['insumo_nombre'],
      insumoCostoUnidad: map['insumo_costo_unidad'],
      insumoUnidadBase: map['insumo_unidad_base'],
    );
  }

  RecetaItem copyWith({
    int? id,
    int? varianteId,
    int? insumoId,
    double? cantidad,
    String? unidadMedida,
    String? insumoNombre,
    double? insumoCostoUnidad,
    String? insumoUnidadBase,
    double? costoCalculado,
  }) {
    return RecetaItem(
      id: id ?? this.id,
      varianteId: varianteId ?? this.varianteId,
      insumoId: insumoId ?? this.insumoId,
      cantidad: cantidad ?? this.cantidad,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      insumoNombre: insumoNombre ?? this.insumoNombre,
      insumoCostoUnidad: insumoCostoUnidad ?? this.insumoCostoUnidad,
      insumoUnidadBase: insumoUnidadBase ?? this.insumoUnidadBase,
      costoCalculado: costoCalculado ?? this.costoCalculado,
    );
  }
}
