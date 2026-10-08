import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/merma_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_logic = """    if (insumoId != null) {
      await _insumoRepo.ajustarStock(
        insumoId: insumoId,
        cantidadAjuste: -cantidad, // Descuento
        tipoAdquisicion: 'merma',
        motivo: 'Merma \\$tipo: ${descripcion ?? ''}',
      );
    }
  }
}"""

new_logic = """    if (insumoId != null) {
      await _insumoRepo.ajustarStock(
        insumoId: insumoId,
        cantidadAjuste: -cantidad, // Descuento
        tipoAdquisicion: 'merma',
        motivo: 'Merma \\$tipo: ${descripcion ?? ''}',
      );
    } else if (varianteId != null) {
      await _prodRepo.actualizarStockVariante(varianteId, -(cantidad.toInt()));
    }
  }
}"""
text = text.replace(old_logic, new_logic)

# if it didn't replace because the literal \$ is just $ in the dart code, let's just do a substring search
if "actualizarStockVariante" not in text:
    old_logic2 = """    if (insumoId != null) {
      await _insumoRepo.ajustarStock(
        insumoId: insumoId,
        cantidadAjuste: -cantidad, // Descuento
        tipoAdquisicion: 'merma',
        motivo: 'Merma $tipo: ${descripcion ?? ''}',
      );
    }
  }
}"""
    new_logic2 = """    if (insumoId != null) {
      await _insumoRepo.ajustarStock(
        insumoId: insumoId,
        cantidadAjuste: -cantidad, // Descuento
        tipoAdquisicion: 'merma',
        motivo: 'Merma $tipo: ${descripcion ?? ''}',
      );
    } else if (varianteId != null) {
      await _prodRepo.actualizarStockVariante(varianteId, -(cantidad.toInt()));
    }
  }
}"""
    text = text.replace(old_logic2, new_logic2)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
