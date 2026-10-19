# USERS_CONFIGURATION.md — KIMI PIZZA

## 1. Propósito

Este documento define las reglas de negocio, seguridad y comportamiento de los módulos **Usuarios** y **Configuración**. Debe considerarse fuente de verdad junto con `AGENTS.md`, `DATA_MODEL.md` y `BUSINESS_RULES.md`.

El objetivo es evitar que una futura modificación de código cambie accidentalmente los permisos, la sesión o la configuración global utilizada por otras funcionalidades.

> **Vigencia (18/10/2026):** reglas de diseño del módulo. Estado verificado actual: login exclusivo por `username` validando `activo = 1 AND bloqueado = 0` (RN-10); ciclo de bloqueo/desactivación auditado y sin auto-baja del propio administrador (RN-11); contraseñas con PBKDF2-HMAC-SHA256 (C-06); guardas de sesión en rutas protegidas (F9); limpieza de estado en logout/restore (C-18). Ante conflicto con el framework principal, prevalece el framework principal.

---

# 2. Principios generales

1. La autorización se basa en el rol/permisos reales del usuario, no en la visibilidad de botones.
2. La interfaz solo representa permisos; la lógica de aplicación y el backend deben hacer cumplir las restricciones.
3. El perfil del usuario autenticado y la administración de usuarios son responsabilidades relacionadas, pero no deben mezclarse en una única clase con múltiples responsabilidades.
4. La configuración global debe tener una fuente única de verdad.
5. Los valores de configuración reutilizados por distintos módulos no deben copiarse en cada pantalla.
6. Los datos sensibles nunca deben quedar expuestos en logs ni almacenarse de forma insegura.
7. Toda modificación administrativa debe ser validada y, cuando corresponda, registrada en auditoría.

---

# 3. Roles

Como mínimo, el sistema contempla:

- `ADMINISTRADOR`
- `EMPLEADO`

La lista real de roles debe provenir del backend/modelo de autorización del proyecto.

## 3.1 Administrador

Puede realizar operaciones administrativas autorizadas, entre ellas:

- administrar usuarios;
- modificar su propio perfil según las reglas del sistema;
- administrar la configuración global disponible;
- cargar o reemplazar el QR utilizado para cobros Yape/Plin;
- autorizar aperturas excepcionales de caja, según las reglas de Caja.

## 3.2 Empleado

Puede utilizar únicamente las funcionalidades que sus permisos permitan.

No debe poder realizar acciones reservadas al administrador simplemente manipulando la interfaz.

---

# 4. Módulo Usuarios

## 4.1 Objetivo

Permitir administrar las cuentas de acceso y permitir que el usuario autenticado gestione las partes de su perfil para las que tiene permiso.

## 4.2 Edición del propio perfil

El formulario de editar perfil debe contemplar una sección específica para el perfil del usuario autenticado.

La sección debe estar ubicada en la parte inferior del formulario, como extensión del formulario existente, sin crear un segundo formulario independiente si puede reutilizarse el mismo flujo.

### Regla

El usuario puede editar únicamente los campos que su rol y las reglas de seguridad permitan modificar.

### Administrador

El administrador debe disponer de la sección de edición de perfil solicitada.

La sección no debe otorgar por sí misma permisos para modificar otras cuentas.

---

# 5. Separación entre "mi perfil" y "administrar usuarios"

No confundir:

```text
Mi perfil
```

con:

```text
Administración de usuarios
```

Son casos de uso diferentes.

### Mi perfil

```text
Usuario autenticado
        ↓
Consultar perfil propio
        ↓
Editar campos permitidos
        ↓
Validar
        ↓
Guardar
        ↓
Actualizar sesión/perfil en memoria
```

### Administración de usuarios

```text
Administrador
        ↓
Lista de usuarios
        ↓
Crear / editar / activar / desactivar / eliminar según permisos
```

No duplicar modelos, validadores, servicios o formularios si una abstracción común puede resolver las dos necesidades sin mezclar responsabilidades.

---

# 6. Seguridad del cambio de perfil

Antes de guardar un cambio:

1. Verificar que el usuario tenga sesión válida.
2. Verificar que el recurso que intenta modificar le corresponda o que tenga permiso administrativo.
3. Validar los campos.
4. Enviar la operación mediante el caso de uso/repositorio correspondiente.
5. Actualizar el estado local únicamente después de una respuesta exitosa.
6. Mostrar un mensaje de éxito o error.

No asumir que un campo visible en Flutter es editable solo porque existe en el formulario.

---

# 7. Contraseñas y credenciales

La contraseña nunca debe:

- almacenarse en texto plano;
- aparecer en logs;
- aparecer en mensajes de depuración;
- almacenarse dentro de preferencias comunes sin protección;
- compararse localmente como mecanismo definitivo de autorización.

La autenticación y validación definitiva de credenciales debe delegarse al mecanismo seguro del backend/autenticador cuando exista.

---

# 8. Sesión de usuario

## 8.1 Regla principal

