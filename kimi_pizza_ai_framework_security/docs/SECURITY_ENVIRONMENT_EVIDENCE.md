# Evidencia de evaluación de seguridad — Casos dependientes de entorno (FS-7)

> **Fecha documental:** 18/10/2026 · **Sesión de ejecución:** 19/10/2026 (reloj del equipo; el archivo exportado conserva su marca `kimi_pizza_2026-10-19`) · **Fase:** `FS-7`, reanudada tras `FS-7A` · **Ámbito:** dispositivo físico y APK release de prueba.
>
> **Naturaleza de la evidencia:** resultados redactados de una ejecución manual asistida por ADB, con datos **sintéticos** (negocio y usuario de prueba) y sin credenciales versionadas. No convierte por sí sola ningún control en "Implementado": falta la revisión humana y, donde corresponda, la ratificación del propietario en `FS-8`.

## 1. Entorno, artefactos y herramientas

| Elemento | Detalle |
|---|---|
| Dispositivo | Motorola Edge 60 Fusion (físico), Android 16 / API 36 |
| Fuente | HEAD `e3e2fc5` (rama `refactor/auditoria-2026-10`, árbol limpio, sin push) |
| APK debug | `flutter build apk --debug --no-pub` (101,4 s) → `app-debug.apk`; instalado con `adb install -r` sobre la instalación previa (conserva datos) |
| APK release | `flutter build apk --release --no-pub` (150,0 s) → `app-release.apk` (84 596 106 bytes) |
| Firma de prueba | `android/kimi-fs7-test.jks` (alias `kimi-fs7`) con `android/key.properties` **local e ignorado por git**; se ajustó `storeFile=../kimi-fs7-test.jks` porque Gradle resuelve `storeFile` relativo al módulo `app` (la ruta anterior fallaba en `:app:validateSigningRelease`) |
| Herramientas | `adb` (platform-tools), `aapt2` 2.20-13193326 (build-tools 36.0.0), `apksigner` 36.0.0, Gradle 9.3.1 (Flutter) con JBR de Android Studio |
| Datos | Negocio sintético `Kimi Pizza Test`; usuario administrador `admin`; frase de respaldo de prueba de 14 caracteres (definida para la sesión, **no versionada**) |

## 2. DEF-FS7-01 — re-verificación en dispositivo

1. La instalación previa quedó reemplazada por el APK debug reconstruido desde `e3e2fc5` (incluye la corrección de `FS-7A`).
2. Flujo ejecutado en debug: `Copias de seguridad → Exportar copia para transferir → Cancelar`.
   - El diálogo "Proteger copia portátil" se abre y cancela; la app vuelve a la pantalla de respaldo.
   - `logcat` sin `A TextEditingController was used after being disposed`, sin `_dependents.isEmpty` y sin `Tried to build dirty widget`.
3. El mismo flujo se repitió en el **release** firmado, con idéntico resultado (sin excepciones).
4. La regresión `test/respaldo_dialogo_seguridad_test.dart` (5 pruebas) sigue verde en la suite de cierre (**144/144**).

**Resultado:** defecto corregido y re-verificado en dispositivo (debug y release).

## 3. SEC-012 — Inspección del APK de release

`aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk` (extracto literal):

