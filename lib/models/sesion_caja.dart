class SesionCaja {
  final int? id;
  final String fechaApertura;
  final double montoApertura;
  final double transferenciasApertura;
  final String estado;
  final String? fechaCierre;
  final double totalEfectivoSistema;
  final double totalYapePlin;
  final double efectivoContado;
  final double diferencia;
  final double totalGastos;
  final double totalGastosCiclo;
  final String? nota;
  final double transferenciasContadas;
  final double diferenciaEfectivo;
  final double diferenciaTransferencia;
  final double totalEsperado;
  final int? usuarioAperturaId;
  final int? usuarioCierreId;

  SesionCaja({
    this.id,
    required this.fechaApertura,
    this.montoApertura = 0,
    this.transferenciasApertura = 0,
    this.estado = 'abierta',
    this.fechaCierre,
    this.totalEfectivoSistema = 0,
    this.totalYapePlin = 0,
    this.efectivoContado = 0,
    this.diferencia = 0,
    this.totalGastos = 0,
    this.totalGastosCiclo = 0,
    this.nota,
    this.transferenciasContadas = 0,
    this.diferenciaEfectivo = 0,
    this.diferenciaTransferencia = 0,
    this.totalEsperado = 0,
    this.usuarioAperturaId,
    this.usuarioCierreId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_apertura': fechaApertura,
      'monto_apertura': montoApertura,
      'transferencias_apertura': transferenciasApertura,
      'estado': estado,
      'fecha_cierre': fechaCierre,
      'total_efectivo_sistema': totalEfectivoSistema,
      'total_yape_plin': totalYapePlin,
      'efectivo_contado': efectivoContado,
      'diferencia': diferencia,
      'total_gastos': totalGastos,
      'total_gastos_ciclo': totalGastosCiclo,
      'nota': nota,
      'transferencias_contadas': transferenciasContadas,
      'diferencia_efectivo': diferenciaEfectivo,
      'diferencia_transferencia': diferenciaTransferencia,
      'total_esperado': totalEsperado,
      'usuario_apertura_id': usuarioAperturaId,
      'usuario_cierre_id': usuarioCierreId,
    };
  }

  factory SesionCaja.fromMap(Map<String, dynamic> map) {
    return SesionCaja(
      id: map['id']?.toInt(),
      fechaApertura: map['fecha_apertura'] ?? '',
      montoApertura: map['monto_apertura']?.toDouble() ?? 0.0,
      transferenciasApertura: map['transferencias_apertura']?.toDouble() ?? 0.0,
      estado: map['estado'] ?? 'abierta',
      fechaCierre: map['fecha_cierre'],
      totalEfectivoSistema: map['total_efectivo_sistema']?.toDouble() ?? 0.0,
      totalYapePlin: map['total_yape_plin']?.toDouble() ?? 0.0,
      efectivoContado: map['efectivo_contado']?.toDouble() ?? 0.0,
      diferencia: map['diferencia']?.toDouble() ?? 0.0,
      totalGastos: map['total_gastos']?.toDouble() ?? 0.0,
      totalGastosCiclo: map['total_gastos_ciclo']?.toDouble() ?? 0.0,
      nota: map['nota'],
      transferenciasContadas: map['transferencias_contadas']?.toDouble() ?? 0.0,
      diferenciaEfectivo: map['diferencia_efectivo']?.toDouble() ?? 0.0,
      diferenciaTransferencia:
          map['diferencia_transferencia']?.toDouble() ?? 0.0,
      totalEsperado: map['total_esperado']?.toDouble() ?? 0.0,
      usuarioAperturaId: map['usuario_apertura_id']?.toInt(),
      usuarioCierreId: map['usuario_cierre_id']?.toInt(),
    );
  }
}
