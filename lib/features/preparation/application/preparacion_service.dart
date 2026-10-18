import 'package:pizzaapp/models/preparacion.dart';
import 'package:pizzaapp/features/preparation/data/repositories/preparacion_repository.dart';
import 'package:pizzaapp/features/waste/data/repositories/merma_repository.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';

/// Coordinates preparation operations; inventory effects are atomic in the repository.
class PreparacionService {
  final PreparacionRepository _prepRepo;
  final MermaRepository _mermaRepo;
  final CajaRepository _cajaRepo;

  PreparacionService(this._prepRepo, this._mermaRepo, this._cajaRepo);

  Future<bool> hayCajaActiva() async => await _cajaRepo.getSesionActiva() != null;

  Future<List<Preparacion>> obtenerHistorial() async {
    final rows = await _prepRepo.getHistorialPreparaciones();
    return rows.map(Preparacion.fromMap).toList();
  }

  Future<Map<String, dynamic>?> obtenerPreparacionHoy() {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    return _prepRepo.getPreparacionDia(hoy);
  }

  Future<List<Map<String, dynamic>>> obtenerSobrantesPendientes() =>
      _prepRepo.getSobrantesPendientes();

  Future<List<Map<String, dynamic>>> obtenerProductosConStockParaSobrantes({
    bool soloNoResueltos = false,
  }) => _prepRepo.getProductosConStockParaSobrantes(
    soloNoResueltos: soloNoResueltos,
  );

  Future<void> procesarGestionSobrantesStock({
    required Map<int, Map<String, int>> decisiones,
    required bool esCierreDeCiclo,
    String tipoMerma = 'otro',
  }) => _prepRepo.procesarGestionSobrantesStock(
    decisiones: decisiones,
    esCierreDeCiclo: esCierreDeCiclo,
    tipoMerma: tipoMerma,
  );

  Future<List<SugerenciaPreparacion>> obtenerSugerencias({
    int? targetWeekday,
  }) async {
    final rows = await _prepRepo.getSugerencias(targetWeekday: targetWeekday);
    return rows.map(SugerenciaPreparacion.fromMap).toList();
  }

  Future<void> registrarPreparacion({
    required String nota,
    required List<Map<String, dynamic>> seleccion,
    Map<int, int> sobrantesAPreparacion = const {},
    Map<int, int> sobrantesAMerma = const {},
    Map<int, int> trasladadosPorVariante = const {},
  }) async {
    final validos = seleccion;
    if (validos.isEmpty) {
      throw Exception('No hay productos seleccionados para registrar.');
    }
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _prepRepo.registrarPreparacion(
      fecha: hoy,
      items: validos,
      nota: nota,
      sobrantesAPreparacion: sobrantesAPreparacion,
      sobrantesAMerma: sobrantesAMerma,
      trasladadosPorVariante: trasladadosPorVariante,
    );
  }

  Future<void> procesarSobrantesPendientes({
    required Map<int, int> sobrantesAPreparacion,
    required Map<int, int> sobrantesAMerma,
    required List<int> itemIdsResueltos,
  }) => _prepRepo.procesarSobrantesPendientes(
    sobrantesAPreparacion: sobrantesAPreparacion,
    sobrantesAMerma: sobrantesAMerma,
    itemIdsResueltos: itemIdsResueltos,
  );

  Future<void> marcarComoMerma(int itemId, int cantidad) =>
      _mermaRepo.registrarMermaPreparacion(itemId: itemId, cantidad: cantidad);

  Future<void> llevarParaManana(int itemId, int cantidad) =>
      _prepRepo.llevarParaManana(itemId, cantidad);

  Future<List<Transformacion>> obtenerTransformaciones() async {
    final rows = await _prepRepo.getTransformaciones();
    return rows.map(Transformacion.fromMap).toList();
  }

  Future<void> crearTransformacion(Transformacion transformacion) =>
      _prepRepo.crearTransformacion(transformacion.toMap());

  Future<void> aplicarTransformacion({
    required int reglaId,
    required int cantidadOrigen,
  }) => _prepRepo.aplicarTransformacion(
    reglaId: reglaId,
    cantidadOrigen: cantidadOrigen,
  );

  Future<void> registrarEntradaProductoPreparado({
    required int varianteId,
    required int cantidad,
    required String motivo,
  }) => _prepRepo.registrarEntradaProductoPreparado(
    varianteId: varianteId,
    cantidad: cantidad,
    motivo: motivo,
  );
}
