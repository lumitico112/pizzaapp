import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db_harness.dart';

/// Caso SEC-020 de la evaluacion FS-2: las consultas de los repositorios
/// usan `where`/`whereArgs` o `rawQuery` con marcadores `?`; un texto con
/// carga SQL se almacena y busca de forma literal sin alterar otras filas.
void main() {
  group('Inyeccion SQL acotada (SEC-020)', () {
    late Database db;

    setUp(() async {
      db = await TestDbHarness.openFreshInMemoryDb();
    });

    tearDown(() async {
      await TestDbHarness.closeDb(db);
    });

    test('T1: una carga SQL se almacena literal y no afecta otras tablas',
        () async {
      final repo = ProductoRepository();
      const payload = "'; DROP TABLE Ventas; --";

      await repo.insertCategoria(Categoria(nombre: payload));
      await repo.insertCategoria(Categoria(nombre: 'Bebidas'));

      final categorias = await repo.getCategorias();
      expect(categorias, hasLength(2));
      expect(categorias.where((c) => c.nombre == payload), hasLength(1));

      // La tabla Ventas sigue existiendo y consultable:
      expect(await db.query('Ventas'), isEmpty);
      expect(await db.query('Categorias'), hasLength(2));
    });

    test('T2: una carga SQL no autentica ni coincide con un usuario real',
        () async {
      final repo = UsuarioRepository();
      await repo.createUsuario(
        Usuario(
          nombre: 'Admin Seguridad',
          username: 'admin_seg',
          passwordHash: HashUtils.hashPassword(
            'ClaveSegura123',
            iterations: 10000,
          ),
          rol: 'admin',
          activo: 1,
          bloqueado: 0,
        ),
      );

      const payload = "' OR '1'='1";

      expect(await repo.usernameExists(payload), isFalse);
      expect(await repo.usernameExists('admin_seg'), isTrue);
      expect(await repo.authenticate(payload, 'ClaveSegura123'), isNull);
      expect(
        await repo.authenticate('admin_seg', 'ClaveSegura123'),
        isNotNull,
      );
    });
  });
}
