import 'package:pizzaapp/models/insumo.dart';

/// Domain-facing contract for catalog operations on ingredients.
abstract interface class InsumoCatalogRepository {
  Future<List<Insumo>> getAll();
  Future<void> save(Insumo insumo);
  Future<void> adjustStock({
    required int insumoId,
    required double quantity,
    required String reason,
  });
  Future<void> deactivate(int id);
}
