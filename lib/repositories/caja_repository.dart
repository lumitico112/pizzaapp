import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';

class CajaRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<SesionCaja?> getSesionActiva() async {
    final db = await dbHelper.database;
    final res = await db.query('SesionesCaja', where: 'estado = ?', whereArgs: ['abierta']);
    if (res.isEmpty) return null;
    return SesionCaja.fromMap(res.first);
  }

  Future<int> crearSesion(SesionCaja sesion) async {
    final db = await dbHelper.database;
    return await db.insert('SesionesCaja', sesion.toMap());
  }

  Future<void> actualizarSesion(SesionCaja sesion) async {
    final db = await dbHelper.database;
    await db.update('SesionesCaja', sesion.toMap(), where: 'id = ?', whereArgs: [sesion.id]);
  }

  Future<int> insertMovimiento(MovimientoCaja mov) async {
    final db = await dbHelper.database;
    return await db.insert('MovimientosCaja', mov.toMap());
  }

  Future<List<MovimientoCaja>> getMovimientos(int sesionId) async {
    final db = await dbHelper.database;
    final res = await db.query('MovimientosCaja', where: 'sesion_caja_id = ?', whereArgs: [sesionId]);
    return res.map((m) => MovimientoCaja.fromMap(m)).toList();
  }
}
