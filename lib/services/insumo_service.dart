import 'package:pizzaapp/models/insumo.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';

class InsumoService {
  final InsumoRepository _repository;

  InsumoService(this._repository);

  Future<List<Insumo>> obtenerInsumos() async {
    return await _repository.getInsumos();
  }

  Future<void> guardarInsumo(Insumo insumo) async {
    if (insumo.nombre.trim().isEmpty) {
      throw Exception('El nombre del insumo es obligatorio.');
    }
    if (insumo.stockMinimo < 0) {
      throw Exception('El stock mÃ­nimo no puede ser negativo.');
    }
    if (insumo.rendimientoPorUnidad <= 0) {
      throw Exception('El rendimiento no puede ser negativo.');
    }
    if (insumo.unidadMedida == 'Paquetes' && insumo.contenidoPaquete <= 0) {
      throw Exception('Debe indicar cuántas unidades contiene el paquete.');
    }

    if (insumo.id == null) {
      await _repository.insertInsumo(insumo);
    } else {
      await _repository.updateInsumo(insumo);
    }
  }

  Future<void> eliminarInsumo(int id) async {
    await _repository.deleteInsumo(id);
  }

  Future<void> registrarAjusteStock({
    required int insumoId,
    required double cantidadAjuste,
    String motivo = 'Ajuste manual',
  }) async {
    if (cantidadAjuste == 0) {
      throw Exception('La cantidad de ajuste no puede ser cero.');
    }
    await _repository.ajustarStock(
      insumoId: insumoId,
      cantidadAjuste: cantidadAjuste,
      tipoAdquisicion: 'ajuste',
      motivo: motivo,
    );
  }
}

