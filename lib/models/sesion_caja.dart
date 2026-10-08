class SesionCaja {
  final int? id;
  final String fechaApertura;
  final double montoApertura;
  final String estado;
  final String? fechaCierre;
  final double totalEfectivoSistema;
  final double totalYapePlin;
  final double efectivoContado;
  final double diferencia;
  final double totalGastos;
  final String? nota;

  SesionCaja({
    this.id,
    required this.fechaApertura,
    this.montoApertura = 0,
    this.estado = 'abierta',
    this.fechaCierre,
    this.totalEfectivoSistema = 0,
    this.totalYapePlin = 0,
    this.efectivoContado = 0,
    this.diferencia = 0,
    this.totalGastos = 0,
    this.nota,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_apertura': fechaApertura,
      'monto_apertura': montoApertura,
      'estado': estado,
      'fecha_cierre': fechaCierre,
      'total_efectivo_sistema': totalEfectivoSistema,
      'total_yape_plin': totalYapePlin,
      'efectivo_contado': efectivoContado,
      'diferencia': diferencia,
      'total_gastos': totalGastos,
      'nota': nota,
    };
  }

  factory SesionCaja.fromMap(Map<String, dynamic> map) {
    return SesionCaja(
      id: map['id']?.toInt(),
      fechaApertura: map['fecha_apertura'] ?? '',
      montoApertura: map['monto_apertura']?.toDouble() ?? 0.0,
      estado: map['estado'] ?? 'abierta',
      fechaCierre: map['fecha_cierre'],
      totalEfectivoSistema: map['total_efectivo_sistema']?.toDouble() ?? 0.0,
      totalYapePlin: map['total_yape_plin']?.toDouble() ?? 0.0,
      efectivoContado: map['efectivo_contado']?.toDouble() ?? 0.0,
      diferencia: map['diferencia']?.toDouble() ?? 0.0,
      totalGastos: map['total_gastos']?.toDouble() ?? 0.0,
      nota: map['nota'],
    );
  }
}
