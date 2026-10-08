import 'package:pizzaapp/models/merma.dart';
import 'package:pizzaapp/repositories/merma_repository.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';

class MermaService {
  final MermaRepository _mermaRepo;
  final InsumoRepository _insumoRepo;

  final ProductoRepository _prodRepo;

  MermaService(this._mermaRepo, this._insumoRepo, this._prodRepo);

  Future<List<Merma>> obtenerMermas() async {
    return await _mermaRepo.getMermas();
  }

  Future<void> registrarMerma({
    required String tipo,
    required double cantidad,
    String? descripcion,
    int? insumoId,
    int? varianteId,
    String? fotoRuta,
  }) async {
    if (cantidad <= 0) throw Exception('La cantidad debe ser mayor a 0');
    if (insumoId == null && varianteId == null) {
      throw Exception('Debe seleccionar un insumo o producto');
    }

    final merma = Merma(
      fecha: DateTime.now().toIso8601String(),
      tipo: tipo,
      descripcion: descripcion,
      insumoId: insumoId,
      varianteId: varianteId,
      cantidad: cantidad,
      fotoRuta: fotoRuta,
    );

    // 1. Registrar merma
    await _mermaRepo.insertMerma(merma);

    // 2. Descontar stock si es insumo directo
    if (insumoId != null) {
      await _insumoRepo.ajustarStock(
        insumoId: insumoId,
        cantidadAjuste: -cantidad, // Descuento
        tipoAdquisicion: 'merma',
        motivo: 'Merma \$tipo: ${descripcion ?? ''}',
      );
    } else if (varianteId != null) {
      await _prodRepo.actualizarStockVariante(varianteId, -(cantidad.toInt()));
    }
  }
}


