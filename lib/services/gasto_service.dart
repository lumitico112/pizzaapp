import 'package:pizzaapp/models/gasto.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';

class GastoService {
  final GastoRepository _repository;

  GastoService(this._repository);

  Future<List<Gasto>> obtenerGastos() async {
    return await _repository.getGastos();
  }

  Future<void> registrarGasto(Gasto gasto) async {
    if (gasto.monto <= 0) throw Exception('El monto del gasto debe ser mayor a 0');
    if (gasto.categoria.trim().isEmpty) throw Exception('La categoría es requerida');

    if (gasto.id == null) {
      await _repository.insertGasto(gasto);
    } else {
      await _repository.updateGasto(gasto);
    }
  }

  Future<void> eliminarGasto(int id) async {
    await _repository.deleteGasto(id);
  }
}