La aplicación debe permanecer autenticada y abierta mientras el usuario no cierre sesión explícitamente o mientras el flujo de negocio no determine que corresponde cerrar la sesión.

### No cerrar sesión por:

- navegar entre módulos;
- volver al dashboard;
- cerrar un modal;
- salir de un formulario;
- cambiar de pantalla;
- actualizar datos;
- volver a abrir un módulo.

## 8.2 Persistencia

La sesión debe restaurarse al abrir nuevamente la aplicación cuando el token/sesión siga siendo válido.

El mecanismo de persistencia debe ser seguro.

## 8.3 Expiración real

Si el backend informa que la sesión/token expiró o fue revocado, la aplicación debe invalidar la sesión de forma controlada y solicitar autenticación nuevamente.

No mantener una sesión aparentemente activa si ya no es válida.

---

# 9. Cierre de sesión y cierre de caja

El sistema distingue entre:

```text
Cerrar sesión
```

y:

```text
Cerrar caja
```

La regla de negocio establecida para KIMI PIZZA indica que la aplicación puede mantener la sesión durante la operación y que el cierre de caja puede formar parte del mecanismo que termina el ciclo operativo del usuario/sistema, según la implementación actual.

Cualquier automatismo de cierre debe respetar esta regla y no implementarse de forma arbitraria.

Cuando el cierre de caja deba terminar la sesión, debe existir un flujo explícito y consistente:

```text
Cerrar caja
   ↓
Guardar cierre
   ↓
Confirmar operación
   ↓
Cerrar ciclo operativo
   ↓
Cerrar sesión cuando corresponda
```

No cerrar la sesión antes de que el cierre haya sido persistido correctamente.

---

# 10. Módulo Configuración

La configuración debe contener únicamente opciones que afecten el comportamiento global de la aplicación y que tengan sentido como configuración central.

Cada configuración debe tener una única fuente de verdad.

Ejemplo actual prioritario:

```text
QR para ventas
```

---

# 11. QR para ventas

## 11.1 Propósito

El administrador debe poder cargar una imagen QR que será utilizada para los pagos mediante Yape/Plin dentro del módulo Ventas.

## 11.2 Permiso

Solo un usuario con permisos administrativos puede:

- cargar el QR;
- reemplazarlo;
- eliminarlo si esa operación está contemplada por la interfaz/backend.

Un empleado puede visualizarlo durante el cobro si su rol tiene permiso para registrar ventas, pero no modificarlo.

---

# 12. Flujo de configuración del QR

```text
Administrador
      ↓
Configuración
      ↓
QR para ventas
      ↓
Seleccionar imagen
      ↓
Cámara / Galería
      ↓
Previsualizar
      ↓
Confirmar
      ↓
Guardar configuración
```

Si la operación falla:

- no reemplazar el QR anterior;
- mostrar el error;
- permitir reintentar.

Si la operación tiene éxito:

- persistir la nueva referencia/imagen;
- actualizar el estado local;
- utilizar inmediatamente el nuevo QR en ventas posteriores.

---

# 13. Cámara y galería para QR

Debe reutilizarse la infraestructura de selección de imágenes existente.

No crear una implementación independiente únicamente para el QR si ya existe un servicio/componente común para:

- cámara;
- galería;
- permisos;
- compresión/redimensionado;
- previsualización;
- subida/almacenamiento.

El QR es otra utilización del componente de imágenes.

---

# 14. Validación del QR

Antes de guardar:

- comprobar que existe una imagen válida;
- comprobar que el proceso de selección/subida terminó correctamente;
- manejar cancelación del usuario;
- manejar errores de permisos;
- manejar errores de almacenamiento/subida.

No es obligatorio reconocer automáticamente el contenido del QR para guardar la imagen, salvo que esa funcionalidad forme parte explícita del proyecto.

La responsabilidad actual es almacenar y presentar la imagen QR correcta.

---

# 15. Persistencia del QR

El QR debe quedar asociado a una configuración global, no a una venta individual.

Conceptualmente:

```text
SystemConfiguration
    └── salesQrImage
```

Las ventas solo consumen la configuración actual.

No duplicar físicamente la misma configuración en cada pantalla.

Si una venta necesita conservar evidencia histórica del método de pago, debe guardar únicamente los datos propios de la venta; no crear una copia de configuración global sin necesidad.

---

# 16. Uso del QR en ventas

Flujo:

```text
Venta
  ↓
Cobrar
  ↓
Seleccionar Yape/Plin
  ↓
Consultar QR configurado
  ↓
Mostrar QR
  ↓
Presionar imagen
  ↓
Ampliar QR
```

Si no existe QR configurado:

- no mostrar una imagen falsa o placeholder como si fuera válida;
- informar claramente que el QR de ventas no está configurado;
- impedir o advertir según la política definida para registrar pagos Yape/Plin.

---

# 17. Visor de QR

El visor debe:

- mostrar la imagen correctamente;
- permitir ampliarla;
- permitir cerrarla;
- reutilizar el componente común de visualización de imágenes cuando exista.