- `package: name='com.kimipizza.pos' versionCode='20' versionName='2.0.0'`
- `minSdkVersion:'24'` · `targetSdkVersion:'36'`
- `application-label:'Kimi Pizza POS'`
- Permisos declarados (`badging`): `USE_BIOMETRIC`, `USE_FINGERPRINT`, `READ_EXTERNAL_STORAGE` (maxSdk 32), `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO` y el permiso interno de receptores dinámicos `com.kimipizza.pos.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; el gestor de paquetes añade además `READ_MEDIA_VISUAL_USER_SELECTED` como solicitado. **Sin `INTERNET`, sin `CAMERA`, sin `WRITE_EXTERNAL_STORAGE`.**

`aapt2 dump xmltree … --file AndroidManifest.xml` (extracto):

- `android:allowBackup=false`
- `android:fullBackupContent=@0x7f110000` y reglas de extracción declaradas
- Sin atributo `debuggable` y sin `usesCleartextTraffic`

`adb shell run-as com.kimipizza.pos ls` → `run-as: package not debuggable: com.kimipizza.pos`.

**Resultado:** el artefacto release no incrusta secretos de servidor, no declara red ni cámara, mantiene la política de backup de `RN-08` y no es debuggable. Residual: firma de producción a cargo del propietario.

## 4. SEC-014 — Exportación y restauración de `.kpzbackup`

### 4.1 Exportación por SAF

- Flujo: `Copias de seguridad → Exportar copia para transferir` → frase de respaldo (dos campos, 14 caracteres) → `Continuar` → selector SAF del sistema abierto en **Descargas** con el nombre propuesto `kimi_pizza_2026-10-19.kpzbackup` → `GUARDAR`.
- Archivo resultante: `20 593 bytes`, marca `2026-10-19 14:20`.
- Cabecera binaria: `4b 50 5a 42 01 00 00 00 50 7b 22 66 6f 72 6d 61` → `KPZB` + versión 1 + byte de tipo `0x50` + envoltura `{"formatVersion":1,"salt":"…","nonce":"…"}` (sal y nonce aleatorios, redactados), seguida de ciphertext.
- Barrido de marcadores sobre el archivo completo: la frase de respaldo de la sesión → ausente; `Kimi Pizza Test` → ausente; `SQLite format 3` → ausente; `PRAGMA` → ausente; `admin` → ausente; `contrase` → ausente.

### 4.2 Ruta negativa (frase incorrecta)

- Se cambió el nombre del negocio a un valor distinguible (`KimiPizzaTMP`, verificado en Configuración).
- Restauración con frase incorrecta → confirmación "Reemplazar datos" → intento → **SnackBar "La contraseña no es correcta."**
- Verificación posterior en Configuración: el nombre siguió siendo `KimiPizzaTMP` → **ningún dato fue reemplazado**.

### 4.3 Ruta positiva (frase correcta)

- Restauración con la frase correcta → la app cerró la sesión y volvió al login, que ya mostraba **KIMI PIZZA TEST**.
- Inicio de sesión con el usuario sintético y verificación en Configuración: el nombre persistido volvió a `Kimi Pizza Test` → **reemplazo de datos confirmado**.

### 4.4 Restauración cruzada tras reinstalación (release, keystore nuevo)

- `adb uninstall com.kimipizza.pos` (elimina datos y alias del keystore de la app) → `adb install app-release.apk` (`firstInstallTime = lastUpdateTime`) → **modo avión activo** (`airplane_mode_on=1`).
- Primer arranque: onboarding ("Bienvenido a PizzaApp") → **"Ya tengo una copia para restaurar"** → selector SAF → la misma copia → frase correcta → "Reemplazar datos" → login con **KIMI PIZZA TEST**.
- Inicio de sesión y dashboard correctos, sin conexión.

**Resultado:** el `.kpzbackup` es exportable, verificable, no revela marcadores en claro y restaura de forma segura (incluido el cruce a una instalación nueva y sin red). La restauración de la copia automática local no se ejecutó en esta sesión (opcional; su `.kpzlocal` ya se inspeccionó cifrado en la ejecución parcial).

## 5. SEC-015 / SEC-016 — Release sin red

- Manifiesto release sin `INTERNET` y sin endpoints (el proyecto no tiene backend ni sincronización): sin superficie HTTP/TLS que evaluar hoy.
- Con **modo avión activo**, el release completó arranque, onboarding, restauración del respaldo, login y dashboard → operación 100 % offline.
- **SEC-016** no aplica mientras no exista tránsito de red; no aplicabilidad ratificada en `FS-8` (R-01).

## 6. SEC-033 — Permisos efectivos (release)

`adb shell dumpsys package com.kimipizza.pos` (extracto):

- **Solicitados:** `READ_MEDIA_VISUAL_USER_SELECTED`, `READ_MEDIA_IMAGES`, `READ_MEDIA_AUDIO`, `READ_MEDIA_VIDEO` (de `open_filex`), `USE_FINGERPRINT`, `USE_BIOMETRIC`.
- **Concedidos en instalación:** `USE_FINGERPRINT=true`, `USE_BIOMETRIC=true`.
- **Runtime:** los cuatro `READ_MEDIA_*` figuran `granted=false`; la app funciona sin ellos porque usa Photo Picker (galería) y SAF (respaldo).
- No hay `CAMERA`, `INTERNET` ni `WRITE_EXTERNAL_STORAGE`.

**Residual:** decidir y, si se aprueba, ejecutar el acotamiento de `READ_MEDIA_VIDEO`/`READ_MEDIA_AUDIO` que aporta `open_filex` (fase autorizada; sin afectar la selección de imágenes).

## 7. SEC-035 — Artefacto release firmado

`apksigner verify --verbose --print-certs` sobre `app-release.apk` (extracto):

- `Verifies` · v1: `false` · **v2: `true`** · v3/v4: `false` · 1 firmante.
- Certificado: `CN=Kimi Pizza FS7 Test, OU=Security, O=Kimi Pizza, L=Lima, ST=Lima, C=PE` (SHA-256 `bdeda2c3…`, RSA 2048).
- Contraste con el APK debug: `CN=Android Debug` (SHA-256 `bd266716…`) → el release **no** usa la clave de depuración.
- Sin `debuggable` y `run-as` rechazado (ver §3).

**Residual:** la firma de producción definitiva queda a cargo del propietario; el keystore de prueba es local, reemplazable y no se versiona.

## 8. SEC-038 — Exportaciones y compartición

- **Copia portátil:** acción explícita ("Exportar copia para transferir") y destino elegido por el usuario en el selector SAF; el nombre propuesto es un archivo simple (`kimi_pizza_2026-10-19.kpzbackup`), sin rutas absolutas ni carpetas amplias.
- **PDF de reportes:** "Exportar PDF" genera el documento y lo abre en el visor del sistema mediante el proveedor del plugin:
  `content://com.kimipizza.pos.fileProvider.com.crazecoder.openfile/cache-path/reporte_<epoch>.pdf`
  (ruta `cache-path` privada de la app; el visor muestra solo el nombre del archivo). No se escribió nada en `/sdcard/Documents` ni en `/sdcard/Download` (allí solo permanece la copia portátil).
