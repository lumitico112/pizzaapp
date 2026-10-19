# KIMI PIZZA — Evidencia estática de repositorio y plataforma (FS-5)

**Versión:** 1.0 — 18/10/2026
**Fase:** `FS-5` — Lote estático de repositorio y plataforma
**Casos:** SEC-011, SEC-013, SEC-032, SEC-034, SEC-036, SEC-037, SEC-039
**Alcance:** inspección de solo lectura sobre `lib/`, `android/`, `pubspec.yaml`/`pubspec.lock` y artefactos de build locales. La reanudación aprobada del 18/10/2026 implementó SEC-037 en `.github/workflows/ci.yml` (commit `a176041`), única modificación de configuración de la fase; sin cambios de código.
**Base:** commit `3b4956d` (rama `refactor/auditoria-2026-10`) + árbol de trabajo de esta fase.
**Entorno:** Windows x64 · Flutter 3.47.5 (stable) · Dart 3.13.4 · git 2.51.0 · 42 commits · 320 archivos versionados.

> **Sanitización:** este documento no contiene secretos reales, credenciales, tokens ni datos personales. Los únicos valores de credenciales citados son los marcadores de posición de `android/key.properties.example`; las contraseñas mencionadas en pruebas son fixtures sintéticos.

> **Naturaleza de la evidencia:** es estática (escritorio). No sustituye la validación en dispositivo ni la revisión humana del propietario/revisor. Los casos que exigen dispositivo, keystore o artefacto release quedan para `FS-7`.

---

## 1. Resumen ejecutivo

| Caso | Resultado de la inspección | Evidencia | Límite / riesgo residual |
|---|---|---|---|
| SEC-011 | Sin secretos reales detectados en el árbol versionado ni en la historia | Barrido de patrones + revisión de 42 commits y nombres de archivo | Sin scanner dedicado local (`gitleaks`/`trufflehog` no instalados); job de CI implementado en SEC-037 (commit `a176041`; canario pendiente del primer push) |
| SEC-013 | Sin credenciales en claro en almacenamiento ordinario; claves en Keystore/Keychain | Inventario de almacenamiento y revisión de escrituras a disco | Restore/exportación real en dispositivo → `FS-7` (SEC-014) |
| SEC-032 | Sin secretos en logs; 6 `debugPrint` de error/traza revisados | Barrido regex + inspección de los 6 puntos | Trazas técnicas pueden incluir rutas/errores internos; no credenciales |
| SEC-034 | Manifiesto fuente y fusionado revisados; backup excluye BD y preferencias | Manifiestos, reglas XML y reporte del *manifest merger* | `READ_MEDIA_*` aportados por `open_filex`; evaluar acotarlos (decisión del propietario) |
| SEC-036 | 121 paquetes hosted inventariados; 0 advisories en OSV a la fecha | `flutter pub deps` + consulta OSV `querybatch` | Foto del 18/10/2026; re-ejecutar en CI/Dependabot |
| SEC-037 | Jobs de secret scanning (Gitleaks v3) y SCA (OSV-Scanner v2.7.0) implementados en CI | `.github/workflows/ci.yml` (commit `a176041`) + YAML validado localmente (10/10 comprobaciones) | Canario de aceptación pendiente del primer push (entorno local sin push) |
| SEC-039 | Sin deep links ni schemes; componentes exportados acotados | Manifiestos + providers/receivers del manifiesto fusionado | Reevaluar si una fase futura agrega deep links (p. ej., pagos) |

---

## 2. SEC-011 — Secret scanning del árbol y de la historia

### 2.1 Herramientas

No hay `gitleaks`, `trufflehog` ni `osv-scanner` instalados en el entorno (`Get-Command` sin resultados). Se aplicó un barrido por patrones de alta señal sobre archivos versionados y sobre la historia, más la revisión de nombres de archivo sensibles.

### 2.2 Comandos y salida sanitizada

