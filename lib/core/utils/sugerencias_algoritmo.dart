import 'package:sqflite/sqflite.dart';

class SugerenciasAlgoritmo {
  static Future<Map<String, dynamic>> calcularSugerencia({
    required Database db,
    required int varianteId,
    required DateTime fechaSugerencia,
  }) async {
    // 1. Promedio de Ventas (ese día en las últimas 4 semanas)
    // 0 = Domingo, 1 = Lunes, ..., 6 = Sábado
    int diaSemanaSqlite = fechaSugerencia.weekday == 7 ? 0 : fechaSugerencia.weekday;
    String fechaBaseStr = fechaSugerencia.toIso8601String().substring(0, 10);

    final ventasRes = await db.rawQuery('''
      SELECT SUM(dv.cantidad) as total_cantidad
      FROM DetalleVenta dv
      JOIN Ventas v ON dv.venta_id = v.id
      WHERE dv.variante_id = ? 
        AND strftime('%w', v.fecha) = ?
        AND v.fecha <= ?
        AND v.fecha > date(?, '-28 days')
        AND v.anulada = 0
    ''', [varianteId, diaSemanaSqlite.toString(), fechaBaseStr, fechaBaseStr]);

    double promedioVentas = 0.0;
    if (ventasRes.isNotEmpty && ventasRes.first['total_cantidad'] != null) {
      promedioVentas = ((ventasRes.first['total_cantidad'] as num).toDouble()) / 4.0;
    }

    // 2. Faltantes: Cantidades menores a 0 (sobrante < 0) en la última semana
    final faltantesRes = await db.rawQuery('''
      SELECT SUM(ip.sobrante) as total_faltante
      FROM ItemsPreparacion ip
      JOIN PreparacionDiaria pd ON ip.preparacion_id = pd.id
      WHERE ip.variante_id = ?
        AND ip.sobrante < 0
        AND pd.fecha <= ?
        AND pd.fecha > date(?, '-7 days')
    ''', [varianteId, fechaBaseStr, fechaBaseStr]);

    double promedioFaltantes = 0.0;
    if (faltantesRes.isNotEmpty && faltantesRes.first['total_faltante'] != null) {
      promedioFaltantes = ((faltantesRes.first['total_faltante'] as num).abs().toDouble()) / 7.0;
    }

    // 3. Sobrantes: sobrante > 0 en la última semana
    final sobrantesRes = await db.rawQuery('''
      SELECT SUM(ip.sobrante) as total_sobrante
      FROM ItemsPreparacion ip
      JOIN PreparacionDiaria pd ON ip.preparacion_id = pd.id
      WHERE ip.variante_id = ?
        AND ip.sobrante > 0
        AND pd.fecha <= ?
        AND pd.fecha > date(?, '-7 days')
    ''', [varianteId, fechaBaseStr, fechaBaseStr]);

    double promedioSobrantes = 0.0;
    if (sobrantesRes.isNotEmpty && sobrantesRes.first['total_sobrante'] != null) {
      promedioSobrantes = ((sobrantesRes.first['total_sobrante'] as num).toDouble()) / 7.0;
    }

    // 4. Sugerencia Final
    double baseSugerencia = promedioVentas + promedioFaltantes - promedioSobrantes;
    if (baseSugerencia < 0) baseSugerencia = 0;
    int sugerenciaFinal = baseSugerencia.ceil();

    return {
      'promedioVentas': promedioVentas,
      'promedioFaltantes': promedioFaltantes,
      'promedioSobrantes': promedioSobrantes,
      'sugerenciaFinal': sugerenciaFinal,
    };
  }
}