- El flujo no abre una hoja de compartición genérica a otras apps ni expone rutas del sistema.

**Resultado:** exportaciones explícitas, con destino/nombre controlados y sin filtración accidental de rutas.

## 9. Observaciones y límites

Observaciones (sin corregir; no bloquean la fase):

- **O-FS7-01 (UX):** al guardar Configuración del negocio con el panel lateral abierto detrás de la ruta, el panel mostró el nombre anterior hasta reabrirse; tras la restauración en release el panel mostró el valor correcto. Sin impacto de seguridad.
- **O-FS7-02 (UX/defensa):** la confirmación "Reemplazar datos" aparece antes de validar la frase de la copia; con frase incorrecta el descifrado falla de forma segura ("La contraseña no es correcta.") y no altera datos.
- **O-FS7-03:** la restauración de la copia automática local no se ejecutó en esta sesión.
- **O-FS7-04 (heredada de la ejecución parcial):** el flujo imprime la aserción de depuración `ListTile background color or ink splashes may be invisible`; no tumba la app.

Límites:

- Un único dispositivo físico y datos sintéticos; sin producción.
- Keystore de prueba (no de producción): la ruta positiva de firma queda verificada con un certificado propio reemplazable.
- Sin red por diseño (modo avión): la no aplicabilidad de TLS quedó ratificada documentalmente en `FS-8` (R-01).
- Revisión humana pendiente; esta evidencia no declara conformidad ISO ni cierre definitivo de controles.

## 10. Trazabilidad de comandos (sanitizada)

```text
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb logcat -c && adb shell am start -n com.kimipizza.pos/.MainActivity
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml <temp>
adb shell input tap <x> <y> && adb shell input text "<clave-sintetica>"
adb exec-out screencap -p > <temp>.png
adb shell ls -l /sdcard/Download/kimi_pizza_2026-10-19.kpzbackup
adb shell head -c 16 <archivo> | od -An -c
flutter build apk --release --no-pub
aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk
aapt2 dump xmltree build/app/outputs/flutter-apk/app-release.apk --file AndroidManifest.xml
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
adb shell dumpsys package com.kimipizza.pos
adb shell run-as com.kimipizza.pos ls
adb shell cmd connectivity airplane-mode enable|disable
```

*Fin de la evidencia de `FS-7`.*
