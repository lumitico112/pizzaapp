import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';

class OnboardingService {
  final ConfiguracionRepository _configRepo;
  final AuthService _authService;

  OnboardingService(this._configRepo, this._authService);

  Future<void> setupInitialSystem({
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
  }
}
