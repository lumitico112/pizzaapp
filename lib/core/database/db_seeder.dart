import 'package:sqflite_sqlcipher/sqflite.dart';

/// Clase responsable de inicializar datos predefinidos (seeds) de forma idempotente.
/// IDEMPOTENTE: Puede ejecutarse múltiples veces sin crear duplicados.
class DbSeeder {
  final Database db;

  DbSeeder(this.db);

  /// Inicializa todos los datos predefinidos del sistema.
  Future<void> seedAll() async {
    await _seedCategoriasInsumo();
    await _seedCategoriasProducto();
    await _seedCategoriasActivo();
  }

  /// 5 categorías predefinidas de insumos (idempotente)
  Future<void> _seedCategoriasInsumo() async {
    const categorias = [
      'Ingredientes',
      'Empaques',
      'Bebidas',
      'Limpieza',
      'Otros',
    ];
    await _seedNombreCategoria('CategoriasInsumo', categorias);
  }

  /// 5 categorías predefinidas de productos (idempotente)
  Future<void> _seedCategoriasProducto() async {
    const categorias = [
      {'nombre': 'Pizzas', 'orden': '1'},
      {'nombre': 'Bebidas', 'orden': '2'},
      {'nombre': 'Entradas', 'orden': '3'},
      {'nombre': 'Postres', 'orden': '4'},
      {'nombre': 'Otros', 'orden': '5'},
    ];
    for (final cat in categorias) {
      final exists = await db.query(
        'Categorias',
        where: 'LOWER(nombre) = LOWER(?)',
        whereArgs: [cat['nombre']],
      );
      if (exists.isEmpty) {
        await db.insert('Categorias', {
          'nombre': cat['nombre'],
          'orden': int.parse(cat['orden']!),
        });
      }
    }
  }

  /// 5 categorías predefinidas de activos fijos (idempotente)
  Future<void> _seedCategoriasActivo() async {
    const categorias = [
      'Maquinaria',
      'Muebles',
      'Tecnología',
      'Vehículos',
      'Otros',
    ];
    await _seedNombreCategoria('CategoriasActivo', categorias);
  }

  /// Inserta nombres en una tabla si no existen (por nombre, case-insensitive)
  Future<void> _seedNombreCategoria(String tabla, List<String> nombres) async {
    for (final nombre in nombres) {
      final exists = await db.query(
        tabla,
        where: 'LOWER(nombre) = LOWER(?)',
        whereArgs: [nombre],
      );
      if (exists.isEmpty) {
        await db.insert(tabla, {'nombre': nombre});
      }
    }
  }
}
