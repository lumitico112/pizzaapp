import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/controllers/onboarding_controller.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_ctrl = """  Future<bool> setupSystem({
    required String nombreNegocio,
    required String moneda,
    required String adminNombre,
    required String adminUsername,
    required String adminPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.setupInitialSystem(
        nombreNegocio: nombreNegocio,
        moneda: moneda,
        adminNombre: adminNombre,
        adminUsername: adminUsername,
        adminPassword: adminPassword,
      );"""

new_ctrl = """  Future<bool> setupSystem({
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
      await _service.setupInitialSystem(
        nombreNegocio: nombreNegocio,
        moneda: moneda,
        adminNombre: adminNombre,
        adminUsername: adminUsername,
        adminPassword: adminPassword,
        adminEmail: adminEmail,
        logoRuta: logoRuta,
        fondoRuta: fondoRuta,
        fotoAdminRuta: fotoAdminRuta,
      );"""

if "Future<bool> setupSystem" in text:
    text = text.replace(old_ctrl, new_ctrl)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Done")
