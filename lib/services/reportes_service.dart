import 'package:pizzaapp/features/inventory/domain/services/unit_converter.dart';
import 'package:pizzaapp/features/reporting/application/reportes_pdf.dart';
import 'package:pizzaapp/features/reporting/data/repositories/reportes_repository.dart';
import 'package:pizzaapp/models/reporte_data.dart';
import 'package:pizzaapp/models/reporte_periodo.dart';

/// Orquestador de reportes: pide los datos al repositorio, aplica la lógica
/// RN-05 (COGS por receta activa con respaldo manual) y delega la construcción
/// del PDF a `ReportesPdf` (H-04c).
class ReportesService {
  final ReportesRepository _repository;

  ReportesService({ReportesRepository? repository})
    : _repository = repository ?? ReportesRepository();

  Future<ReporteData> getReporteGlobal(ReportePeriodo periodo) async {
    final fechaInicio = periodo.inicioSql;
    final fechaFinExclusiva = periodo.finExclusivoSql;

    // Total Ingresos (Ventas no anuladas)
    final totalIngresos = await _repository.getTotalIngresos(
      fechaInicio,
      fechaFinExclusiva,
    );

    // Total Gastos (Desde la tabla Gastos para incluir compras, activos, pagos CxP y salidas manuales)
    final totalGastos = await _repository.getTotalGastos(
      fechaInicio,
      fechaFinExclusiva,
    );

    // Costo de Mercaderia Vendida (COGS) segun RN-05 / BR-REP-02:
    // Prioriza el costo calculado automaticamente por la receta activa de la variante
    // (Recetas + Insumos con conversion de unidades).
    // Solo cuando una variante no tenga receta configurada se utiliza costo_estimado_manual como respaldo.

    // 1. Obtener todas las recetas e insumos asociados
    final recetasRows = await _repository.getRecetasConInsumos();

    final Map<int, double> costoRecetaPorVariante = {};
    for (final row in recetasRows) {
      final vId = (row['variante_id'] as num).toInt();
      final cant = (row['receta_cantidad'] as num).toDouble();
      final rUnidad = row['receta_unidad'] as String? ?? 'unidad';
      final iUnidad = row['insumo_unidad'] as String? ?? 'unidad';
      final costoUnidad = (row['insumo_costo'] as num?)?.toDouble() ?? 0.0;
      final packContent = (row['contenido_paquete'] as num?)?.toInt() ?? 1;

      double cantidadConvertida = cant;
      try {
        cantidadConvertida = UnitConverter.convert(
          cant,
          rUnidad,
          iUnidad,
          packageContent: packContent,
        );
      } catch (_) {
        // En caso de discrepancia de unidad no convertible, mantener cantidad base
      }
      final costoItem = cantidadConvertida * costoUnidad;
      costoRecetaPorVariante[vId] =
          (costoRecetaPorVariante[vId] ?? 0.0) + costoItem;
    }

    // 2. Precalcular costos de promociones si existen
    final promoItemsRows = await _repository.getPromocionItemsConCostos();

    final Map<int, double> costoPorPromocion = {};
    for (final row in promoItemsRows) {
      final pId = (row['promocion_id'] as num).toInt();
      final cant = (row['cantidad'] as num?)?.toDouble() ?? 1.0;
      final vId = (row['variante_id'] as num?)?.toInt();
      final iId = (row['insumo_id'] as num?)?.toInt();

      double itemUnitCost = 0.0;
      if (vId != null) {
        final recipeCost = costoRecetaPorVariante[vId];
        if (recipeCost != null && recipeCost > 0) {
          itemUnitCost = recipeCost;
        } else {
          itemUnitCost =
              (row['costo_estimado_manual'] as num?)?.toDouble() ?? 0.0;
        }
      } else if (iId != null) {
        itemUnitCost = (row['costo_por_unidad'] as num?)?.toDouble() ?? 0.0;
      }
      costoPorPromocion[pId] =
          (costoPorPromocion[pId] ?? 0.0) + (cant * itemUnitCost);
    }

    // 3. Calcular COGS para todas las lineas de venta del periodo
    final detalleVentasRes = await _repository.getDetalleVentasPeriodo(
      fechaInicio,
      fechaFinExclusiva,
    );

    double costoMercaderia = 0.0;
    for (final row in detalleVentasRes) {
      final cant = (row['cantidad'] as num?)?.toDouble() ?? 0.0;
      final vId = (row['variante_id'] as num?)?.toInt();
      final pId = (row['promocion_id'] as num?)?.toInt();

      double costoUnitario = 0.0;
      if (vId != null) {
        final recipeCost = costoRecetaPorVariante[vId];
        if (recipeCost != null && recipeCost > 0) {
          costoUnitario = recipeCost;
        } else {
          costoUnitario =
              (row['costo_estimado_manual'] as num?)?.toDouble() ?? 0.0;
        }
      } else if (pId != null) {
        costoUnitario = costoPorPromocion[pId] ?? 0.0;
      }
      costoMercaderia += cant * costoUnitario;
    }

    // Productos mas vendidos
    final lista = await _repository.getProductosMasVendidos(
      fechaInicio,
      fechaFinExclusiva,
    );

    return ReporteData(
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      costoMercaderia: costoMercaderia,
      beneficioNeto: totalIngresos - totalGastos - costoMercaderia,
      productosVendidos: lista,
      periodo: periodo,
    );
  }

  Future<String?> generarReportePDF(ReporteData data) {
    return ReportesPdf.generarPDF(data);
  }
}
