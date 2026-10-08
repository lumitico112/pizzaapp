import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/activo_fijo_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_func = "Future<void> registrarActivo(ActivoFijo activo) async {"
new_func = "Future<void> registrarActivo(ActivoFijo activo, [double adelanto = 0]) async {"
text = text.replace(old_func, new_func)

old_logic = """      } else if (activo.metodoPago == 'Crédito') {
        // A crédito: Generar cuentas por pagar por cada cuota
        double montoCuota = activo.costo / (activo.cuotas > 0 ? activo.cuotas : 1);
        for (int i = 1; i <= activo.cuotas; i++) {
          await _insumoRepo.registrarCuentaPorPagar(
            insumoId: 0, // 0 indicará activo, ya que no podemos poner NULL fácilmente en InsumoRepository, o podemos modificar registrarCuentaPorPagar
            cantidad: 1,
            costoTotal: montoCuota,
            proveedor: 'Proveedor de ${activo.nombre}',
            factura: 'Cuota $i/${activo.cuotas}: ${activo.nombre}',
          );
        }
      }"""

new_logic = """      } else if (activo.metodoPago == 'Crédito') {
        if (adelanto > 0) {
          await _gastoRepo.insertGasto(Gasto(
            categoria: 'Activos Fijos',
            monto: adelanto,
            descripcion: 'Adelanto de Activo (Crédito): ${activo.nombre}',
            fecha: hoy,
          ));
        }
        double restante = activo.costo - adelanto;
        if (restante > 0) {
          double montoCuota = restante / (activo.cuotas > 0 ? activo.cuotas : 1);
          for (int i = 1; i <= activo.cuotas; i++) {
            await _insumoRepo.registrarCuentaPorPagar(
              insumoId: 0, 
              cantidad: 1,
              costoTotal: montoCuota,
              proveedor: 'Proveedor de ${activo.nombre}',
              factura: 'Cuota $i/${activo.cuotas}: ${activo.nombre}',
            );
          }
        }
      }"""
text = text.replace(old_logic, new_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
