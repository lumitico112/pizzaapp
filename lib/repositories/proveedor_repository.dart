import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/proveedor.dart';

class ProveedorRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Proveedor>> getProveedores({bool soloActivos = true}) async {
    final db = await _db.database;
    final where = soloActivos ? 'activo = 1' : null;
    final maps = await db.query('Proveedores', where: where, orderBy: 'nombre ASC');
    return maps.map(Proveedor.fromMap).toList();
  }

  Future<Proveedor?> getProveedorById(int id) async {
    final db = await _db.database;
    final maps = await db.query('Proveedores', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Proveedor.fromMap(maps.first);
  }

  Future<bool> existeNombre(String nombre, {int? exceptoId}) async {
    final db = await _db.database;
    final query = exceptoId != null
        ? 'SELECT id FROM Proveedores WHERE LOWER(nombre) = LOWER(?) AND id != ? AND activo = 1'
        : 'SELECT id FROM Proveedores WHERE LOWER(nombre) = LOWER(?) AND activo = 1';
    final args = exceptoId != null ? [nombre.trim(), exceptoId] : [nombre.trim()];
    final result = await db.rawQuery(query, args);
    return result.isNotEmpty;
  }

  Future<int> insertProveedor(Proveedor p) async {
    final db = await _db.database;
    return db.insert('Proveedores', p.toMap()..remove('id'));
  }

  Future<void> updateProveedor(Proveedor p) async {
    final db = await _db.database;
    await db.update('Proveedores', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> desactivarProveedor(int id) async {
    final db = await _db.database;
    await db.update('Proveedores', {'activo': 0}, where: 'id = ?', whereArgs: [id]);
  }
}
