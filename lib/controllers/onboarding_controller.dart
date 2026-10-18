import 'package:flutter/material.dart';
import 'package:pizzaapp/services/onboarding_service.dart';

class OnboardingController extends ChangeNotifier {
  final OnboardingService _service;

  OnboardingController(this._service);

  bool _isLoading = false;
  String? _error;
  String? _recoveryCode;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? takeRecoveryCode() {
    final code = _recoveryCode;
    _recoveryCode = null;
    return code;
  }

  Future<bool> setupSystem({
    required String nombreNegocio,
    required String moneda,
    required String adminNombre,
    required String adminUsername,
    required String adminPassword,
    required String adminEmail,
    String? logoRuta,
    String? fondoRuta,
    String? fotoAdminRuta,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recoveryCode = await _service.setupInitialSystem(
        nombreNegocio: nombreNegocio,
        moneda: moneda,
        adminNombre: adminNombre,
        adminUsername: adminUsername,
        adminPassword: adminPassword,
        adminEmail: adminEmail,
        logoRuta: logoRuta,
        fondoRuta: fondoRuta,
        fotoAdminRuta: fotoAdminRuta,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
