---
name: security-review
description: Directivas de seguridad criptográfica, almacenamiento de credenciales, derivación de claves, protección de base de datos SQLCipher y auditoría.
---

# Skill: Revisión de Seguridad y Criptografía

## 1. Directivas Inmutables de Seguridad
1. **Cero Texto Plano en Credenciales:**
   - Prohibido terminantemente almacenar contraseñas de usuarios en texto plano.
   - Utilizar `HashUtils.hashPassword` con sal criptográfica única por usuario.
2. **Generación Segura del Recovery Kit:**
   - Usar `Random.secure()` para generar el código de 24 caracteres alfanuméricos (`XXXXXX-XXXXXX-XXXXXX-XXXXXX`).
   - Solo el hash del token (`HashUtils.hashRecoveryCode`) se almacena en base de datos.
3. **Cifrado de Base de Datos Local:**
   - La base de datos SQLite debe abrirse utilizando `sqflite_sqlcipher` con cifrado AES-256 bits.
   - Las llaves deben derivarse de forma segura mediante PBKDF2.
4. **Control de Acceso Basado en Roles (RBAC):**
   - Verificar siempre que acciones privilegiadas (editar recetas, ver reportes analíticos, reabrir caja, administrar usuarios) requieran rol `admin`.
5. **Auditoría de Acciones Excepcionales:**
   - Las reaperturas de caja cerrada deben registrar id del administrador, timestamp y motivo obligatorio.
