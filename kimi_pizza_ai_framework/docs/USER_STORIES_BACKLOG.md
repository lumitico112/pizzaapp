# HISTORIAS DE USUARIO Y PRODUCT BACKLOG ÁGIL — KIMI PIZZA
**Documento:** BACKLOG-2026-V2.0  
**Metodología:** Scrum / Agile Framework con Criterios de Aceptación Gherkin  
**Proyecto:** KIMI PIZZA  
**Estado:** Product Backlog Aprobado (Day-0 Baseline)  

---

## 1. ÍNDICE DE ÉPICAS

| Código Épica | Nombre de la Épica | Story Points Totales | Prioridad Global |
|---|---|---|---|
| **EPIC-01** | Seguridad, Onboarding y Control de Acceso (RBAC) | 21 SP | Must Have |
| **EPIC-02** | Configuración de Negocio y Billetera Digital (QR) | 13 SP | Must Have |
| **EPIC-03** | Inventario de Insumos y Conversión de Unidades | 26 SP | Must Have |
| **EPIC-04** | Compras Unificadas, Proveedores y Cuentas por Pagar | 34 SP | Must Have |
| **EPIC-05** | Catálogo de Productos, Variantes y Recetas Escalares | 29 SP | Must Have |
| **EPIC-06** | Promociones y Combos con Restricción Horaria | 18 SP | Should Have |
| **EPIC-07** | Preparación Diaria (Mise en Place), Sobrantes y Transformaciones | 34 SP | Must Have |
| **EPIC-08** | Motor Heurístico de Sugerencias de Producción (IA) | 21 SP | Should Have |
| **EPIC-09** | Terminal de Punto de Venta (POS), Cortesías y Cobros | 42 SP | Must Have |
| **EPIC-10** | Emisión Persistente y Compartición de Boletas PDF | 21 SP | Must Have |
| **EPIC-11** | Control de Desperdicios y Mermas Operativas | 13 SP | Must Have |
| **EPIC-12** | Sesiones de Caja, Arqueo Ciego y Ciclo Nocturno | 34 SP | Must Have |
| **EPIC-13** | Dashboard Ejecutivo y Reportes Financieros P&L | 29 SP | Must Have |

---

## 2. DETALLE DE HISTORIAS DE USUARIO POR ÉPICA

### ÉPICA 01: Seguridad, Onboarding y Control de Acceso (RBAC)

#### US-01.1: Inicialización del Administrador Maestro (Day-0 Onboarding)
- **Como:** Dueño de la pizzería que instala la aplicación por primera vez.
- **Quiero:** Configurar mi cuenta de Administrador con usuario, contraseña fuerte, foto y obtener mi clave de rescate de emergencia.
- **Para:** Garantizar el control total del negocio y poder recuperar el acceso de forma autónoma si olvido mi clave.
- **Story Points:** 8 SP | **Prioridad:** Must Have | **Ref. SRS:** FR-001, FR-002, FR-003
- **Criterios de Aceptación (Gherkin):**
  ```gherkin
  Escenario: Primer arranque sin usuarios en la base de datos
    Dado que la aplicación se inicia por primera vez y la tabla "usuarios" está vacía
    Cuando se carga la aplicación
    Entonces se debe mostrar obligatoriamente la pantalla de "Onboarding Administrador"
    Y no se debe permitir la navegación a ninguna otra pantalla del sistema.

  Escenario: Generación exitosa de credenciales y Emergency Recovery Kit
    Dado que el usuario ingresa un nombre, un usuario "admin" y una contraseña de 8+ caracteres
    Cuando presiona el botón "Crear Administrador"
    Entonces el sistema debe derivar una sal criptográfica y almacenar el hash de la contraseña
    Y debe generar una clave de rescate alfanumérica de 24 caracteres en formato "XXXXXX-XXXXXX-XXXXXX-XXXXXX"
    Y debe presentar un diálogo modal de alta prioridad con la clave de rescate para su anotación obligatoria.
  ```

