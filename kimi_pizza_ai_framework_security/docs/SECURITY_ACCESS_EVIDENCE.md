# KIMI PIZZA — Evidencia de acceso, cuentas y sesión (FS-6)

**Fecha de ejecución:** 18/10/2026 · **Fase:** `FS-6` · **Casos:** SEC-001…SEC-010 · **Commit de pruebas:** `a482224` · **Alcance:** pruebas de escritorio con `sqflite_common_ffi`; sin cambios en `lib/`, `android/` ni `test/` distinto de la suite nueva.

**Límite de confianza (S2):** la aplicación es local-only. Estas pruebas verifican las defensas implementadas en Dart, SQLite y la UI; no prometen resistencia frente a root, control físico del dispositivo o un APK modificado. Los residuales que requieren decisión del propietario se registran en la sección 5.

---

## 1. Resultado por caso

| Caso | Prueba (archivo:línea) | Resultado | Detalle |
|---|---|---|---|
| SEC-001 | `test/acceso_cuentas_sesion_seguridad_test.dart:119` | ✅ Pasa | Campos vacíos → error de validación sin contar intento; contraseña incorrecta y usuario inexistente → mismo mensaje genérico (`Credenciales incorrectas o usuario inactivo.`); `currentUser` permanece `null`. |
| SEC-002 | `test/acceso_cuentas_sesion_seguridad_test.dart:167` y `:219` | ✅ Pasa (con residual) | 4 fallos → error de credenciales; 5.º → `Demasiados intentos fallidos` (bloqueo 30 s); durante el bloqueo se rechaza incluso la contraseña correcta (`Espera 20 segundos` a los 10 s); al expirar, el login correcto entra y resetea el contador. La instancia nueva de `AuthService` no hereda el bloqueo (residual §5.1). |
| SEC-003 | `test/acceso_cuentas_sesion_seguridad_test.dart:318` | ✅ Pasa (adaptado) | No existen tokens remotos: la sesión vive en memoria. Una instancia nueva de `AuthService` no hereda sesión; tras logout `haySesion` es `false`. |
| SEC-004 | `test/acceso_cuentas_sesion_seguridad_test.dart:318` | ✅ Pasa (adaptado) | `AuthController.logout()` limpia `currentUser`, invoca `onLogout` (vacía el carrito de `PosController`) y deja `haySesion = false`; no hay sesión remota que revocar. |
| SEC-005 | `test/acceso_cuentas_sesion_seguridad_test.dart:261` | ✅ Pasa | Usuarios con `activo = 0` o `bloqueado = 1` no entran por login ni por `loginRapido`; el usuario activo sí entra. Mensaje genérico para no enumerar cuentas. |
| SEC-006 | `test/acceso_cuentas_sesion_seguridad_test.dart:361` | ✅ Pasa | Empleado en la pantalla de usuarios ve `Acceso Restringido` y no ve `Nuevo Usuario`; el servicio rechaza crear (mensaje de permisos) y bloquear (`Solo admin.`). La guarda de ruta es solo de sesión (F9); la autorización por rol se aplica en pantalla y servicios. |
| SEC-007 | `test/acceso_cuentas_sesion_seguridad_test.dart:412` | ✅ Pasa | Un empleado que envía `rol: 'admin'` al editarse sigue siendo `empleado` en la BD. Con un `currentUser` manipulado en memoria a `admin`, `authorizeAdminOperation` revalida contra la BD y rechaza la contraseña del empleado; un admin real sí autoriza. |
| SEC-008 | `test/acceso_cuentas_sesion_seguridad_test.dart:477` | ✅ Pasa | Un empleado no puede editar a otro usuario por ID: excepción de permisos y la fila conserva nombre, username, rol y `password_hash`. Un ID inexistente como admin devuelve `Usuario no encontrado.` sin insertar nada. |
| SEC-009 | `test/acceso_cuentas_sesion_seguridad_test.dart:553` | ✅ Pasa | Empleado no crea ni bloquea; no hay filas nuevas ni auditoría. Admin crea/edita; bloquear, desbloquear, dar de baja y reactivar dejan 4 eventos `USUARIO_*` con el actor. Un disparador temporal que aborta `LogAuditoria` revierte la baja: el usuario sigue activo y no queda auditoría parcial. |
| SEC-010 | `test/acceso_cuentas_sesion_seguridad_test.dart:671` | ✅ Pasa (con observación) | Auto-bloqueo y auto-baja denegados sin cambios ni auditoría; al dar de baja al otro admin queda exactamente 1 admin activo. El código de rescate tiene 4 bloques, se guarda como hash (no en claro), el código incorrecto se rechaza y el correcto cambia la contraseña: la antigua falla y la nueva entra. |

