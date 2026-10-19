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
  final int insumoContenidoPaquete;
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
    this.insumoContenidoPaquete = 1,
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
      id: map['id'] as int?,
      varianteId: (map['variante_id'] as num).toInt(),
      insumoId: (map['insumo_id'] as num).toInt(),
      cantidad: (map['cantidad'] as num).toDouble(),
      unidadMedida: map['unidad_medida'] as String? ?? 'Unidades',
      insumoNombre: map['insumo_nombre'] as String?,
      insumoCostoUnidad: (map['insumo_costo_unidad'] as num?)?.toDouble(),
      insumoUnidadBase: map['insumo_unidad_base'] as String?,
      insumoContenidoPaquete:
          (map['insumo_contenido_paquete'] as num?)?.toInt() ?? 1,
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
    int? insumoContenidoPaquete,
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
      insumoContenidoPaquete:
          insumoContenidoPaquete ?? this.insumoContenidoPaquete,
      costoCalculado: costoCalculado ?? this.costoCalculado,
    );
  }
}
