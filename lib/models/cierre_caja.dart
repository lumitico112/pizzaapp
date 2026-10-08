class CierreCaja {
  final int? id;
  final String fecha;
  final int? usuarioId;
  final double totalEfectivoSistema;
  final double totalTransferenciaSistema;
  final double efectivoContado;
  final double transferenciasContadas;
  final double diferenciaEfectivo;
  final double diferenciaTransferencia;
  final String? nota;
  final String? cerradoEn;

  CierreCaja({
    this.id,
    required this.fecha,
    this.usuarioId,
    required this.totalEfectivoSistema,
    required this.totalTransferenciaSistema,
    required this.efectivoContado,
    required this.transferenciasContadas,
    required this.diferenciaEfectivo,
    required this.diferenciaTransferencia,
    this.nota,
    this.cerradoEn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'usuario_id': usuarioId,
      'total_efectivo_sistema': totalEfectivoSistema,
      'total_transferencia_sistema': totalTransferenciaSistema,
      'efectivo_contado': efectivoContado,
      'transferencias_contadas': transferenciasContadas,
      'diferencia_efectivo': diferenciaEfectivo,
      'diferencia_transferencia': diferenciaTransferencia,
      'nota': nota,
      'cerrado_en': cerradoEn,
    };
  }

  factory CierreCaja.fromMap(Map<String, dynamic> map) {
    return CierreCaja(
      id: map['id'],
      fecha: map['fecha'],
      usuarioId: map['usuario_id'],
      totalEfectivoSistema: (map['total_efectivo_sistema'] ?? 0.0).toDouble(),
      totalTransferenciaSistema: (map['total_transferencia_sistema'] ?? 0.0).toDouble(),
      efectivoContado: (map['efectivo_contado'] ?? 0.0).toDouble(),
      transferenciasContadas: (map['transferencias_contadas'] ?? 0.0).toDouble(),
      diferenciaEfectivo: (map['diferencia_efectivo'] ?? 0.0).toDouble(),
      diferenciaTransferencia: (map['diferencia_transferencia'] ?? 0.0).toDouble(),
      nota: map['nota'],
      cerradoEn: map['cerrado_en'],
    );
  }
}