---

## 2. Comandos y salida literal

### 2.1 Suite específica

```text
flutter test --no-pub test/acceso_cuentas_sesion_seguridad_test.dart
...
00:19 +10: All tests passed!
```

### 2.2 Gate completo de la fase

```text
flutter test --no-pub
...
01:34 +139: All tests passed!
```

```text
flutter analyze --no-pub
Analyzing pizzaapp...
No issues found! (ran in 19.9s)
```

**Lectura:** la suite pasa de 129 a **139** pruebas (10 nuevas) y el análisis queda en 0. La última corrida completa se ejecutó después del ajuste de estilo de la suite (import no usado y `!` innecesario); el estado final es el commit `a482224`.

---

## 3. Recorrido de autorización inspeccionado

- **Login y bloqueo:** `lib/services/auth_service.dart:26-116` aplica el contador en memoria (5 intentos / 30 s) antes de autenticar; el mensaje de credenciales es común para usuario inexistente, contraseña incorrecta, inactivo o bloqueado. `loginRapido` revalida `activo = 1 AND bloqueado = 0` mediante `UsuarioRepository.getUsuarioActivo` (`lib/repositories/usuario_repository.dart:45-60`).
- **Sesión y logout:** `lib/controllers/auth_controller.dart` expone `haySesion` y en `logout()` limpia el usuario, revoca el acceso por huella y ejecuta `onLogout`; en `lib/main.dart:164` el callback está conectado a `posController.limpiarCarrito`.
- **Guarda de ruta:** `lib/app/auth_guard.dart:19` solo decide por sesión (`haySesion`), alcance aprobado en F9. La autorización administrativa se aplica después: menú del dashboard (`lib/screens/dashboard/dashboard_screen.dart:126-134`), pantalla de usuarios (`lib/screens/usuarios/usuarios_screen.dart:193-260`) y servicios (`lib/services/usuario_service.dart:32-110`).
- **Ciclo de vida y auditoría:** `UsuarioRepository.updateBloqueo/updateActivo` escriben el cambio y `AuditLogWriter.record` en la misma transacción (`lib/core/database/audit_log_writer.dart:7-19`); las acciones auditadas son `USUARIO_BLOQUEAR`, `USUARIO_DESBLOQUEAR`, `USUARIO_BAJA` y `USUARIO_REACTIVAR`.
- **Recuperación:** `lib/services/auth_service.dart:167-230` limita la recuperación a un admin activo, compara el código con `HashUtils.verifyRecoveryCode` y actualiza la contraseña con PBKDF2.
- **Rol propio en UI:** `lib/screens/usuarios/usuario_form_screen.dart:344-349` establece `canManageRole = isAdmin && (isCreating || usuarioId != currentUser.id)`, por lo que el formulario no ofrece cambiar el rol del propio usuario.

---

## 4. Actualización propuesta de la matriz

| Control(es) | Estado | Evidencia / pendiente |
|---|---|---|
| ISO 5.15 / 5.16 / 5.17 / 5.18 | Evidencia registrada (FS-6, 18/10/2026) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-001…010): login genérico, bloqueo 30 s, cierre de sesión, cuentas inactivas/bloqueadas, rol de empleado en UI y servicios, ciclo de vida auditado, última admin y recuperación. Pendiente: revisor humano; decisión del propietario sobre SEC-002 y SEC-007/008; ratificación en build release (`FS-7`) si se exige. |
| ISO 8.2 / 8.3 / 8.5 · MASVS-AUTH | Evidencia registrada (FS-6, 18/10/2026) | La autorización de operaciones administrativas se prueba en servicios y UI; los intentos de escalada por rol/ID se rechazan y no dejan cambios. Pendiente: revisor humano; aceptar el límite local-only (sin backend) y los residuales §5. |

