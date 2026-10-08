import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/preparacion_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_logic = """
      for (var ingrediente in receta) {
        final insumoId = ingrediente['insumo_id'] as int;
        // La cantidad base (ej: 0.200 kg) por la cantidad de pizzas preparadas (ej: 10)
        final consumoEstimadoTotal = (ingrediente['cantidad_estimada'] as num).toDouble() * cantidadPreparada;

        if (consumoEstimadoTotal > 0) {
          await _insumoRepo.ajustarStock(
            insumoId: insumoId,
            cantidadAjuste: -consumoEstimadoTotal, // Descuento!
            tipoAdquisicion: 'consumo',
            motivo: 'PreparaciÃ³n de $cantidadPreparada unidades (Variante ID: $varianteId)',
          );
        }
      }
"""

new_logic = """
      // Incrementar el stock del producto pre-preparado
      await _prodRepo.actualizarStockVariante(varianteId, cantidadPreparada);

      for (var ingrediente in receta) {
        final insumoId = ingrediente['insumo_id'] as int;
        // La cantidad base (ej: 0.200 kg) por la cantidad de pizzas preparadas (ej: 10)
        final consumoEstimadoTotal = (ingrediente['cantidad_estimada'] as num).toDouble() * cantidadPreparada;

        if (consumoEstimadoTotal > 0) {
          await _insumoRepo.ajustarStock(
            insumoId: insumoId,
            cantidadAjuste: -consumoEstimadoTotal, // Descuento!
            tipoAdquisicion: 'consumo',
            motivo: 'Preparacion de $cantidadPreparada unidades (Variante ID: $varianteId)',
          );
        }
      }
"""

text = text.replace(old_logic, new_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