| Comando | Resultado |
|---|---|
| `git grep -n -I -e '-----BEGIN' -- .` | 0 coincidencias (sin bloques de clave privada/certificado) |
| `git grep -n -I -E '(AKIA\|ASIA)[0-9A-Z]{16}' -- .` | 0 coincidencias (sin claves AWS) |
| `git grep -n -I -E 'AIza[0-9A-Za-z_-]{35}' -- .` | 0 coincidencias (sin API keys de Google) |
| `git grep -n -I -E 'sk_live_[0-9A-Za-z]{16,}' -- .` | 0 coincidencias |
| `git grep -n -I -E 'eyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}' -- .` | 0 coincidencias de JWT con formato completo |
| `git log --all --name-only --pretty=format:` + filtro `key.properties\|*.jks\|*.keystore\|*.env\|*.pem\|*.p12\|*.pfx` | 0 archivos sensibles versionados en 42 commits |
| `git log --all --oneline -G'-----BEGIN [A-Z ]*PRIVATE KEY-----'` | 0 commits |
| `git log --all --oneline -G'(AKIA\|ASIA)[0-9A-Z]{16}'` | 0 commits |
| `git log --all --oneline -S'api_key'` / `-S'apiKey'` / `-S'token='` / `-S'BEGIN RSA PRIVATE KEY'` | 0 commits |
| `git log --all --oneline -S'storePassword=' -- android` | 1 commit: `b2af7a9` (baseline); corresponde solo a `android/key.properties.example` con marcadores `CAMBIAR_PASSWORD_KEYSTORE` / `CAMBIAR_PASSWORD_CLAVE` y `upload-keystore.jks` (placeholders, no credenciales) |
| `Test-Path android/key.properties` | `False` (no existe en el entorno) |
| `git check-ignore -v --no-index android/key.properties` | Ignorado por `android/.gitignore:12` (y por `/android/key.properties` en `.gitignore:47`) |

**Barrido de credenciales hardcodeadas** (`password|passwd|contraseña` con asignación a literal): 8 coincidencias, **todas en `test/` y sintéticas**:

- `test/biometric_login_test.dart:284,313`
- `test/qr_administrativo_seguridad_test.dart:100,114`
- `test/caja_ciclo_operativo_seguridad_test.dart:34,48`
- `test/phase5_architecture_reports_performance_test.dart:380`
- `test/phase4_security_resources_test.dart:228`

No son credenciales de producción: son contraseñas de datos de prueba creados por la propia suite.

### 2.3 Conclusión y limitación

- **Resultado:** sin evidencia de secretos reales versionados ni introducidos en la historia.
- **Limitación:** un barrido por patrones no cubre todos los formatos posibles de secretos; no hubo scanner dedicado local. La mitigación implementada es el job de SEC-037 (Gitleaks; commit `a176041`), con el canario de aceptación pendiente del primer push.
- **Riesgo residual:** bajo para el estado actual; medio si en el futuro se introducen credenciales con formatos no cubiertos y no se habilita el escaneo en CI.

---

## 3. SEC-013 — Persistencia local (inspección estática)

### 3.1 Inventario de almacenamiento

| Dato | Ubicación | Protección / contenido | Evidencia |
|---|---|---|---|
| Clave de la base SQLCipher | `flutter_secure_storage` (Android Keystore / iOS Keychain) | 32 bytes aleatorios; se crea si no existe | `lib/core/database/database_helper.dart:27-44` |
| Usuario recordado | `flutter_secure_storage` | Solo `username` y `user_id`; **nunca** contraseña | `lib/core/storage/secure_auth_store.dart:24-44` |
| Permiso de acceso con huella | `flutter_secure_storage` | Bandera `'1'`; se revoca al cerrar sesión | `lib/core/storage/secure_auth_store.dart:46-61` |
| Clave de respaldos locales automáticos | `flutter_secure_storage` | 32 bytes aleatorios (`local_backup_encryption_key_v1`) | `lib/features/backup/application/backup_service.dart:32,499-505` |
| Respaldos automáticos locales | `getApplicationSupportDirectory()/backups` | Cifrados con la clave anterior; se conservan 7 | `lib/features/backup/application/backup_service.dart:507-527` |
| Respaldo portátil `.kpzbackup` | Archivo elegido por el usuario | AES-256-GCM + PBKDF2; passphrase mínima de 12 caracteres | `lib/features/backup/application/backup_service.dart:20,34-58,161-234` |
| QR de ventas | `Documentos/configuracion/qr_ventas_<epoch>.<ext>` | Imagen de cobro (dato de negocio, no credencial) | `lib/screens/configuracion/configuracion_negocio_screen.dart:107-130` |
| Boletas PDF | `Documentos/boletas/boleta_<id>.pdf` | Documento de venta persistente | `lib/services/pos_service.dart:257-262,663,697-701` |
| Arqueo y reportes PDF | Directorio temporal | Se regeneran; no son fuente de verdad | `lib/services/caja_service.dart:834-837`; `lib/features/reporting/application/reportes_pdf.dart:498-503` |