---

## 5. Residuales y observaciones (no corregidos en FS-6)

> Ningún residual se marca como aceptado por el agente: la aceptación corresponde al propietario. **Resolución (FS-8, 18/10/2026):** el propietario aceptó §5.1–§5.5 como excepciones documentadas E-01…E-05, con dueño, compensación y caducidad (`docs/SECURITY_CLOSURE_REGISTER.md` §4); una corrección futura debe ejecutarse como fase nueva aprobada, con pruebas y gate propios.

### 5.1 SEC-002 — bloqueo solo en memoria

`AuthService` reinicia `failedAttempts` y `lockedUntil` al crear una instancia nueva (reinicio de la app). No hay evento de auditoría por intento fallido ni persistencia del bloqueo. Propuesta si el propietario lo aprueba: persistir el estado de bloqueo (por ejemplo, en SQLite/almacenamiento seguro con expiración) y registrar el evento sin datos sensibles; no se implementó.

### 5.2 SEC-005 — sesión ya abierta

La desactivación/bloqueo se revalida al iniciar sesión o con `loginRapido`, pero una sesión ya abierta no se revalida en cada operación. En este producto local-only de un solo dispositivo el cambio se aplica al siguiente acceso; si se exigiera revocación inmediata, haría falta una comprobación por operación o una autoridad remota. Pendiente de decisión.

### 5.3 SEC-006 — guarda de ruta solo de sesión

`AuthGuard` no comprueba rol; la denegación por rol está en el menú, en la pantalla (`Acceso Restringido`) y en los servicios. Es el alcance aprobado en F9 y no permite modificar datos administrativos, pero una navegación directa a una pantalla administrativa no se bloquea en el router. Pendiente de revisor/decisión si se quiere defensa en profundidad en el router.

### 5.4 SEC-007/008 — límite local-only

- `UsuarioService` confía en `currentUser.rol` para las operaciones de administración de usuarios; un APK modificado con control del proceso podría invocar el servicio con un usuario manipulado. `authorizeAdminOperation` (operaciones de caja) sí revalida contra la BD, y la UI no expone la edición de otro usuario a un empleado.
- Las lecturas `obtenerUsuario`/`obtenerUsuarios` no tienen autorización por objeto; la pantalla que las consume está restringida, pero el dueño del dispositivo/root puede leer la base SQLCipher si obtiene la clave. No hay backend que imponga autorización remota.
- No se corrigió: forma parte del límite declarado S2 y requiere decisión del propietario.

### 5.5 SEC-010 — autodemoción y auditoría de alta/edición

- `UsuarioService.guardarUsuario` no bloquea explícitamente que un admin se cambie el rol a sí mismo; el formulario sí oculta el selector de rol para el propio usuario (`canManageRole = false`). La auto-baja y el auto-bloqueo sí están bloqueados en el servicio. Recomendación (si se aprueba): añadir la guarda de autodemoción en el servicio como defensa en profundidad.
- Crear y editar usuarios no genera evento en `LogAuditoria`; solo los cambios de estado (`bloquear/desbloquear/baja/reactivar`) se auditan. No es un fallo de autorización, pero conviene decidir si el alta/edición debe quedar trazada.
- El rechazo de creación de un empleado devuelve el mensaje de permisos de edición por el orden de las comprobaciones; la operación se deniega antes de escribir. Observación de UX, sin impacto de seguridad.

---

## 6. Conclusión de la fase

Los 10 casos tienen prueba permanente y resultado registrado. No se modificó `lib/`; la fase no corrige los residuales anteriores. El gate de cierre queda verde con **139/139** y **0 issues**. La validación en dispositivo/release se ejecutó en `FS-7` (SEC-012/014/015/016/033/035/038) y la ratificación de los residuales quedó cerrada en `FS-8` como excepciones E-01…E-05 (`docs/SECURITY_CLOSURE_REGISTER.md` §4).
