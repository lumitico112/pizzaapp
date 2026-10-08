import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/onboarding_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_service = """  Future<void> setupInitialSystem({
    required String nombreNegocio,
    required String moneda,
    required String adminNombre,
    required String adminUsername,
    required String adminPassword,
  }) async {
    // 1. Guardar configuraciones iniciales
    if (nombreNegocio.trim().isEmpty) {
      throw Exception('El nombre del negocio es obligatorio.');
    }
    await _configRepo.saveConfig('nombre_negocio', nombreNegocio.trim());
    await _configRepo.saveConfig('moneda', moneda);

    // 2. Crear administrador (reutilizamos reglas de negocio del AuthService)
    await _authService.createAdmin(adminNombre, adminUsername, adminPassword);
  }"""
new_service = """  Future<void> setupInitialSystem({
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
    // 1. Guardar configuraciones iniciales
    if (nombreNegocio.trim().isEmpty) {
      throw Exception('El nombre del negocio es obligatorio.');
    }
    await _configRepo.saveConfig('nombre_negocio', nombreNegocio.trim());
    await _configRepo.saveConfig('moneda', moneda);
    
    if (logoRuta != null) {
      await _configRepo.saveConfig('logo_ruta', logoRuta);
    }
    if (fondoRuta != null) {
      await _configRepo.saveConfig('fondo_login_ruta', fondoRuta);
    }

    // 2. Crear administrador (reutilizamos reglas de negocio del AuthService)
    await _authService.createAdmin(adminNombre, adminUsername, adminPassword, correo: adminEmail, fotoRuta: fotoAdminRuta);
  }"""

if "setupInitialSystem" in text:
    text = text.replace(old_service, new_service)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Done")
