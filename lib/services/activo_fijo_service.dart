import 'package:pizzaapp/models/activo_fijo.dart';
import 'package:pizzaapp/models/gasto.dart';
import 'package:pizzaapp/repositories/activo_fijo_repository.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/repositories/insumo_repository.dart';

import 'package:pizzaapp/core/database/database_helper.dart';

class ActivoFijoService {
  final ActivoFijoRepository _repository;
  final GastoRepository _gastoRepo;
  final InsumoRepository _insumoRepo;

  ActivoFijoService(this._repository, this._gastoRepo, this._insumoRepo);

  Future<List<ActivoFijo>> obtenerTodos() async {
    return await _repository.getAll();
  }

  Future<void> registrarActivo(ActivoFijo activo, [double adelanto = 0]) async {
    if (activo.costo < 0) throw Exception('El costo del activo no puede ser negativo.');
    if (activo.nombre.isEmpty) throw Exception('El nombre del activo es obligatorio.');
    if (adelanto < 0) throw Exception('El adelanto no puede ser negativo.');
    if (adelanto > activo.costo) throw Exception('El adelanto no puede superar el costo total.');

    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      final map = activo.toMap();
      map.remove('id');
      final activoId = await txn.insert('ActivosFijos', map);

      if (activo.condicion == 'Comprado') {
        if (activo.costo <= 0) throw Exception('El costo debe ser mayor a 0 para un activo comprado.');

        await txn.insert('AjustesStock', {
          'fecha': hoy,
          'insumo_id': 0,
          'cantidad_ajuste': activo.cantidad > 0 ? activo.cantidad : 1,
          'tipo_adquisicion': 'comprado',
          'costo_unitario': activo.costo / (activo.cantidad > 0 ? activo.cantidad : 1),
          'motivo': activo.nombre,
        });

        if (activo.metodoPago == 'Contado') {
          await txn.insert('Gastos', {
            'fecha': hoy,
            'categoria': 'Activos Fijos',
            'monto': activo.costo,
            'descripcion': 'Compra de Activo (Cash): ${activo.nombre}',
            'activo_id': activoId,
          });
        } else if (activo.metodoPago == 'Crédito') {
          if (adelanto > 0) {
            await txn.insert('Gastos', {
              'fecha': hoy,
              'categoria': 'Activos Fijos',
              'monto': adelanto,
              'descripcion': 'Adelanto de Activo (Crédito): ${activo.nombre}',
              'activo_id': activoId,
            });
          }
          double restante = activo.costo - adelanto;
          if (restante > 0) {
            await txn.insert('CuentasPorPagar', {
              'fecha': hoy,
              'insumo_id': 0,
              'cantidad': activo.cantidad > 0 ? activo.cantidad : 1,
              'costo_total': restante,
              'proveedor': 'Proveedor de ${activo.nombre}',
              'motivo': activo.nombre,
              'pagado': 0,
              'monto_pagado': 0.0,
              'cuotas': activo.cuotas > 0 ? activo.cuotas : 1,
              'adelanto': adelanto,
            });
          }
        }
      }
    });
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
