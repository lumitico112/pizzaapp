import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/utils/sugerencias_algoritmo.dart';

class PreparacionRepository {
  final dbHelper = DatabaseHelper.instance;

  // Registra la preparacion del dia
  Future<int> registrarPreparacion({
    required String fecha,
    required List<Map<String, dynamic>> items, // [{varianteId, cantidad}]
    String? nota,
  }) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      // Eliminar si ya existe para hoy
      final existing = await txn.query('PreparacionDiaria', where: 'fecha = ?', whereArgs: [fecha]);
      if (existing.isNotEmpty) {
        final id = existing.first['id'];
        await txn.delete('ItemsPreparacion', where: 'preparacion_id = ?', whereArgs: [id]);
        await txn.delete('PreparacionDiaria', where: 'id = ?', whereArgs: [id]);
      }

      final prepId = await txn.insert('PreparacionDiaria', {
        'fecha': fecha,
        'nota': nota,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in items) {
        if ((item['cantidad'] as num) != 0) {
          await txn.insert('ItemsPreparacion', {
            'preparacion_id': prepId,
            'variante_id': item['varianteId'],
            'cantidad_preparada': item['cantidad'],
            'notas': item['notas'],
          });
          if ((item['cantidad'] as num) > 0) {
            await txn.rawUpdate(
              'UPDATE VariantesProducto SET stock = stock + ? WHERE id = ?',
              [item['cantidad'], item['varianteId']]
            );
          }
        }
      }
      return prepId;
    });
  }

  // Obtiene preparacion de un dia
  Future<Map<String, dynamic>?> getPreparacionDia(String fecha) async {
    final db = await dbHelper.database;
    final rows = await db.query('PreparacionDiaria', where: 'fecha = ?', whereArgs: [fecha]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // Obtiene items de una preparacion
  Future<List<Map<String, dynamic>>> getItemsPreparacion(int prepId) async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT ip.*, vp.nombre_variante, vp.precio_venta, p.nombre as producto_nombre
      FROM ItemsPreparacion ip
      JOIN VariantesProducto vp ON ip.variante_id = vp.id
      JOIN Productos p ON vp.producto_id = p.id
      WHERE ip.preparacion_id = ?
    ''', [prepId]);
  }

  // Calcular sugerencias basadas en el nuevo algoritmo
  Future<List<Map<String, dynamic>>> getSugerencias({int? targetWeekday}) async {
    final db = await dbHelper.database;
    
    // Obtenemos la fecha actual, o si pasan targetWeekday, construimos una fecha para ese día
    DateTime fechaBase = DateTime.now();
    if (targetWeekday != null) {
      int difference = targetWeekday - fechaBase.weekday;
      fechaBase = fechaBase.add(Duration(days: difference));
    }

    // 1. Obtener todas las variantes activas
    final variantesActivas = await db.rawQuery('''
      SELECT vp.id as variante_id, vp.nombre_variante, p.nombre as producto_nombre
      FROM VariantesProducto vp
      JOIN Productos p ON vp.producto_id = p.id
      WHERE p.activo = 1
    ''');

    List<Map<String, dynamic>> resultado = [];

    // 2. Calcular sugerencia para cada variante
    for (var v in variantesActivas) {
      final int varianteId = v['variante_id'] as int;
      final calculo = await SugerenciasAlgoritmo.calcularSugerencia(
        db: db,
        varianteId: varianteId,
        fechaSugerencia: fechaBase,
      );

      resultado.add({
        'variante_id': varianteId,
        'producto_nombre': v['producto_nombre'],
        'variante_nombre': v['nombre_variante'],
        'promedioVentas': calculo['promedioVentas'],
        'promedioFaltantes': calculo['promedioFaltantes'],
        'promedioSobrantes': calculo['promedioSobrantes'],
        'sugerenciaFinal': calculo['sugerenciaFinal'],
      });
    }

    // Ordenar por sugerencia de mayor a menor
    resultado.sort((a, b) => (b['sugerenciaFinal'] as int).compareTo(a['sugerenciaFinal'] as int));

    return resultado;
  }

  // Obtener historial reciente de preparaciones
  Future<List<Map<String, dynamic>>> getHistorialPreparaciones({int limit = 7}) async {
    final db = await dbHelper.database;
    final preps = await db.query(
      'PreparacionDiaria',
      orderBy: 'fecha DESC',
      limit: limit,
    );

    List<Map<String, dynamic>> resultado = [];
    for (final prep in preps) {
      final items = await getItemsPreparacion(prep['id'] as int);
      resultado.add({...prep, 'items': items});
    }
    return resultado;
  }

  Future<void> marcarComoMerma(int itemId, int cantidad) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE ItemsPreparacion SET enviado_merma = enviado_merma + ? WHERE id = ?',
      [cantidad, itemId]
    );
  }

  Future<void> llevarParaManana(int itemId, int cantidad) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE ItemsPreparacion SET llevado_manana = llevado_manana + ? WHERE id = ?',
      [cantidad, itemId]
    );
  }

  Future<int> crearTransformacion(Map<String, dynamic> data) async {
    final db = await dbHelper.database;
    return await db.insert('Transformaciones', data);
  }

  Future<List<Map<String, dynamic>>> getTransformaciones() async {
    final db = await dbHelper.database;
    return await db.query('Transformaciones');
  }
}

