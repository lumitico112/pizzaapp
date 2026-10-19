import 'package:pizzaapp/models/merma.dart';
import 'package:pizzaapp/features/waste/data/repositories/merma_repository.dart';

/// Validates waste operations; persistence and stock changes are atomic.
class MermaService {
  final MermaRepository _mermaRepo;

  MermaService(this._mermaRepo);

  Future<List<Merma>> obtenerMermas() => _mermaRepo.getMermas();

  Future<void> registrarMerma({
    required String tipo,
    required double cantidad,
    String? descripcion,
    int? insumoId,
    int? varianteId,
    String? fotoRuta,
  }) async {
    if (cantidad <= 0) throw Exception('La cantidad debe ser mayor a 0');
    if ((insumoId == null) == (varianteId == null)) {
      throw Exception('Debe seleccionar exactamente un insumo o producto');
    }

    await _mermaRepo.insertMerma(Merma(
      fecha: DateTime.now().toIso8601String(),
      tipo: tipo,
      descripcion: descripcion,
      insumoId: insumoId,
      varianteId: varianteId,
      cantidad: cantidad,
      fotoRuta: fotoRuta,
    ));
  }
}
