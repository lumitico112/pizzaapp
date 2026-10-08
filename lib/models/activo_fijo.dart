class ActivoFijo {
  final int? id;
  final String nombre;
  final String? categoria;
  final double costo;
  final String? fechaAdquisicion;
  final String estado; // 'En uso', 'En reparación', 'Fuera de servicio'
  final String? observaciones;
  final String? fotoRuta;
  final int activo;
  
  // Nuevos campos que faltaban en toMap/fromMap
  final String condicion; // 'Comprado', 'Alquilado', 'Prestado', 'Regalado'
  final String metodoPago; // 'Contado', 'Crédito'
  final int cuotas;
  final int cantidad;
  final String? frecuenciaAlquiler; // 'Diario', 'Mensual', 'Anual'

  ActivoFijo({
    this.id,
    required this.nombre,
    this.categoria,
    this.costo = 0.0,
    this.fechaAdquisicion,
    this.estado = 'En uso',
    this.observaciones,
    this.fotoRuta,
    this.activo = 1,
    this.condicion = 'Comprado',
    this.metodoPago = 'Contado',
    this.cuotas = 1,
    this.cantidad = 1,
    this.frecuenciaAlquiler,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'costo': costo,
        'fecha_adquisicion': fechaAdquisicion,
        'estado': estado,
        'observaciones': observaciones,
        'foto_ruta': fotoRuta,
        'activo': activo,
        'condicion': condicion,
        'metodo_pago': metodoPago,
        'cuotas': cuotas,
        'cantidad': cantidad,
        'frecuencia_alquiler': frecuenciaAlquiler,
      };

  factory ActivoFijo.fromMap(Map<String, dynamic> map) {
    // Normalizar estados antiguos a los nuevos
    String estadoDB = map['estado'] ?? 'En uso';
    if (['Nuevo', 'Bueno', 'Regular', 'Malo'].contains(estadoDB)) estadoDB = 'En uso';
    if (estadoDB == 'En reparacin' || estadoDB == 'En reparacion') estadoDB = 'En reparación';

    return ActivoFijo(
      id: map['id'],
      nombre: map['nombre'],
      categoria: map['categoria'],
      costo: (map['costo'] ?? 0.0).toDouble(),
      fechaAdquisicion: map['fecha_adquisicion'],
      estado: estadoDB,
      observaciones: map['observaciones'],
      fotoRuta: map['foto_ruta'],
      activo: map['activo'] ?? 1,
      condicion: map['condicion'] ?? 'Comprado',
      metodoPago: map['metodo_pago'] ?? 'Contado',
      cuotas: map['cuotas'] ?? 1,
      cantidad: map['cantidad'] ?? 1,
      frecuenciaAlquiler: map['frecuencia_alquiler'],
    );
  }
}
