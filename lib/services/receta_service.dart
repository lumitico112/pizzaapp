import 'package:pizzaapp/repositories/receta_repository.dart';
import 'package:pizzaapp/models/receta.dart';
import 'package:pizzaapp/core/utils/conversiones_helper.dart';

class RecetaService {
  final RecetaRepository _repository;

  RecetaService(this._repository);

  Future<List<RecetaItem>> obtenerRecetaCompleta(int varianteId) async {
    final items = await _repository.getRecetaByVariante(varianteId);
    
    // Cálculo de costos
    return items.map((item) {
      double costoCalculado = 0.0;
      if (item.insumoCostoUnidad != null && item.insumoUnidadBase != null) {
        // Convertir la cantidad requerida en la receta a la unidad base del insumo
        double cantidadConvertida = ConversionesHelper.convertir(
          item.cantidad, 
          item.unidadMedida, 
          item.insumoUnidadBase!
        );
        costoCalculado = cantidadConvertida * item.insumoCostoUnidad!;
      }
      return item.copyWith(costoCalculado: costoCalculado);
    }).toList();
  }

  Future<void> agregarInsumoAReceta(RecetaItem item) async {
    if (item.cantidad <= 0) throw Exception('La cantidad debe ser mayor a 0');
    await _repository.insertOrUpdate(item);
  }

  Future<void> eliminarInsumoDeReceta(int id) async {
    await _repository.deleteRecetaItem(id);
  }
}