### 3.2 Verificaciones

- `shared_preferences` / `SharedPreferences`: **0 usos en `lib/`**. La app no usa preferencias ordinarias para credenciales.
- `writeAsString`: **0 coincidencias** en `lib/`.
- `writeAsBytes`: solo PDFs (boletas/arqueo/reportes), respaldos cifrados y extracción de assets durante un restore; no se escriben contraseñas ni tokens.
- Las reglas de backup de Android excluyen `database` y `sharedpref` (`android/app/src/main/res/xml/backup_rules.xml:5-6`; `data_extraction_rules.xml:5-12`), coherente con `allowBackup="false"`.
- El flujo de login no persiste la contraseña: el usuario recordado solo guarda nombre e id; el acceso con huella revalida la sesión contra la base (`AuthService.loginRapido`).

### 3.3 Conclusión y límite

- **Resultado:** sin credenciales en claro en almacenamiento ordinario; las claves criptográficas viven en almacenamiento seguro del dispositivo.
- **Límite:** esta es una inspección estática. La verificación funcional de cifrado, restore y archivos en un dispositivo real corresponde a `FS-7` (SEC-014).
- **Riesgo residual:** un dispositivo con root/Keystore comprometido queda fuera del modelo de defensa local-only (S2); la app no promete resistencia a un atacante con control físico/root.

---

## 4. SEC-032 — Barrido de logs

### 4.1 Conteo y revisión

- Llamadas de log en `lib/`: **6** `debugPrint` (3 sitios, mensaje + stack trace); **0** `print` y **0** `developer.log`.

| Archivo:línea | Contenido registrado |
|---|---|
| `lib/controllers/pos_controller.dart:327-328` | Mensaje de error de `procesarCobro` + `stackTrace` |
| `lib/screens/pos/widgets/pos_cobro_sheet.dart:209-210` | Mensaje de error de `_confirmarCobro` + `stackTrace` |
| `lib/services/pos_service.dart:222-225` | `ventaId` + error de generación de boleta + `stackTrace` |

### 4.2 Barrido de secretos

Regex aplicada sobre las llamadas de log: `password|passwd|contrase|token|authorization|secret|api[_-]?key|bearer` → **0 coincidencias**.

### 4.3 Conclusión y límite

- **Resultado:** no se registran credenciales, tokens, payloads de pago ni datos personales. Solo mensajes de error y trazas técnicas.
- **Límite:** una excepción de SQLite/SQLCipher podría incluir rutas o fragmentos de SQL en la traza; no se observaron credenciales. Los logs de Android son accesibles con depuración USB y no se consideran un canal seguro.
- **Riesgo residual:** bajo. Si en el futuro se agrega telemetría o se registran payloads, aplicar redacción/allowlist.

---

## 5. SEC-034 — Manifiesto Android, componentes y backup

### 5.1 Manifiestos fuente