#### US-01.2: Restablecimiento de Contraseña mediante Recovery Kit
- **Como:** Administrador que olvidó su contraseña.
- **Quiero:** Ingresar mi nombre de usuario y mi clave de rescate de 24 caracteres.
- **Para:** Definir una nueva contraseña sin depender de conexión a internet ni correos externos.
- **Story Points:** 5 SP | **Prioridad:** Must Have | **Ref. SRS:** FR-004
- **Criterios de Aceptación (Gherkin):**
  ```gherkin
  Escenario: Restablecimiento exitoso con clave válida
    Dado que el administrador está en la pantalla de "Recuperar Acceso"
    Cuando ingresa su usuario "admin", su clave de rescate de 24 caracteres y su nueva contraseña
    Y la clave de rescate coincide con el hash almacenado en la base de datos
    Entonces el sistema actualiza la contraseña con un nuevo hash y sal
    Y muestra mensaje de confirmación y redirige a la pantalla de login.
  ```

---

### ÉPICA 02: Configuración de Negocio y Billetera Digital (QR)

#### US-02.1: Carga y Despliegue del Código QR de Cobro (Yape/Plin)
- **Como:** Administrador de la pizzería.
- **Quiero:** Configurar los datos del negocio y seleccionar desde la galería la imagen QR de cobro en una pantalla separada del perfil.
- **Para:** Que los cajeros puedan mostrar el QR al cliente directamente en el POS para cobrar rápidamente por transferencia.
- **Story Points:** 5 SP | **Prioridad:** Must Have | **Ref. SRS:** FR-008, FR-009
- **Criterios de Aceptación (Gherkin):**
  ```gherkin
  Escenario: Configuración del QR desde el menú lateral
    Dado que el Administrador abre "Configuración del negocio" desde el menú lateral
    Cuando selecciona una imagen de su código QR y presiona "Guardar"
    Entonces la imagen se copia al directorio persistente de la app y su ruta se guarda con la configuración global.

  Escenario: Despliegue interactivo en POS al pagar con Yape/Plin
    Dado que el cajero está cobrando una venta de S/ 45.00 y selecciona método "Yape/Plin"
    Cuando se abre el modal de cobro
    Entonces se visualiza la imagen del código QR configurado
    Y al tocar sobre la imagen, esta se abre en un visor ampliado.
  ```

---

### ÉPICA 03: Inventario de Insumos y Conversión de Unidades

#### US-03.1: Conversión Universal de Unidades de Materia Prima
- **Como:** Encargado de cocina y compras.
- **Quiero:** Comprar harina por sacos de 50 Kg y que las recetas descuenten en porciones de 250 g de manera exacta.
- **Para:** No tener descuadres en el inventario ni realizar conversiones manuales propensas a errores.
- **Story Points:** 8 SP | **Prioridad:** Must Have | **Ref. SRS:** FR-015, FR-016
- **Criterios de Aceptación (Gherkin):**
  ```gherkin
  Escenario: Descuento de stock en unidad fraccionaria
    Dado un insumo "Harina Especial" con unidad base "Kg" y stock actual de 10.0 Kg
    Cuando se prepara una receta que requiere 500 g de "Harina Especial"
    Entonces el servicio ConversionesHelper convierte 500 g a 0.5 Kg
    Y el nuevo stock del insumo en base de datos pasa a ser exactamente 9.5 Kg.
  ```

---

### ÉPICA 07: Preparación Diaria, Sobrantes y Transformaciones

