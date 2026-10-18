import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/reporte_data.dart';

/// Acceso a datos del módulo de reportes (H-04c).
///
/// Conserva exactamente el SQL, los parámetros y los resultados que antes
/// vivían en `ReportesService`; la lógica de negocio (RN-05) permanece en la
/// capa de servicio para no alterar sus fórmulas.
class ReportesRepository {
  final DatabaseHelper dbHelper;

  ReportesRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Total de ventas no anuladas del periodo.
  Future<double> getTotalIngresos(String fechaInicio, String fechaFin) async {
    final db = await dbHelper.database;
    final ventasRes = await db.rawQuery(
      '''
      SELECT SUM(total) as total 
      FROM Ventas 
      WHERE fecha >= ? AND fecha <= ? AND anulada = 0
    ''',
      [fechaInicio, fechaFin],
    );
    return (ventasRes.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Total de gastos del periodo (excluye compras, activos fijos y CxP).
  Future<double> getTotalGastos(String fechaInicio, String fechaFin) async {
    final db = await dbHelper.database;
    final gastosRes = await db.rawQuery(
      '''
      SELECT SUM(monto) as total
      FROM Gastos
      WHERE fecha >= ? AND fecha <= ? AND categoria NOT IN ('Compras', 'Activos Fijos', 'Cuentas por Pagar')
    ''',
      [fechaInicio, fechaFin],
    );
    return (gastosRes.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Recetas con el costo y la unidad del insumo asociado (base de RN-05).
  Future<List<Map<String, Object?>>> getRecetasConInsumos() async {
    final db = await dbHelper.database;
    return db.rawQuery('''
      SELECT r.variante_id, r.cantidad as receta_cantidad, r.unidad_medida as receta_unidad,
             i.costo_por_unidad as insumo_costo, i.unidad_medida as insumo_unidad,
             i.contenido_paquete
      FROM Recetas r
      JOIN Insumos i ON r.insumo_id = i.id
    ''');
  }

  /// Ítems de promoción con sus costos de referencia (base de RN-05).
  Future<List<Map<String, Object?>>> getPromocionItemsConCostos() async {
    final db = await dbHelper.database;
    return db.rawQuery('''
      SELECT pi.promocion_id, pi.variante_id, pi.insumo_id, pi.cantidad,
             vp.costo_estimado_manual, i.costo_por_unidad
      FROM PromocionItems pi
      LEFT JOIN VariantesProducto vp ON pi.variante_id = vp.id
      LEFT JOIN Insumos i ON pi.insumo_id = i.id
    ''');
  }

  /// Líneas de venta del periodo con su costo manual de respaldo (base de RN-05).
  Future<List<Map<String, Object?>>> getDetalleVentasPeriodo(
    String fechaInicio,
    String fechaFin,
  ) async {
    final db = await dbHelper.database;
    return db.rawQuery('''
      SELECT dv.variante_id, dv.promocion_id, dv.cantidad,
             vp.costo_estimado_manual
      FROM DetalleVenta dv
      JOIN Ventas v ON dv.venta_id = v.id
      LEFT JOIN VariantesProducto vp ON dv.variante_id = vp.id
      WHERE v.fecha >= ? AND v.fecha <= ? AND v.anulada = 0
    ''', [fechaInicio, fechaFin]);
  }

  /// Top 20 de productos más vendidos del periodo.
  Future<List<ProductoVendido>> getProductosMasVendidos(
    String fechaInicio,
    String fechaFin,
  ) async {
    final db = await dbHelper.database;
    final productosRes = await db.rawQuery(
      '''
      SELECT p.nombre || ' ' || vp.nombre_variante as nombre_prod, 
             SUM(dv.cantidad) as cant, 
             SUM(dv.cantidad * dv.precio_unitario) as tot
      FROM DetalleVenta dv
      JOIN Ventas v ON dv.venta_id = v.id
      JOIN VariantesProducto vp ON dv.variante_id = vp.id
      JOIN Productos p ON vp.producto_id = p.id
      WHERE v.fecha >= ? AND v.fecha <= ? AND v.anulada = 0
      GROUP BY vp.id
      ORDER BY cant DESC
      LIMIT 20
    ''',
      [fechaInicio, fechaFin],
    );

    return productosRes
        .map(
          (r) => ProductoVendido(
            nombre: r['nombre_prod'] as String,
            cantidad: (r['cant'] as num).toInt(),
            total: (r['tot'] as num).toDouble(),
          ),
        )
        .toList();
  }
}
