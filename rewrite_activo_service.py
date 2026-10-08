import sys

new_content = """import 'package:pizzaapp/models/activo_fijo.dart';
import 'package:pizzaapp/models/gasto.dart';
import 'package:pizzaapp/repositories/activo_fijo_repository.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';

class ActivoFijoService {
  final ActivoFijoRepository _repository;
  final GastoRepository _gastoRepo;
  final InsumoRepository _insumoRepo;

  ActivoFijoService(this._repository, this._gastoRepo, this._insumoRepo);

  Future<List<ActivoFijo>> obtenerTodos() async {
    return await _repository.getAll();
  }

  Future<void> registrarActivo(ActivoFijo activo) async {
    if (activo.costo < 0) throw Exception('El costo del activo no puede ser negativo.');
    if (activo.nombre.isEmpty) throw Exception('El nombre del activo es obligatorio.');

    final id = await _repository.insert(activo);
    final hoy = DateTime.now().toIso8601String().split('T')[0];

    // Lógica de registro financiero basado en el cliente
    if (activo.condicion == 'Comprado') {
      if (activo.metodoPago == 'Contado') {
        // Al cash: Subir a gastos
        await _gastoRepo.insertGasto(Gasto(
          categoria: 'Activos Fijos',
          monto: activo.costo,
          descripcion: 'Compra de Activo (Cash): ${activo.nombre}',
          fecha: hoy,
        ));
      } else if (activo.metodoPago == 'Crédito') {
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
      }
    }
  }

  Future<void> actualizarActivo(ActivoFijo activo) async {
    if (activo.costo < 0) throw Exception('El costo del activo no puede ser negativo.');
    if (activo.nombre.isEmpty) throw Exception('El nombre del activo es obligatorio.');
    await _repository.update(activo);
  }

  Future<void> eliminarActivo(int id) async {
    await _repository.delete(id);
  }

  double calcularTotalInvertido(List<ActivoFijo> activos) {
    return activos.fold(0, (sum, item) => sum + item.costo);
  }

  Future<void> registrarGastoReparacion(ActivoFijo activo, double costo, String descripcion) async {
    if (costo <= 0) throw Exception('Costo inválido');
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _gastoRepo.insertGasto(Gasto(
      categoria: 'Mantenimiento/Reparación',
      monto: costo,
      descripcion: 'Reparación de activo [${activo.nombre}]: $descripcion',
      fecha: hoy,
    ));
    
    // Auto-actualizar estado a 'En reparación' o dejar como está, mejor actualizarlo
    if (activo.estado != 'En reparación') {
      final updated = ActivoFijo(
        id: activo.id,
        nombre: activo.nombre,
        categoria: activo.categoria,
        costo: activo.costo,
        fechaAdquisicion: activo.fechaAdquisicion,
        estado: 'En reparación',
        condicion: activo.condicion,
        metodoPago: activo.metodoPago,
        cuotas: activo.cuotas,
        observaciones: activo.observaciones,
        fotoRuta: activo.fotoRuta,
        activo: activo.activo,
      );
      await _repository.update(updated);
    }
  }
}
"""

with open('C:/D/ProyectoPizza/pizzaapp/lib/services/activo_fijo_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