| Archivo | Hallazgos |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Solo `USE_BIOMETRIC`; `allowBackup="false"`; `fullBackupContent` y `dataExtractionRules`; `MainActivity` `exported="true"` con **solo** `MAIN`/`LAUNCHER`; `queries` para `PROCESS_TEXT` y `GET_CONTENT`; **sin** `INTERNET`; **sin** `usesCleartextTraffic` ni `networkSecurityConfig` |
| `android/app/src/debug/AndroidManifest.xml` | `INTERNET` (solo tooling de Flutter: hot reload/debug) |
| `android/app/src/profile/AndroidManifest.xml` | `INTERNET` (solo perfil) |

`MainActivity` extiende `FlutterFragmentActivity` (`android/app/src/main/kotlin/com/kimipizza/pos/MainActivity.kt`), requisito de `local_auth`; el label es `Kimi Pizza POS` y el `applicationId`/namespace es `com.kimipizza.pos` (`android/app/build.gradle.kts:18,29`).

### 5.2 Manifiesto fusionado (artefacto debug local)

Ruta: `build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml` (generado por el build debug de `FS-11`; no es un artefacto release).

**SDK:** `minSdkVersion 24`, `targetSdkVersion 36`.

**Permisos efectivos y atribución (reporte del merger):**

| Permiso | Origen | Observación |
|---|---|---|
| `USE_BIOMETRIC` | manifiesto propio | Acceso con huella (`local_auth`) |
| `USE_FINGERPRINT` | `androidx.biometric:1.1.0` | Compatibilidad con API antigua; normal en biometría |
| `READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`) | `open_filex` | Para abrir PDFs en Android antiguo |
| `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` / `READ_MEDIA_AUDIO` | `open_filex` | **Observación:** la app solo abre PDFs e imágenes; `VIDEO`/`AUDIO` no son necesarios. Evaluar acotarlos con `tools:node="remove"` en una fase autorizada (no se modificó nada aquí) |
| `INTERNET` | `src/debug` | Solo debug; **no** está en `src/main` |
| `com.kimipizza.pos.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | `androidx.core:1.18.0` | Permiso `signature` para receivers dinámicos; no expone datos |

**Componentes:**

| Componente | `exported` | Detalle |
|---|---|---|
| `com.kimipizza.pos.MainActivity` | `true` | Launcher (`MAIN`/`LAUNCHER`); sin `<data>` ni deep links |
| `io.flutter.plugins.imagepicker.ImagePickerFileProvider` | `false` | `grantUriPermissions=true`; autoridad `com.kimipizza.pos.flutter.image_provider` |
| `com.crazecoder.openfile.FileProvider` | `false` | `grantUriPermissions=true`; usado por `open_filex` para abrir PDFs |
| `dev.fluttercommunity.plus.share.ShareFileProvider` | `false` | `grantUriPermissions=true`; comparte PDFs vía chooser |
| `dev.fluttercommunity.plus.share.SharePlusPendingIntent` (receiver) | `false` | Resultado del chooser de compartir |
| `com.google.android.gms.metadata.ModuleDependencies` (service) | `false` | `enabled="false"`; soporte del photo picker |
| `androidx.startup.InitializationProvider` | `false` | Inicializadores de AndroidX |
| `androidx.profileinstaller.ProfileInstallReceiver` | `true` | Protegido por `android.permission.DUMP` (firma/sistema); acciones de perfil, sin datos de la app |

**Backup:** `allowBackup="false"`, `fullBackupContent=@xml/backup_rules` y `dataExtractionRules=@xml/data_extraction_rules`; ambas reglas excluyen `database` y `sharedpref` en cloud backup y device transfer.

**Cleartext:** no hay `usesCleartextTraffic` ni `networkSecurityConfig`; con `targetSdk 36` aplica el bloqueo de cleartext por defecto de Android.

**Debug:** el manifiesto fusionado debug contiene `android:debuggable="true"` (esperado). La ausencia de `debuggable` en release se valida sobre el artefacto firmado en `FS-7` (SEC-035).

### 5.3 Conclusión y observación

- **Resultado:** componentes sin exposición innecesaria; `MainActivity` exportada solo por el launcher; providers `exported=false`; receiver del sistema protegido por `DUMP`; backup alineado con RN-08.
- **Observación (no defecto de esta fase):** `READ_MEDIA_VIDEO` y `READ_MEDIA_AUDIO` provienen de `open_filex`, no del código de la app. Acotarlos requeriría editar `android/` (fase nueva aprobada) y validar que `open_filex` siga funcionando; se deja como decisión del propietario para `FS-7`/corrección posterior.
- **Límite:** revisión estática sobre el manifiesto fuente y el fusionado debug; el manifiesto release firmado se revisa en `FS-7`.

---

## 6. SEC-036 — Inventario de dependencias y advisories

### 6.1 Inventario

- `flutter pub deps --style=compact`: salida de 135 líneas.
- `pubspec.lock`: **121 paquetes hosted** (directos + transitivos; incluye dev).
- Dependencias directas de producción: **16** — `archive`, `cryptography`, `file_picker`, `sqflite_sqlcipher`, `path`, `path_provider`, `provider`, `image_picker`, `share_plus`, `crypto`, `flutter_secure_storage`, `intl`, `google_fonts`, `pdf`, `open_filex`, `local_auth`.
- Dependencias directas de desarrollo: **3** — `flutter_lints`, `mocktail`, `sqflite_common_ffi`.

Versiones clave observadas: `flutter_secure_storage 11.2.0`, `local_auth 3.0.2`, `sqflite_sqlcipher 3.4.1`, `image_picker 1.2.3`, `file_picker 13.1.0`, `share_plus 13.3.0`, `open_filex 4.7.0`, `google_fonts 9.0.0`, `cryptography 2.9.0`, `pdf 3.13.1`, `provider 6.1.5+1`.

### 6.2 Advisories

Se consultó la API OSV (`POST https://api.osv.dev/v1/querybatch`, ecosistema `Pub`) para los **121** paquetes hosted de `pubspec.lock`:

```
Consultando OSV para 121 paquetes...
Paquetes con advisories: 0
```

No se encontraron advisories conocidos para las versiones bloqueadas a la fecha de la consulta.

### 6.3 Observaciones y limitaciones

- `google_fonts` incorpora `http` como dependencia transitiva, pero `GoogleFonts.config.allowRuntimeFetching = false` (`lib/main.dart:71`) y el manifiesto de producción no declara `INTERNET`; no hay descarga de fuentes en runtime.
- La consulta OSV es una **foto** del 18/10/2026. No hay `osv-scanner` local ni configuración de Dependabot (`.github/dependabot.yml` no existe). Desde el 18/10/2026 el job `dependency-scan` de CI (SEC-037, commit `a176041`) re-ejecuta los advisories sobre `pubspec.lock` en cada push/PR, lo que mantiene la evidencia vigente sin depender de una revisión manual.
- No se realizaron upgrades ni cambios de dependencias en esta fase.

---

## 7. SEC-037 — Escaneo de secretos y advisories en CI

### 7.1 Implementación (18/10/2026, aprobación del propietario)

La propuesta de §7.2 fue **aprobada por el propietario** y quedó implementada en el commit `ci:` `a176041`. `.github/workflows/ci.yml` declara `permissions: contents: read` a nivel de workflow y agrega dos jobs; el job `validate` conserva sus pasos con refs actualizados.

