import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/features/backup/application/backup_service.dart';

class OnboardingService {
  final ConfiguracionRepository _configRepo;
  final AuthService _authService;

  OnboardingService(this._configRepo, this._authService);

  Future<String> setupInitialSystem({
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
    if (nombreNegocio.trim().isEmpty) {
      throw Exception('El nombre del negocio es obligatorio.');
    }

    await _configRepo.runTransaction((txn) async {
      // 1. Guardar configuraciones iniciales dentro de la transacción
      await _configRepo.saveConfig(
        'nombre_negocio',
        nombreNegocio.trim(),
        executor: txn,
      );
      await _configRepo.saveConfig('moneda', moneda, executor: txn);

      if (logoRuta != null) {
        await _configRepo.saveConfig('logo_ruta', logoRuta, executor: txn);
      }
      if (fondoRuta != null) {
        await _configRepo.saveConfig(
          'fondo_login_ruta',
          fondoRuta,
          executor: txn,
        );
      }

      // 2. Crear administrador en la misma transacción
      await _authService.createAdmin(
        adminNombre,
        adminUsername,
        adminPassword,
        correo: adminEmail,
        fotoRuta: fotoAdminRuta,
        executor: txn,
      );
    });

    final recoveryCode = _authService.takeGeneratedRecoveryCode();

    // Tomar la primera copia local cuando ya existe una cuenta y la configuración inicial.
    try {
      await BackupService().createDailyLocalBackupIfDue();
    } catch (_) {
      // La configuración inicial no debe fallar por una copia de seguridad.
    }
    if (recoveryCode == null) {
      throw Exception('No se pudo generar la clave de rescate.');
    }
    return recoveryCode;
  }
}
