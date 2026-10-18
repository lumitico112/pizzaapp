import 'package:flutter/material.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/services/promocion_service.dart';

class PromocionController extends ChangeNotifier {
  final PromocionService _service;

  PromocionController(this._service);

  List<Promocion> _promociones = [];
  bool _isLoading = false;
  String? _error;

  List<Promocion> get promociones => _promociones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPromociones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _promociones = await _service.getPromociones();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarPromocion(
    Promocion promocion,
    List<PromocionItem> items,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (promocion.id == null) {
        await _service.crearPromocion(promocion, items);
      } else {
        await _service.actualizarPromocion(promocion, items);
      }
      await loadPromociones();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminarPromocion(int id) async {
    try {
      await _service.eliminarPromocion(id);
      await loadPromociones();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isPromocionValidaAhora(Promocion promocion) {
    if (promocion.activa != 1) return false;

    final now = DateTime.now();
    // dia: 1=Lunes, 7=Domingo (coincide con DateTime.weekday)
    if (promocion.diasSemana != null && promocion.diasSemana!.isNotEmpty) {
      final rawDays = promocion.diasSemana!
          .split(',')
          .map((e) => e.trim())
          .toSet();
      final labels = const {
        1: 'L',
        2: 'M',
        3: 'X',
        4: 'J',
        5: 'V',
        6: 'S',
        7: 'D',
      };
      if (!rawDays.contains('${now.weekday}') &&
          !rawDays.contains(labels[now.weekday])) {
        return false;
      }
    }

    if (promocion.horaInicio != null &&
        promocion.horaInicio!.isNotEmpty &&
        promocion.horaFin != null &&
        promocion.horaFin!.isNotEmpty) {
      final formatoHora = RegExp(r'^(\d{1,2}):(\d{2})$');
      final matchInicio = formatoHora.firstMatch(promocion.horaInicio!);
      final matchFin = formatoHora.firstMatch(promocion.horaFin!);

      if (matchInicio != null && matchFin != null) {
        final horaInicio = int.parse(matchInicio.group(1)!);
        final minInicio = int.parse(matchInicio.group(2)!);

        final horaFin = int.parse(matchFin.group(1)!);
        final minFin = int.parse(matchFin.group(2)!);

        final inicioMinutos = horaInicio * 60 + minInicio;
        final finMinutos = horaFin * 60 + minFin;
        final actualMinutos = now.hour * 60 + now.minute;

        if (inicioMinutos <= finMinutos) {
          if (actualMinutos < inicioMinutos || actualMinutos > finMinutos) {
            return false;
          }
        } else {
          // Pasa la medianoche
          if (actualMinutos > finMinutos && actualMinutos < inicioMinutos) {
            return false;
          }
        }
      }
    }

    return true;
  }
}