- **`secret-scan`:** `actions/checkout@v7` con `fetch-depth: 0` (historia completa) y `gitleaks/gitleaks-action@v3` (runtime Node 24) con `GITHUB_TOKEN`. `GITLEAKS_ENABLE_COMMENTS: 'false'` porque el token es de solo lectura: el hallazgo se reporta en el log y el resumen del job, y el check falla; no se publican comentarios en el PR.
- **`dependency-scan`:** workflow reusable recomendado por Google (`google/osv-scanner-action/.github/workflows/osv-scanner-reusable.yml@v2.7.0`) con `scan-args: --lockfile=pubspec.lock` (Dart soportado: `pubspec.lock`/`package_config.json`). Permisos del job: `actions: read`, `contents: read`, `security-events: write` (SARIF a "Code scanning"); `fail-on-vuln` por defecto falla el check si hay vulnerabilidades.
- **`validate` (mantenimiento):** `actions/checkout@v4` → `@v7` y `actions/setup-java@v4` → `@v6`; esos majors corrían sobre Node 20, retirado de los runners de GitHub el 16/09/2026 según la documentación vigente de los actions. `subosito/flutter-action@v2` se mantiene (versión vigente según su README). Sin cambios de pasos ni de comportamiento.
- **Ajuste frente a la propuesta original:** la propuesta usaba `gitleaks/gitleaks-action@v2` (inservible tras la retirada de Node 20) y la acción compuesta `google/osv-scanner-action@v2` (desaconsejada por su README en favor de los reusable workflows). Se implementó la forma vigente conservando el diseño aprobado: canario de secretos + SCA sobre `pubspec.lock`.
- **Validación local:** YAML parseado con el paquete `yaml` 3.1.4 de Dart y estructura comprobada (3 jobs; `contents: read`; `fetch-depth: 0`; `--lockfile=pubspec.lock`; `security-events: write`): 10/10 comprobaciones OK. GitHub Actions no se ejecuta en local; la ejecución real ocurre en el primer push.

### 7.2 Propuesta original del 18/10/2026 (aprobada; referencia histórica)

> El estado descrito en este apartado corresponde al momento de la propuesta; la implementación vigente está en §7.1. La propuesta se aprobó y se implementó en un commit `ci:` separado (`a176041`).

```yaml
permissions:
  contents: read

jobs:
  secret-scan:
    name: Escaneo de secretos
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  dependency-scan:
    name: Advisories de dependencias
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: OSV-Scanner (pubspec.lock)
        uses: google/osv-scanner-action@v2
        with:
          scan-args: |-
            --lockfile=pubspec.lock
```

**Criterio de aceptación del canario (secret scanning):**

1. En una rama/PR de prueba, agregar un archivo temporal con un secreto **falso** (por ejemplo, una cadena con formato de clave) y verificar que el job falla y lo reporta redactado.
2. Confirmar que el mismo job pasa en la rama limpia (sin el archivo).
3. Eliminar el archivo de prueba; nunca usar un secreto real ni dejarlo en la historia.

**Alternativa/complemento:** habilitar Dependabot para el ecosistema `pub` (alertas y PRs de actualización) y/o `osv-scanner` como paso del job `validate`. Requiere decisión del propietario por el consumo de minutos de CI y el flujo de actualizaciones.

### 7.3 Canario de aceptación y estado

- **Canario (pendiente del primer push):** el criterio 1–3 descrito en §7.2 se ejecuta cuando el propietario empuje una rama/PR de prueba; el entorno de esta edición trabaja solo local (sin push).
- **Implementado** (commit `a176041`); la propuesta original queda superada por la implementación descrita en §7.1.
- El job `dependency-scan` re-ejecuta además los advisories de SEC-036 en cada push/PR.

---

## 8. SEC-039 — Deep links e intents

### 8.1 Entrada (deep links)

- Manifiestos Android: **sin** `<data android:scheme=...>`, **sin** `android:host`, **sin** `autoVerify`; el único `intent-filter` es `MAIN`/`LAUNCHER` de `MainActivity` (`android/app/src/main/AndroidManifest.xml:29-32`).
- No existe carpeta `ios/` ni `web/` en el proyecto: no hay URL schemes de iOS ni manifest web que revisar.
- `queries` del manifiesto: `PROCESS_TEXT` y `GET_CONTENT` (visibilidad para selección de archivos/texto), no recepción de intents.
- No hay actividades/servicios/receivers de la app que reciban datos externos.

### 8.2 Salida (intents/providers)

