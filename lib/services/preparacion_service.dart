import 'package:pizzaapp/models/preparacion.dart';
import 'package:pizzaapp/repositories/preparacion_repository.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';

class PreparacionService {
  final PreparacionRepository _prepRepo;
  final ProductoRepository _prodRepo;
  final InsumoRepository _insumoRepo;

  PreparacionService(this._prepRepo, this._prodRepo, this._insumoRepo);

  Future<List<Preparacion>> obtenerHistorial() async {
    final res = await _prepRepo.getHistorialPreparaciones();
    return res.map((e) => Preparacion.fromMap(e)).toList();
  }

  Future<List<SugerenciaPreparacion>> obtenerSugerencias({int? targetWeekday}) async {
    final res = await _prepRepo.getSugerencias(targetWeekday: targetWeekday);
    return res.map((e) => SugerenciaPreparacion.fromMap(e)).toList();
  }

  Future<void> registrarPreparacion({
    required String nota,
    required List<Map<String, dynamic>> seleccion,
  }) async {
    // 1. Filtrar solo los que tienen cantidad != 0
    final validos = seleccion.where((s) => (s['cantidad'] as num) != 0).toList();
    if (validos.isEmpty) throw Exception('No hay productos seleccionados para registrar.');

    final hoy = DateTime.now().toIso8601String().split('T')[0];

    // 2. Registrar en la base de datos de preparaciÃ³n
    await _prepRepo.registrarPreparacion(
      fecha: hoy,
      items: validos,
      nota: nota,
    );

    // 3. DESCUENTO DE INVENTARIO BASADO EN RECETAS
    // Para cada producto preparado, buscar su receta y descontar insumos
    for (var item in validos) {
      final varianteId = item['varianteId'] as int;
      final cantidadPreparada = (item['cantidad'] as num).toInt();

      final receta = await _prodRepo.getRecetaCompleta(varianteId);
      
      for (var ingrediente in receta) {
        final insumoId = ingrediente['insumo_id'] as int;
        // La cantidad base (ej: 0.200 kg) por la cantidad de pizzas preparadas (ej: 10)
        final consumoEstimadoTotal = (ingrediente['cantidad_estimada'] as num).toDouble() * cantidadPreparada;

        if (consumoEstimadoTotal > 0) {
          await _insumoRepo.ajustarStock(
            insumoId: insumoId,
            cantidadAjuste: -consumoEstimadoTotal, // Descuento!
            tipoAdquisicion: 'consumo',
            motivo: 'PreparaciÃ³n de \$cantidadPreparada unidades (Variante ID: \$varianteId)',
          );
        }
      }
    }
  }

  Future<void> marcarComoMerma(int itemId, int cantidad) async {
    await _prepRepo.marcarComoMerma(itemId, cantidad);
  }

  Future<void> llevarParaManana(int itemId, int cantidad) async {
    await _prepRepo.llevarParaManana(itemId, cantidad);
  }

  Future<List<Transformacion>> obtenerTransformaciones() async {
    final res = await _prepRepo.getTransformaciones();
    return res.map((e) => Transformacion.fromMap(e)).toList();
  }

  Future<void> crearTransformacion(Transformacion transformacion) async {
    await _prepRepo.crearTransformacion(transformacion.toMap());
  }
}
