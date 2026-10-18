import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/features/waste/data/repositories/merma_repository.dart';

class DashboardSummary {
  final double ventas;
  final double gastos;
  final double ganancia;
  final int cantidadVentas;
  final int cantidadGastos;
  final List<DashboardMovement> movimientos;
  final List<DashboardProductSales> productos;
  final DateTime actualizacion;
  final int cuentasPendientes;
  final double montoPendiente;

  DashboardSummary({
    this.ventas = 0.0,
    this.gastos = 0.0,
    this.ganancia = 0.0,
    this.cantidadVentas = 0,
    this.cantidadGastos = 0,
    this.movimientos = const [],
    this.productos = const [],
    DateTime? actualizacion,
    this.cuentasPendientes = 0,
    this.montoPendiente = 0.0,
  }) : actualizacion = actualizacion ?? DateTime.now();
}

class DashboardMovement {
  final String tipo;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final String referencia;
  final String? metodoPago;

  const DashboardMovement({
    required this.tipo,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.referencia,
    this.metodoPago,
  });

  bool get esVenta => tipo == 'venta';
}

class DashboardProductSales {
  final String nombre;
  final int cantidad;
  final double total;

  const DashboardProductSales({
    required this.nombre,
    required this.cantidad,
    required this.total,
  });
}

class DashboardService {
  final VentaRepository _ventaRepo;
  final PurchaseRepository _purchaseRepo;
  final MermaRepository _mermaRepo;

  DashboardService(
    this._ventaRepo,
    this._purchaseRepo, [
    MermaRepository? mermaRepo,
  ]) : _mermaRepo = mermaRepo ?? MermaRepository();

  Future<DashboardSummary> obtenerResumenDelDia() async {
    final stats = await _ventaRepo.getResumenHoy();
    final ventasHoy = await _ventaRepo.getMovimientosFinancierosHoy();
    final detalleVentasHoy = await _ventaRepo.getDetallesVentasHoy();
    final gastosHoy = await _purchaseRepo.getGastosHoy();
    final mermasHoy = await _mermaRepo.getMermasValoradasHoy();
    final totalMermas = mermasHoy.fold<double>(
      0,
      (total, row) => total + ((row['monto'] as num?)?.toDouble() ?? 0),
    );

    final cuentas = await _purchaseRepo.getCuentasPorPagar();
    final pendientes = cuentas.where((c) => c['pagado'] == 0).toList();
    final totalDeuda = pendientes.fold(0.0, (sum, c) {
      final total = (c['costo_total'] as num).toDouble();
      final paid = (c['monto_pagado'] as num?)?.toDouble() ?? 0;
      return sum + (total - paid).clamp(0, double.infinity);
    });

    final detallesPorVenta = <int, List<String>>{};
    final productosVendidos = <String, _ProductSalesAccumulator>{};
    for (final row in detalleVentasHoy) {
      final ventaId = (row['venta_id'] as num).toInt();
      final cantidad = (row['cantidad'] as num?)?.toInt() ?? 0;
      final precio = (row['precio_unitario'] as num?)?.toDouble() ?? 0;
      final descuento = (row['descuento'] as num?)?.toDouble() ?? 0;
      final cortesia = (row['es_cortesia'] as num?)?.toInt() == 1;
      final varianteId = (row['variante_id'] as num?)?.toInt();
      final promocionId = (row['promocion_id'] as num?)?.toInt();
      final productoId = (row['producto_id'] as num?)?.toInt();
      final productoNombre = row['producto_nombre']?.toString();
      final varianteNombre = row['nombre_variante']?.toString();
      final promocionNombre = row['promocion_nombre']?.toString();

      final nombre = promocionId != null
          ? 'Promoción: ${promocionNombre?.trim().isNotEmpty == true ? promocionNombre : 'Combo'}'
          : '${productoNombre?.trim().isNotEmpty == true ? productoNombre : 'Producto'}${varianteNombre?.trim().isNotEmpty == true ? ' - $varianteNombre' : ''}';
      final tituloLinea =
          '${cantidad}x $nombre${cortesia ? ' (Cortesía)' : ''}';
      (detallesPorVenta[ventaId] ??= <String>[]).add(tituloLinea);

      final key = promocionId != null
          ? 'promo:$promocionId'
          : varianteId != null
          ? 'variante:$varianteId'
          : 'producto:${productoId ?? nombre}';
      final acumulado = productosVendidos.putIfAbsent(
        key,
        () => _ProductSalesAccumulator(nombre: nombre),
      );
      acumulado.cantidad += cantidad;
      acumulado.total += cortesia
          ? 0.0
          : (precio * cantidad - descuento)
                .clamp(0.0, double.infinity)
                .toDouble();
    }

    final movements = <DashboardMovement>[
      ...ventasHoy.map((row) {
        final id = (row['id'] as num).toInt();
        final idText = id.toString().padLeft(4, '0');
        final payment = row['metodo_pago']?.toString();
        return DashboardMovement(
          tipo: 'venta',
          descripcion: detallesPorVenta[id]?.join(', ') ?? 'Venta #$idText',
          referencia: 'Venta #$idText',
          metodoPago: payment,
          monto: (row['monto'] as num?)?.toDouble() ?? 0,
          fecha: _parseMovementDate(row['fecha']?.toString()),
        );
      }),
      ...gastosHoy.map((row) {
        final id = (row['id'] as num?)?.toInt() ?? 0;
        final categoria = row['categoria']?.toString() ?? 'Gasto';
        return DashboardMovement(
          tipo: 'gasto',
          descripcion: _expenseDescription(row),
          referencia: '$categoria #${id.toString().padLeft(4, '0')}',
          monto: (row['monto'] as num?)?.toDouble() ?? 0,
          fecha: _parseMovementDate(row['created_at']?.toString()),
        );
      }),
      ...mermasHoy.map((row) {
        final id = (row['id'] as num?)?.toInt() ?? 0;
        return DashboardMovement(
          tipo: 'gasto',
          descripcion: 'Merma · ${row['insumo_nombre'] ?? 'Insumo'}',
          referencia: 'Merma #${id.toString().padLeft(4, '0')}',
          monto: (row['monto'] as num?)?.toDouble() ?? 0,
          fecha: _parseMovementDate(row['fecha']?.toString()),
        );
      }),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));

