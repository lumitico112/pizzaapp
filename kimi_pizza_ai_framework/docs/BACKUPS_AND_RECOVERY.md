# Copias de seguridad, recuperación y política Android Auto Backup (`RN-08`, `RN-09`)

## Objetivo

La aplicación funciona sin servidor y pertenece a una sola dueña (`com.kimipizza.pos` — **Kimi Pizza POS**). Las copias deben servir para recuperar el móvil actual y para trasladar la información a otro dispositivo sin exportar la clave de SQLCipher del teléfono.

## Política oficial frente a Android Auto Backup (`RN-08` / `C-20`)

- La clave de 256 bits de SQLCipher reside en `FlutterSecureStorage` respaldada por Android Keystore y no se transfiere automáticamente a otro dispositivo cuando Android Auto Backup restaura archivos desde la nube.
- Por ello, **se excluye `pizzaapp_secure.db` de Android Auto Backup** (`dataExtractionRules` y `fullBackupContent` / `allowBackup="false"`), evitando que una restauración del sistema operativo deje una base de datos inaccesible por falta de clave.
- El **único mecanismo oficial de migración y respaldo** entre teléfonos es el archivo portátil cifrado `.kpzbackup`.

## Copia portátil (`.kpzbackup`)

- Se crea desde el Dashboard: abre el **menú lateral → Copias de seguridad → Exportar copia para transferir**.
- En un móvil nuevo, se puede abrir **Restaurar una copia** desde la bienvenida antes de configurar la cuenta. Al terminar, la app vuelve al login usando la cuenta incluida en la copia.
- La exportación completa y la restauración de copias locales solo aparecen después de entrar a la app.
- El archivo `.kpzbackup` contiene las filas de las tablas de la app, configuración y los archivos locales referenciados por rutas (imágenes, QR, fotos y comprobantes disponibles).
- El contenido se empaqueta en ZIP y se cifra con AES-256-GCM. La clave se deriva de una contraseña elegida para esa copia mediante PBKDF2-HMAC-SHA256 (310 000 iteraciones y salt aleatorio, ejecutado en `Isolate.run` para no bloquear el hilo de UI — `C-17`). Se requiere una contraseña de al menos 12 caracteres.
- La clave de SQLCipher del teléfono nunca se escribe en el archivo portátil. Al restaurar, los datos se insertan en la base cifrada del dispositivo que recibe la copia.

## Copia local periódica

- Tras crear la cuenta propietaria, la app genera una copia diaria cifrada en el almacenamiento privado de la aplicación (diferida fuera del arranque crítico para evitar bloqueo de UI — `C-17`).
- La comprobación se realiza al iniciar y cada hora mientras la app permanece abierta; solo escribe una copia cuando ya cambió el día.
- La clave aleatoria de estas copias se guarda en almacenamiento seguro del mismo teléfono. Se conservan las siete copias más recientes.
- Estas copias sirven para errores en el móvil actual; no sirven por sí solas si se pierde/reinstala el móvil o se borra su almacenamiento seguro. Para esos casos se necesita una copia portátil fuera del dispositivo.

## Restauración e higiene de sesión (`C-18`)

- Antes de restaurar, se verifica la autenticidad del archivo y su contraseña.
- La app crea primero una copia local del estado actual.
- **Después de restaurar, se cierra obligatoriamente la sesión en memoria, se limpia el carrito (`PosController`) y se reinician los controladores activos** antes de volver al login para que la dueña autentique la cuenta recuperada.
- Los archivos se extraen al directorio privado administrado por la app; las referencias guardadas en las filas/configuración se actualizan a las nuevas rutas.
- La sustitución de registros se ejecuta en una transacción, garantizando que `PRAGMA foreign_keys` vuelva a su estado activo en un bloque `finally`. Si falla, SQLite revierte los cambios de datos.
