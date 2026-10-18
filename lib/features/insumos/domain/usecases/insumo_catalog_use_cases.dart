import 'package:pizzaapp/features/insumos/domain/repositories/insumo_catalog_repository.dart';
import 'package:pizzaapp/models/insumo.dart';

/// Business rules for listing and maintaining the ingredient catalog.
class InsumoCatalogUseCases {
  final InsumoCatalogRepository _repository;

  InsumoCatalogUseCases(this._repository);

  Future<List<Insumo>> list() => _repository.getAll();

  Future<void> save(Insumo insumo) async {
    if (insumo.nombre.trim().isEmpty) {
      throw Exception('El nombre del insumo es obligatorio.');
    }
    if (insumo.stockMinimo < 0) {
      throw Exception('El stock mínimo no puede ser negativo.');
    }
    if (insumo.rendimientoPorUnidad <= 0) {
      throw Exception('El rendimiento no puede ser negativo.');
    }
    if (insumo.unidadMedida == 'Paquetes' && insumo.contenidoPaquete <= 0) {
      throw Exception('Debe indicar cuántas unidades contiene el paquete.');
    }
    await _repository.save(insumo);
  }

  Future<void> adjustStock({
    required int insumoId,
    required double quantity,
    String reason = 'Ajuste manual',
  }) async {
    if (quantity == 0) {
      throw Exception('La cantidad de ajuste no puede ser cero.');
    }
    await _repository.adjustStock(
      insumoId: insumoId,
      quantity: quantity,
      reason: reason,
    );
  }

  Future<void> deactivate(int id) => _repository.deactivate(id);
}