    final productos =
        productosVendidos.values
            .map(
              (item) => DashboardProductSales(
                nombre: item.nombre,
                cantidad: item.cantidad,
                total: item.total,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byQuantity = b.cantidad.compareTo(a.cantidad);
            return byQuantity != 0 ? byQuantity : b.total.compareTo(a.total);
          });

    final gastosTotales = (stats['gastos'] ?? 0.0) + totalMermas;

    return DashboardSummary(
      ventas: stats['ventas'] ?? 0.0,
      gastos: gastosTotales,
      ganancia: (stats['ventas'] ?? 0.0) - gastosTotales,
      cantidadVentas: (stats['cantidad_ventas'] as num?)?.toInt() ?? 0,
      cantidadGastos:
          ((stats['cantidad_gastos'] as num?)?.toInt() ?? 0) + mermasHoy.length,
      movimientos: movements,
      productos: productos,
      actualizacion: DateTime.now(),
      cuentasPendientes: pendientes.length,
      montoPendiente: totalDeuda,
    );
  }

  String _expenseDescription(Map<String, dynamic> row) {
    final item = row['insumo_nombre']?.toString();
    if (item != null && item.trim().isNotEmpty) {
      final quantity = (row['cantidad_compra'] as num?)?.toDouble();
      final unit = row['unidad_medida']?.toString().trim() ?? '';
      final quantityLabel = quantity == null
          ? ''
          : '${quantity == quantity.roundToDouble() ? quantity.toInt() : quantity} $unit'
                .trim();
      return 'Compra: $item${quantityLabel.isEmpty ? '' : ' · $quantityLabel'}';
    }
    final description = row['descripcion']?.toString().trim();
    if (description != null && description.isNotEmpty) return description;
    return row['categoria']?.toString() ?? 'Gasto';
  }

  DateTime _parseMovementDate(String? value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }
}

class _ProductSalesAccumulator {
  final String nombre;
  int cantidad = 0;
  double total = 0;

  _ProductSalesAccumulator({required this.nombre});
}