No crear un visor exclusivo si ya existe uno reutilizable.

---

# 18. Consistencia del QR durante una venta

La imagen QR puede cambiar en Configuración mientras una venta ya está abierta.

La implementación debe evitar estados incoherentes.

Regla recomendada:

- al abrir el método Yape/Plin, obtener la configuración actual;
- mantenerla estable durante ese flujo de cobro;
- las nuevas ventas utilizarán la configuración actualizada.

No cambiar silenciosamente la imagen en mitad de una interacción sin actualizar el estado correspondiente.

---

# 19. Configuraciones futuras

La arquitectura de Configuración debe permitir agregar posteriormente opciones como:

- datos del negocio;
- logo;
- información para boletas;
- parámetros de stock;
- reglas de preparación;
- parámetros de cortesía;
- información para reportes;
- preferencias de impresión;
- otras configuraciones globales.

No crear una clase `Configuration` gigante que contenga lógica de negocio, UI y persistencia.

Separar configuración por responsabilidad cuando el crecimiento del módulo lo justifique.

---

# 20. Reutilización

Los siguientes componentes deben ser reutilizables entre Usuarios, Configuración y otros módulos:

```text
AppImagePicker
ImageSourceService
PermissionService
AppTextField
AppButton
AppDialog
AppConfirmationDialog
AppLoading
AppErrorState
AppDatePicker
AuthState
SessionManager
Role/Permission model
```

Los nombres anteriores son conceptuales: antes de crearlos, buscar equivalentes en el proyecto y reutilizar/refactorizar los existentes.

---

# 21. Auditoría

Las acciones administrativas sensibles deberían poder rastrearse, especialmente:

```text
Cambio de permisos/rol
Activar/desactivar usuario
Cambio de configuración global
Cambio de QR
Apertura excepcional de caja
```

Si el backend dispone de auditoría, esa fuente debe ser prioritaria.

---

# 22. Casos de error obligatorios

### Usuario sin sesión

No puede entrar a funcionalidades protegidas.

### Empleado intentando cambiar configuración administrativa

Debe rechazarse la operación aunque intente invocarla fuera de la UI normal.

### Administrador cancela selección de QR

No modificar el QR existente.

### Error al guardar QR

Conservar el QR anterior.

### No existe QR

Mostrar estado de configuración incompleta.

### Token expirado

Invalidar sesión y solicitar autenticación.

### Doble envío

No realizar dos operaciones administrativas por doble toque.

---

# 23. Criterios de aceptación — Usuarios

```text
[ ] El perfil propio utiliza el formulario existente cuando sea posible.
[ ] El administrador tiene su sección de edición de perfil.
[ ] Solo se pueden modificar campos autorizados.
[ ] No se duplican formularios ni lógica innecesariamente.
[ ] Los permisos se validan fuera de la UI.
[ ] Las contraseñas nunca se almacenan en texto plano.
[ ] La sesión permanece activa durante la operación normal.
[ ] La sesión solo termina por logout o regla de negocio/expiración válida.
[ ] La sesión puede restaurarse de forma segura cuando corresponda.
```

# 24. Criterios de aceptación — Configuración QR

```text
[ ] Solo el administrador autorizado puede cambiar el QR.
[ ] Se puede seleccionar QR desde cámara cuando corresponda.
[ ] Se puede seleccionar QR desde galería.
[ ] Se puede previsualizar.
[ ] Se puede reemplazar el QR anterior.
[ ] Si falla el guardado, el QR anterior se conserva.
[ ] El QR queda persistido.
[ ] Ventas utiliza automáticamente el QR configurado.
[ ] El empleado puede visualizarlo al cobrar si tiene permiso.
[ ] El QR puede ampliarse.
[ ] No existe implementación duplicada de cámara/galería/visor.
[ ] El sistema informa claramente cuando no hay QR configurado.
```

# 25. Pruebas mínimas

## Usuarios

- login correcto;
- restauración de sesión;
- logout;
- token expirado;
- administrador editando perfil;
- empleado intentando acceder a función administrativa;
- doble envío del formulario;
- error de API al guardar perfil.

## Configuración

- guardar primer QR;
- reemplazar QR;
- cancelar selección;
- cámara sin permiso;
- galería cancelada;
- error de almacenamiento;
- QR inexistente;
- visualizar QR en venta;
- ampliar/cerrar QR;
- cambiar QR y comprobar que nuevas ventas utilicen el nuevo;
- asegurar que un empleado no pueda modificarlo.

---

# 26. Regla final

No implementar Usuarios ni Configuración como pantallas aisladas.

Ambos módulos participan en reglas transversales del sistema:

```text
Usuarios
   ↓
Autenticación
   ↓
Autorización
   ↓
Sesión
   ↓
Operaciones permitidas

Configuración
   ↓
Valores globales
   ↓
Ventas / Boletas / UI / reglas configurables
```

Cualquier cambio debe analizar su impacto en los módulos que consumen estos datos.
