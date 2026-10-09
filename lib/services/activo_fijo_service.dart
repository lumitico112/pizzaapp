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
          
          final sesionActivaRes = await txn.query('SesionesCaja', where: "estado = 'abierta'", limit: 1);
          if (sesionActivaRes.isNotEmpty) {
            await txn.insert('MovimientosCaja', {
              'sesion_caja_id': sesionActivaRes.first['id'],
              'tipo': 'compra',
              'metodo_pago': 'efectivo',
              'monto': activo.costo,
              'descripcion': 'Compra activo: ${activo.nombre}',
              'fecha': DateTime.now().toIso8601String(),
            });
          }
        } else if (activo.metodoPago == 'Crédito' || activo.metodoPago.contains('Cr')) {
          if (adelanto > 0) {
            await txn.insert('Gastos', {
              'fecha': hoy,
              'categoria': 'Activos Fijos',
              'monto': adelanto,
              'descripcion': 'Adelanto de Activo (Crédito): ${activo.nombre}',
              'activo_id': activoId,
            });
            
            final sesionActivaRes = await txn.query('SesionesCaja', where: "estado = 'abierta'", limit: 1);
            if (sesionActivaRes.isNotEmpty) {
              await txn.insert('MovimientosCaja', {
                'sesion_caja_id': sesionActivaRes.first['id'],
                'tipo': 'compra',
                'metodo_pago': 'efectivo',
                'monto': adelanto,
                'descripcion': 'Adelanto activo: ${activo.nombre}',
                'fecha': DateTime.now().toIso8601String(),
              });
            }
          }
          double restante = activo.costo - adelanto;
          if (restante > 0) {
            int numCuotas = activo.cuotas > 0 ? activo.cuotas : 1;
            double cuotaFija = restante / numCuotas;
            for (int i = 0; i < numCuotas; i++) {
              await txn.insert('CuentasPorPagar', {
                'fecha': hoy,
                'insumo_id': 0,
                'cantidad': activo.cantidad > 0 ? activo.cantidad : 1,
                'costo_total': cuotaFija,
                'proveedor': 'Proveedor de ${activo.nombre}',
                'motivo': '${activo.nombre} (Cuota ${i+1}/$numCuotas)',
                'pagado': 0,
                'monto_pagado': 0.0,
                'cuotas': 1,
                'adelanto': 0.0,
              });
            }
          }
        }
      } else if (activo.condicion == 'Alquilado' || activo.condicion == 'Prestado') {
        if (activo.costo > 0) {
          await txn.insert('Gastos', {
            'fecha': hoy,
            'categoria': 'Activos Fijos',
            'monto': activo.costo,
            'descripcion': '${activo.condicion} de Activo: ${activo.nombre}',
            'activo_id': activoId,
          });
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

    final db = await DatabaseHelper.instance.database;
    final sesionActivaRes = await db.query('SesionesCaja', where: "estado = 'abierta'", limit: 1);
    if (sesionActivaRes.isNotEmpty) {
      await db.insert('MovimientosCaja', {
        'sesion_caja_id': sesionActivaRes.first['id'],
        'tipo': 'salida',
        'metodo_pago': 'efectivo',
        'monto': costo,
        'descripcion': 'Reparación: ${activo.nombre}',
        'fecha': DateTime.now().toIso8601String(),
      });
    }
    
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



