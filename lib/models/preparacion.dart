class ItemPreparacion {
  final int id;
  final int preparacionId;
  final int varianteId;
  final int cantidadPreparada;
  final String? productoNombre;
  final String? varianteNombre;
  final String? notas;
  final int sobrante;
  final int enviadoMerma;
  final int llevadoManana;

  ItemPreparacion({
    required this.id,
    required this.preparacionId,
    required this.varianteId,
    required this.cantidadPreparada,
    this.productoNombre,
    this.varianteNombre,
    this.notas,
    this.sobrante = 0,
    this.enviadoMerma = 0,
    this.llevadoManana = 0,
  });

  factory ItemPreparacion.fromMap(Map<String, dynamic> map) {
    return ItemPreparacion(
      id: map['id'],
      preparacionId: map['preparacion_id'],
      varianteId: map['variante_id'],
      cantidadPreparada: map['cantidad_preparada'] ?? 0,
      productoNombre: map['producto_nombre'],
      varianteNombre: map['variante_nombre'],
      notas: map['notas'],
      sobrante: map['sobrante'] ?? 0,
      enviadoMerma: map['enviado_merma'] ?? 0,
      llevadoManana: map['llevado_manana'] ?? 0,
    );
  }
}

class Preparacion {
  final int id;
  final String fecha;
  final int? usuarioId;
  final String? nota;
  final List<ItemPreparacion> items;

  Preparacion({
    required this.id,
    required this.fecha,
    this.usuarioId,
    this.nota,
    this.items = const [],
  });

  factory Preparacion.fromMap(Map<String, dynamic> map) {
    return Preparacion(
      id: map['id'],
      fecha: map['fecha'],
      usuarioId: map['usuario_id'],
      nota: map['nota'],
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => ItemPreparacion.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SugerenciaPreparacion {
  final int varianteId;
  final String productoNombre;
  final String varianteNombre;
  final double promedioVentas;
  final double promedioFaltantes;
  final double promedioSobrantes;
  final int sugerenciaFinal;

  SugerenciaPreparacion({
    required this.varianteId,
    required this.productoNombre,
    required this.varianteNombre,
    required this.promedioVentas,
    required this.promedioFaltantes,
    required this.promedioSobrantes,
    required this.sugerenciaFinal,
  });

  factory SugerenciaPreparacion.fromMap(Map<String, dynamic> map) {
    return SugerenciaPreparacion(
      varianteId: map['variante_id'],
      productoNombre: map['producto_nombre'] ?? 'Desconocido',
      varianteNombre: map['variante_nombre'] ?? '',
      promedioVentas: (map['promedioVentas'] ?? map['promedio_diario'] ?? 0.0).toDouble(),
      promedioFaltantes: (map['promedioFaltantes'] ?? map['faltantes'] ?? 0.0).toDouble(),
      promedioSobrantes: (map['promedioSobrantes'] ?? map['sobrantes'] ?? 0.0).toDouble(),
      sugerenciaFinal: (map['sugerenciaFinal'] ?? map['sugerencia'] ?? 0).toInt(),
    );
  }
}

class Transformacion {
  final int? id;
  final int varianteOrigenId;
  final int varianteDestinoId;
  final int? insumoAdicionalId;
  final double? cantidadInsumo;

  Transformacion({
    this.id,
    required this.varianteOrigenId,
    required this.varianteDestinoId,
    this.insumoAdicionalId,
    this.cantidadInsumo,
  });

  factory Transformacion.fromMap(Map<String, dynamic> map) {
    return Transformacion(
      id: map['id'],
      varianteOrigenId: map['variante_origen_id'],
      varianteDestinoId: map['variante_destino_id'],
      insumoAdicionalId: map['insumo_adicional_id'],
      cantidadInsumo: map['cantidad_insumo'] != null ? (map['cantidad_insumo'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'variante_origen_id': varianteOrigenId,
      'variante_destino_id': varianteDestinoId,
      'insumo_adicional_id': insumoAdicionalId,
      'cantidad_insumo': cantidadInsumo,
    };
  }
}
