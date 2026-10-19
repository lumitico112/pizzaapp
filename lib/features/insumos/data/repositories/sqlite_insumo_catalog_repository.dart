import 'package:pizzaapp/features/insumos/domain/repositories/insumo_catalog_repository.dart';
import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart' as legacy;

/// Bridges catalog use cases to the shared SQLite repository.
/// Other inventory flows continue using the shared repository during migration.
class SqliteInsumoCatalogRepository implements InsumoCatalogRepository {
  final legacy.InsumoRepository _repository;

  SqliteInsumoCatalogRepository(this._repository);

  @override
  Future<List<Insumo>> getAll() => _repository.getInsumos();

  @override
  Future<void> save(Insumo insumo) async {
    if (insumo.id == null) {
      await _repository.insertInsumo(insumo);
    } else {
      await _repository.updateInsumo(insumo);
    }
  }

  @override
  Future<void> adjustStock({
    required int insumoId,
    required double quantity,
    required String reason,
  }) =>
      _repository.ajustarStock(
          insumoId: insumoId,
          cantidadAjuste: quantity,
          tipoAdquisicion: 'ajuste',
          motivo: reason,
        );

  @override
  Future<void> deactivate(int id) async {
    await _repository.deleteInsumo(id);
  }
}
