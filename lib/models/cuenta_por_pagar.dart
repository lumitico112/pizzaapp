class CuentaPorPagar {
  final int id;
  final String insumoNombre;
  final String fecha;
  final double costoTotal;
  final double montoPagado;
  final int cuotas;
  final double adelanto;
  final int? activoFijoId;
  final String? fechaVencimiento;
  final bool pagado;
  final String? proveedor;
  final String? motivo;
  final String? facturaRuta;
  final String? fechaPago;
  final int? compraOcasionalId;

  CuentaPorPagar({
    required this.id,
    required this.insumoNombre,
    required this.fecha,
    required this.costoTotal,
    this.montoPagado = 0,
    this.cuotas = 1,
    this.adelanto = 0,
    this.activoFijoId,
    this.fechaVencimiento,
    required this.pagado,
    this.proveedor,
    this.motivo,
    this.facturaRuta,
    this.fechaPago,
    this.compraOcasionalId,
  });

  double get saldoPendiente =>
      (costoTotal - montoPagado).clamp(0, double.infinity);

  factory CuentaPorPagar.fromMap(Map<String, dynamic> map) {
    return CuentaPorPagar(
      id: (map['id'] as num).toInt(),
      insumoNombre: map['insumo_nombre'] as String? ?? 'Activo/Insumo',
      fecha: map['fecha'] as String? ?? '',
      costoTotal: (map['costo_total'] as num?)?.toDouble() ?? 0,
      montoPagado: (map['monto_pagado'] as num?)?.toDouble() ?? 0,
      cuotas: (map['cuotas'] as num?)?.toInt() ?? 1,
      adelanto: (map['adelanto'] as num?)?.toDouble() ?? 0,
      activoFijoId: (map['activo_fijo_id'] as num?)?.toInt(),
      fechaVencimiento: map['fecha_vencimiento'] as String?,
      pagado: (map['pagado'] as num?) == 1,
      proveedor:
          map['proveedor'] as String? ?? map['proveedor_nombre'] as String?,
      motivo: map['motivo'] as String?,
      facturaRuta: map['factura_ruta'] as String?,
      fechaPago: map['fecha_pago'] as String?,
      compraOcasionalId: (map['compra_ocasional_id'] as num?)?.toInt(),
    );
  }

  double _money(double value) => (value * 100).roundToDouble() / 100;

  double _montoCuota(int numero) {
    final safeCount = cuotas < 1 ? 1 : cuotas;
    final saldoFinanciado = (costoTotal - adelanto)
        .clamp(0, costoTotal)
        .toDouble();
    if (safeCount == 1) return saldoFinanciado;
    final base = _money(saldoFinanciado / safeCount);
    return numero == safeCount
        ? _money(saldoFinanciado - base * (safeCount - 1))
        : base;
  }

  int get cuotaSiguiente {
    final saldoFinanciado = (costoTotal - adelanto)
        .clamp(0, costoTotal)
        .toDouble();
    var pagadoEnCuotas = (montoPagado - adelanto)
        .clamp(0, saldoFinanciado)
        .toDouble();
    for (var numero = 1; numero <= cuotas; numero++) {
      final importeCuota = _montoCuota(numero);
      if (pagadoEnCuotas + 0.001 < importeCuota) return numero;
      pagadoEnCuotas -= importeCuota;
    }
    return cuotas;
  }

  double get saldoCuotaSiguiente {
    final saldoFinanciado = (costoTotal - adelanto)
        .clamp(0, costoTotal)
        .toDouble();
    var pagadoEnCuotas = (montoPagado - adelanto)
        .clamp(0, saldoFinanciado)
        .toDouble();
    for (var numero = 1; numero <= cuotas; numero++) {
      final importeCuota = _montoCuota(numero);
      if (pagadoEnCuotas + 0.001 < importeCuota) {
        return _money(
          (importeCuota - pagadoEnCuotas).clamp(0, importeCuota).toDouble(),
        );
      }
      pagadoEnCuotas -= importeCuota;
    }
    return 0;
  }
}
