import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/promocion.dart';

class PromocionRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insertPromocion(Promocion promocion, List<PromocionItem> items) async {
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

  Future<int> updatePromocion(Promocion promocion, List<PromocionItem> items) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      int count = await txn.update(
        'Promociones',
        promocion.toMap(),
        where: 'id = ?',
        whereArgs: [promocion.id],
      );
      
      // Delete old items and insert new ones
      await txn.delete('PromocionItems', where: 'promocion_id = ?', whereArgs: [promocion.id]);
      
      for (var item in items) {
        final itemMap = item.toMap();
        itemMap['promocion_id'] = promocion.id;
        itemMap.remove('id');
        await txn.insert('PromocionItems', itemMap);
      }
      return count;
    });
  }

  Future<List<Promocion>> getPromociones() async {
    final db = await _dbHelper.database;
    // We only fetch active promotions or all? Let's fetch all.
    final List<Map<String, dynamic>> maps = await db.query('Promociones', orderBy: 'nombre');
    
    List<Promocion> promociones = [];
    for (var map in maps) {
      final itemsMaps = await db.query('PromocionItems', where: 'promocion_id = ?', whereArgs: [map['id']]);
      List<PromocionItem> items = itemsMaps.map((itemMap) => PromocionItem.fromMap(itemMap)).toList();
      promociones.add(Promocion.fromMap(map, items));
    }
    return promociones;
  }
  
  Future<void> deletePromocion(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('PromocionItems', where: 'promocion_id = ?', whereArgs: [id]);
      await txn.delete('Promociones', where: 'id = ?', whereArgs: [id]);
    });
  }
}
