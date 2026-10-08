class Insumo {
  final int? id;
  final String nombre;
  final String tipoInsumo; // 'ingrediente', 'empaquíe', 'vajilla', 'bebida_cortesia', 'limpieza', 'utensilio_consumible'
  final String unidadMedida; // 'Kg', 'gr', 'Litros', 'ml', 'Unidades'
  final int contenidoPaquete;
  final double rendimientoPorUnidad;
  final double costoPorUnidad;
  final double stockActual;
  final double stockMinimo;
  final String? fotoRuta;
  final int activo;

  Insumo({
    this.id,
    required this.nombre,
    required this.tipoInsumo,
    required this.unidadMedida,
    this.contenidoPaquete = 1,
    this.rendimientoPorUnidad = 1.0,
    this.costoPorUnidad = 0.0,
    this.stockActual = 0.0,
    this.stockMinimo = 0.0,
    this.fotoRuta,
    this.activo = 1,
  });

  Insumo copyWith({
    int? id,
    String? nombre,
    String? tipoInsumo,
    String? unidadMedida,
    int? contenidoPaquete,
    double? rendimientoPorUnidad,
    double? costoPorUnidad,
    double? stockActual,
    double? stockMinimo,
    String? fotoRuta,
    int? activo,
  }) {
    return Insumo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoInsumo: tipoInsumo ?? this.tipoInsumo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      contenidoPaquete: contenidoPaquete ?? this.contenidoPaquete,
      rendimientoPorUnidad: rendimientoPorUnidad ?? this.rendimientoPorUnidad,
      costoPorUnidad: costoPorUnidad ?? this.costoPorUnidad,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      fotoRuta: fotoRuta ?? this.fotoRuta,
      activo: activo ?? this.activo,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'tipo_insumo': tipoInsumo,
        'unidad_medida': unidadMedida,
        'contenido_paquete': contenidoPaquete,
        'rendimiento_por_unidad': rendimientoPorUnidad,
        'costo_por_unidad': costoPorUnidad,
        'stock_actual': stockActual,
        'stock_minimo': stockMinimo,
        'foto_ruta': fotoRuta,
        'activo': activo,
      };

  factory Insumo.fromMap(Map<String, dynamic> map) => Insumo(
        id: map['id'],
        nombre: map['nombre'],
        tipoInsumo: map['tipo_insumo'],
        unidadMedida: map['unidad_medida'],
        contenidoPaquete: (map['contenido_paquete'] ?? 1) as int,
        rendimientoPorUnidad: (map['rendimiento_por_unidad'] ?? 1.0).toDouble(),
        costoPorUnidad: (map['costo_por_unidad'] ?? 0.0).toDouble(),
        stockActual: (map['stock_actual'] ?? 0.0).toDouble(),
        stockMinimo: (map['stock_minimo'] ?? 0.0).toDouble(),
        fotoRuta: map['foto_ruta'],
        activo: map['activo'] ?? 1,
      );
}
