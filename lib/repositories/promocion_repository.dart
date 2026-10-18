import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/promocion.dart';

class PromocionRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insertPromocion(
    Promocion promocion,
    List<PromocionItem> items,
  ) async {
    _validate(promocion, items);
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      int id = await txn.insert('Promociones', promocion.toMap());
      for (var item in items) {
        final itemMap = item.toMap();
        itemMap['promocion_id'] = id;
        itemMap.remove('id'); // Ensure auto-increment works
        await txn.insert('PromocionItems', itemMap);
      }
      return id;
    });
  }

  Future<int> updatePromocion(
    Promocion promocion,
    List<PromocionItem> items,
  ) async {
    _validate(promocion, items);
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      int count = await txn.update(
        'Promociones',
        promocion.toMap(),
        where: 'id = ?',
        whereArgs: [promocion.id],
      );

      // Delete old items and insert new ones
      await txn.delete(
        'PromocionItems',
        where: 'promocion_id = ?',
        whereArgs: [promocion.id],
      );

      for (var item in items) {
        final itemMap = item.toMap();
        itemMap['promocion_id'] = promocion.id;
        itemMap.remove('id');
        await txn.insert('PromocionItems', itemMap);
      }
      return count;
    });
  }

  void _validate(Promocion promo, List<PromocionItem> items) {
    if (promo.nombre.trim().isEmpty) {
      throw Exception('El nombre de la promoción es obligatorio.');
    }
    if (!promo.precio.isFinite || promo.precio < 0) {
      throw Exception('El precio de la promoción no es válido.');
    }
    if (items.isEmpty) {
      throw Exception('Agrega al menos un componente.');
    }
    for (final item in items) {
      if ((item.varianteId == null) == (item.insumoId == null)) {
        throw Exception(
          'Cada componente debe ser exactamente un producto o un insumo.',
        );
      }
      if (item.cantidad < 1) {
        throw Exception(
          'La cantidad de cada componente debe ser mayor a cero.',
        );
      }
    }
  }

  Future<List<Promocion>> getPromociones() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Promociones',
      orderBy: 'nombre',
    );

    if (maps.isEmpty) {
      return [];
    }

    final promoIds = maps.map((m) => m['id'] as int).toList();
    final placeholders = List.filled(promoIds.length, '?').join(',');
    final List<Map<String, dynamic>> allItemsMaps = await db.query(
      'PromocionItems',
      where: 'promocion_id IN ($placeholders)',
      whereArgs: promoIds,
    );

    final Map<int, List<PromocionItem>> itemsByPromoId = {};
    for (final itemMap in allItemsMaps) {
      final promoId = itemMap['promocion_id'] as int;
      itemsByPromoId
          .putIfAbsent(promoId, () => [])
          .add(PromocionItem.fromMap(itemMap));
    }

    return maps.map((map) {
      final id = map['id'] as int;
      final items = itemsByPromoId[id] ?? <PromocionItem>[];
      return Promocion.fromMap(map, items);
    }).toList();
  }

  Future<void> deletePromocion(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'PromocionItems',
        where: 'promocion_id = ?',
        whereArgs: [id],
      );
      await txn.delete('Promociones', where: 'id = ?', whereArgs: [id]);
    });
  }
}