- `open_filex` abre PDFs locales mediante `FileProvider` `exported=false` (`lib/screens/reportes/reportes_screen.dart:133`; `lib/screens/pos/widgets/pos_venta_exitosa_dialog.dart:215`; `lib/screens/pos/widgets/pos_historial_boletas_sheet.dart`).
- `share_plus` comparte PDFs con el chooser del sistema (`pos_venta_exitosa_dialog.dart:251`; `pos_historial_boletas_sheet.dart`), también con provider `exported=false`.
- No se aceptan URIs/content de terceros en la app; las rutas compartidas son archivos generados localmente.

### 8.3 Conclusión

- **Resultado:** superficie de deep links **nula**; componentes exportados acotados al launcher y a un receiver del sistema protegido por `DUMP`.
- **Límite/riesgo residual:** si una fase futura (por ejemplo, pagos digitales) introduce deep links o App Links, deberá validar esquema/host, firma del emisor, idempotencia y tratamiento de contenido no confiable (S6).

---

## 9. Reproducción de la evidencia

```powershell
# SEC-011 (árbol versionado)
git grep -n -I -e '-----BEGIN' -- .
git grep -n -I -E '(AKIA|ASIA)[0-9A-Z]{16}' -- .
git grep -n -I -E 'AIza[0-9A-Za-z_-]{35}' -- .
git grep -n -I -E 'sk_live_[0-9A-Za-z]{16,}' -- .
git grep -n -I -E 'eyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}' -- .

# SEC-011 (historia y archivos sensibles)
git log --all --name-only --pretty=format: | Sort-Object -Unique |
  Select-String -Pattern 'key\.properties|\.jks$|\.keystore$|\.env$|\.pem$|\.p12$|\.pfx$'
git log --all --oneline -G'-----BEGIN [A-Z ]*PRIVATE KEY-----'
git log --all --oneline -G'(AKIA|ASIA)[0-9A-Z]{16}'
git log --all --oneline -S'storePassword=' -- android
Test-Path android/key.properties
git check-ignore -v --no-index android/key.properties

# SEC-013 / SEC-032
git grep -n -i -E '(print|debugPrint|developer\.log)\s*\(.*(password|contrase|token|authorization|secret|api[_-]?key|bearer)' -- lib
git grep -n -E 'SharedPreferences|shared_preferences|writeAsString' -- lib

# SEC-034 / SEC-039
Get-ChildItem android/app/src -Recurse -Filter AndroidManifest.xml
Get-Content android/app/src/main/AndroidManifest.xml
Get-Content build/app/outputs/logs/manifest-merger-debug-report.txt | Select-String 'READ_MEDIA|USE_FINGERPRINT|ProfileInstallReceiver'

# SEC-036
flutter pub deps --style=compact
# Consulta OSV (querybatch) sobre las 121 entradas hosted de pubspec.lock;
# resultado de esta fase: 0 advisories (18/10/2026).
```

---

## 10. Cierre de la fase

- Fase **solo-documentación** (ejecución original): no se modificaron `lib/`, `android/`, `test/` ni `.github/`; por regla de la edición, no se re-ejecutó la suite ni `flutter analyze`. **Reanudación (18/10/2026):** con aprobación del propietario se implementó SEC-037 en `.github/workflows/ci.yml` (commit `a176041`), única modificación de configuración; tampoco hubo cambio de código, por lo que el gate de suite/analyze se omite con constancia (última puerta verde: `FS-7A`, **144/144**; analyze 0).
- Evidencia sanitizada por caso registrada arriba y enlazada desde `SECURITY_CONTROL_MATRIX.md`, `SECURITY_TEST_PLAN.md`, `SECURITY_ACTION_PLAN.md` y `SECURITY_PHASE_PROMPTS.md`.
- **Decisiones pendientes del propietario:** evaluar el acotamiento de `READ_MEDIA_VIDEO`/`READ_MEDIA_AUDIO` en una fase autorizada (SEC-033/`FS-7`). SEC-037 quedó resuelta: aprobada e implementada (commit `a176041`); solo el canario de aceptación espera el primer push.
- **Siguiente fase:** `FS-6` — acceso, cuentas y sesión (SEC-001…SEC-010), con los riesgos residuales ya identificados (SEC-002, SEC-007/008).