#### US-07.1: Transformación de Pizzas Pre-Elaboradas en Vivo
- **Como:** Maestro pizzero durante el servicio de alta demanda.
- **Quiero:** Transformar una Pizza Americana pre-hecha en una Pizza Hawaiana agregando una porción de piña.
- **Para:** Atender el pedido del cliente de inmediato sin alterar el inventario físico real ni duplicar productos.
- **Story Points:** 8 SP | **Prioridad:** Must Have | **Ref. SRS:** FR-032
- **Criterios de Aceptación (Gherkin):**
  ```gherkin
  Escenario: Transformación de producto preparado con insumo adicional
    Dado que existen 3 unidades de "Pizza Americana Mediana" preparadas y 1.0 Kg de "Piña en Trozos"
    Cuando el pizzero registra una transformación a "Pizza Hawaiana Mediana" que consume 100 g de piña
    Entonces el stock de "Pizza Americana Mediana" disminuye a 2 unidades
    Y el stock de "Pizza Hawaiana Mediana" aumenta a 1 unidad
    Y el stock de "Piña en Trozos" se reduce de 1.0 Kg a 0.9 Kg de forma atómica.
  ```

---

### ÉPICA 09: Terminal de Punto de Venta (POS), Cortesías y Cobros

#### US-09.1: Cobro en Efectivo con Vuelto y Feedback Sensorial
- **Como:** Cajero de la pizzería.
- **Quiero:** Ingresar el monto recibido en efectivo, ver el vuelto calculado al instante, y que al confirmar suene un pitido de éxito y se muestre un check animado.
- **Para:** Cobrar rápido y con total certeza operativa en un ambiente concurrido.
- **Story Points:** 13 SP | **Prioridad:** Must Have | **Ref. SRS:** FR-038, FR-039
- **Criterios de Aceptación (Gherkin):**
  ```gherkin
  Escenario: Cálculo de vuelto correcto
    Dado un carrito con total a pagar de S/ 38.00
    Cuando el cajero selecciona "Efectivo" e ingresa "Se pagó con: S/ 50.00"
    Entonces el sistema muestra en pantalla un vuelto de "S/ 12.00" en color verde resaltado.

  Escenario: Confirmación sensorial de venta
    Dado que el cajero presiona el botón "Confirmar Venta"
    Cuando la transacción se asienta exitosamente en SQLite
    Entonces se reproduce el archivo de audio local de éxito "success.mp3"
    Y se despliega un diálogo con animación Lottie de verificación (Check)
    Y aparecen los botones "Ver Boleta" y "Descargar / Compartir".
  ```

---

### ÉPICA 12: Sesiones de Caja, Arqueo Ciego y Ciclo Nocturno

#### US-12.1: Arqueo Ciego y Semáforo de Balance en Cierre Nocturno
- **Como:** Administrador o Cajero que finaliza su turno a las 02:00 AM.
- **Quiero:** Contar el dinero en efectivo del cajón e ingresarlo sin ver cuánto dinero espera el sistema, conservando el ciclo operativo del día en que se abrió la caja.
- **Para:** Evitar fraudes o cuadres forzados y mantener la trazabilidad contable del día comercial.
- **Story Points:** 13 SP | **Prioridad:** Must Have | **Ref. SRS:** FR-044, FR-045, FR-046, FR-047
- **Criterios de Aceptación (Gherkin):**
  ```gherkin
  Escenario: Cierre de caja que cruza la medianoche
    Dado que la caja se abrió el día "2026-10-14 a las 18:00" con S/ 100.00 de fondo
    Cuando el cajero realiza el cierre el día "2026-10-15 a las 02:15"
    Entonces el ciclo_operativo asignado a la sesión y a los reportes sigue siendo "2026-10-14".

  Escenario: Arqueo ciego con diferencia exacta
    Dado que el sistema tiene ventas en efectivo por S/ 450.00 y gastos por S/ 50.00 (Teórico = S/ 500.00)
    Cuando el cajero cuenta y declara "Efectivo contado: S/ 500.00"
    Entonces la diferencia calculada es S/ 0.00
    Y la tarjeta de balance se pinta en VERDE con el rótulo "Caja Cuadrada".

  Escenario: Arqueo ciego con faltante de efectivo
    Dado el mismo teórico de S/ 500.00
    Cuando el cajero cuenta y declara "Efectivo contado: S/ 480.00"
    Entonces la diferencia calculada es S/ -20.00
    Y la tarjeta de balance se pinta en ROJO con el rótulo "Faltante de Caja: S/ -20.00".
  ```
