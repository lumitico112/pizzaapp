import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/repositories/promocion_repository.dart';

class PromocionService {
  final PromocionRepository _repository;

  PromocionService(this._repository);

  Future<List<Promocion>> getPromociones() async {
    return await _repository.getPromociones();
  }

  Future<int> crearPromocion(Promocion promocion, List<PromocionItem> items) async {
    return await _repository.insertPromocion(promocion, items);
  }

  Future<void> actualizarPromocion(Promocion promocion, List<PromocionItem> items) async {
    await _repository.updatePromocion(promocion, items);
  }

  Future<void> eliminarPromocion(int id) async {
    await _repository.deletePromocion(id);
  }
}
