# ESPECIFICACIÓN DE REQUISITOS DE SOFTWARE (SRS) — KIMI PIZZA
**Documento:** SRS-2026-V2.0  
**Estándar:** IEEE Std 830-1998 / ISO/IEC/IEEE 29148  
**Proyecto:** KIMI PIZZA — Sistema de Punto de Venta (POS), Control de Producción y Gestión Financiera  
**Fecha:** Octubre 2026  
**Estado:** Aprobado para Construcción (Day-0 Baseline)  

---

## 1. INTRODUCCIÓN

### 1.1 Propósito del Documento
El presente documento tiene como objetivo especificar de manera formal, completa y verificable todos los requisitos funcionales, requisitos no funcionales, reglas de negocio y restricciones técnicas para la construcción desde cero del software **KIMI PIZZA**. Está dirigido al equipo de arquitectura de software, ingenieros de desarrollo Flutter, ingenieros de aseguramiento de calidad (QA) y a la dirección operativa del negocio.

### 1.2 Alcance del Sistema
KIMI PIZZA es una solución integral de software móvil/desktop concebida para operar en modo **Offline-First** (autónomo sin internet) en el sector gastronómico de pizzerías artesanales y comerciales. El sistema abarca:
- Gestión de seguridad y control de acceso por roles (RBAC) con recuperación autónoma criptográfica.
- Configuración de identidad de marca y billeteras digitales (códigos QR para pagos Yape/Plin).
- Control de inventario de materia prima con soporte de conversiones universales de unidades ($Kg \leftrightarrow g$, $L \leftrightarrow ml$, $Pqte \leftrightarrow Und$).
- Módulo unificado de compras a proveedores, control de comprobantes y gestión de cuentas por pagar (CxP).
- Catálogo de productos, variantes escalares y costeo automático de recetas (COGS).
- Gestión de combos, promociones y ofertas con vigencia horaria y por días de la semana.
- Planificación y registro de producción diaria (Mise en Place), transformaciones en vivo y faltantes.
- Motor de inteligencia operativa heurística para la sugerencia predictiva de producción.
- Terminal de Punto de Venta (POS) con soporte para cortesías, múltiples métodos de pago, cálculo de cambio y generación persistente de boletas de venta en PDF.
- Control de desperdicios y mermas operativas.
- Administración estricta de sesiones de caja, arqueo ciego, control de balance por semáforo y soporte para ciclos operativos que cruzan la medianoche.
- Generación de reportes analíticos con Estado de Resultados (P&L) y Dashboard ejecutivo en tiempo real.

### 1.3 Definiciones, Acrónimos y Abreviaturas
- **POS:** Point of Sale (Punto de Venta).
- **ERP:** Enterprise Resource Planning (Planificación de Recursos Empresariales).
- **COGS:** Cost of Goods Sold (Costo de Mercadería Vendida / Food Cost).
- **P&L:** Profit and Loss Statement (Estado de Ganancias y Pérdidas / Estado de Resultados).
- **Mise en Place:** Término culinario que designa la preparación previa de pizzas o bases antes de la apertura al público.
- **Transformación:** Conversión de una pizza pre-elaborada en otra variante mediante la adición de ingredientes sin duplicar la base física.
- **Ciclo Operativo:** Período continuo de trabajo comercial de la pizzería que puede abarcar dos días calendario (ej. 18:00 a 02:30).
- **Arqueo Ciego:** Proceso de cierre donde el operador cuenta y declara el dinero físico sin conocer previamente el monto teórico calculado por el sistema.
- **SQLCipher:** Extensión de SQLite que proporciona cifrado transparente de 256 bits AES para la base de datos local.
- **RBAC:** Role-Based Access Control (Control de Acceso Basado en Roles).

---

## 2. DESCRIPCIÓN GENERAL

### 2.1 Perspectiva del Producto
KIMI PIZZA es un sistema independiente y autónomo. No depende de microservicios externos o APIs en la nube para su operativa crítica diaria. Utiliza el hardware local del dispositivo (tablets Android, smartphones o PCs) para almacenar la base de datos cifrada y emitir comprobantes impresos o digitales.

### 2.2 Características de los Usuarios
| Perfil | Nivel Técnico | Responsabilidades Principales |
|---|---|---|
| **Administrador / Dueño** | Medio | Configuración de empresa, gestión de usuarios, definición de recetas, fijación de precios, supervisión de P&L, apertura/cierre de caja, auditoría de mermas y reaperturas excepcionales. |
| **Cajero / Mozo** | Básico | Apertura de turno, toma de pedidos en POS, cobros en efectivo/QR, emisión y compartición de boletas, registro de mermas y arqueo de caja al cierre. |
| **Pizzero / Cocinero** | Básico | Consulta de sugerencias de preparación, registro de pizzas elaboradas en el turno, solicitud de insumos y reporte de sobrantes/faltantes. |

### 2.3 Entorno Operativo
- **Plataformas:** Android (SDK 24+ / Android 7.0 a 15+), iOS (14+), Windows 10/11 (Desktop).
- **Base de Datos:** SQLite cifrado con SQLCipher (AES-256).
- **Rendimiento Requerido:** Arranque en menos de 2 segundos; respuesta táctil en POS inferior a 100 ms.

---

## 3. REQUISITOS FUNCIONALES (FR)

### Subsistema 1: Seguridad, Autenticación y Perfil
- **FR-001 (Onboarding Day-0):** Si no existe ningún usuario registrado, el sistema debe presentar obligatoriamente la pantalla de configuración del Administrador Maestro, impidiendo el uso de cualquier otro módulo.
- **FR-002 (Credenciales Seguras):** El sistema debe almacenar las contraseñas aplicando hashing criptográfico con sal aleatoria (Salt) única por usuario. No se admiten contraseñas menores a 8 caracteres.
- **FR-003 (Clave de Rescate Autónoma):** Durante el registro del Admin, el sistema debe generar una clave de 24 caracteres (`XXXXXX-XXXXXX-XXXXXX-XXXXXX`). El sistema almacenará solo el hash de esta clave.
- **FR-004 (Recuperación de Acceso):** El Administrador puede restablecer su contraseña ingresando su nombre de usuario y la clave de rescate correcta sin conexión a internet.
- **FR-005 (Control de Roles):** El sistema debe restringir las pantallas de Configuración, Recetas, Reportes Financieros y Reapertura de Caja únicamente a usuarios con rol `Admin`.
- **FR-006 (Persistencia de Sesión):** La sesión del usuario autenticado debe mantenerse activa entre aperturas de la app y solo destruirse mediante acción explícita de "Cerrar Sesión" o por el evento de fin de turno asociado al cierre de caja.

### Subsistema 2: Configuración del Negocio y Billetera Digital
- **FR-007 (Datos del negocio):** El nombre de la pizzería se captura durante el primer inicio. Solo el administrador puede consultar y editar nombre comercial/razón social, RUC o DNI, dirección, teléfono y mensaje al pie de la boleta desde una pantalla separada del perfil.
- **FR-008 (Imagen QR de Cobro):** Solo el administrador puede configurar, reemplazar o quitar desde Configuración del negocio la imagen QR seleccionada de la galería (Yape/Plin).
- **FR-009 (Despliegue del QR en POS):** En el momento del cobro mediante billetera digital, la pantalla debe mostrar el QR configurado y permitir ampliarlo. Si la imagen no está configurada o disponible, debe informar que el administrador la configure.

### Subsistema 3: Gestión de Activos Fijos
- **FR-010 (Registro de Activos):** El sistema debe permitir registrar activos con: Nombre, Categoría, Cantidad, Foto, Fecha de adquisición, Estado y Notas.
- **FR-011 (Modalidad Comprado):** Permite elegir `Contado` (genera salida de caja inmediata) o `Crédito` (permite adelanto y genera automáticamente una Cuenta por Pagar por el saldo).
- **FR-012 (Modalidad Alquilado):** Permite registrar el costo del canon y la periodicidad (`Diario`, `Semanal`, `Mensual`, `Anual`).
- **FR-013 (Modalidades Prestado y Regalado):** Permite registrar bienes sin generar egreso financiero de compra, manteniendo valoración de reposición.
- **FR-014 (Semáforo de Activos):** El listado debe identificar visualmente el estado: Verde (`En Uso` / `Bueno`), Amarillo (`En Reparación`), Rojo (`Fuera de Servicio` / `Baja`).

### Subsistema 4: Insumos y Conversión Universal de Unidades
- **FR-015 (Catálogo de Insumos):** Debe permitir registrar insumos con Nombre único, Categoría, Unidad base (`Kg`, `g`, `L`, `ml`, `Und`, `Pqte`), Contenido por paquete, Stock actual, Stock mínimo y Costo promedio ponderado.
- **FR-016 (Conversión Centralizada):** Todas las transformaciones de unidades deben ejecutarse mediante el servicio `ConversionesHelper`:
  - $1 \text{ Kg} \leftrightarrow 1000 \text{ g}$.
  - $1 \text{ L} \leftrightarrow 1000 \text{ ml}$.
  - $1 \text{ Pqte} \leftrightarrow n \text{ Unidades}$ (según factor configurado en el insumo).
- **FR-017 (Semáforo de Stock de Insumos):**
  - Verde: $\text{Stock} > 1.5 \times \text{Stock Mínimo}$.
  - Amarillo: $\text{Stock Mínimo} \le \text{Stock} \le 1.5 \times \text{Stock Mínimo}$.
  - Rojo: $\text{Stock} < \text{Stock Mínimo}$.

### Subsistema 5: Proveedores, Compras y Cuentas por Pagar (CxP)
- **FR-018 (Directorio de Proveedores):** CRUD completo de proveedores con validación de no duplicidad de RUC/DNI.
- **FR-019 (Flujo Unificado de Compras):** El registro de compras permite asociar múltiples insumos o activos, registrar el costo total y calcular el costo unitario derivado.
- **FR-020 (Captura de Facturas):** Permite adjuntar fotografía de la factura física para respaldo de auditoría.
- **FR-021 (Gestión de CxP):** Si la compra es a crédito, se genera una cuenta por pagar con saldo pendiente. El sistema permite amortizar cuotas sucesivas con su respectivo asiento de salida en la caja activa.

### Subsistema 6: Catálogo, Variantes y Costeo de Recetas
- **FR-022 (Productos y Variantes):** Un producto (ej. "Pizza Pepperoni") se compone de múltiples variantes comerciales (ej. "Personal 4 porc.", "Mediana 8 porc.", "Familiar 12 porc.").
- **FR-023 (Formulación de Recetas):** Cada variante tiene su receta compuesta por insumos y cantidades en unidades de cocina. Variantes independientes pueden compartir insumos, pero mantienen sus cantidades propias; una variante derivada hereda únicamente cuando existe una relación explícita con la variante base.
- **FR-024 (Regla Upsert en Receta):** Agregar un insumo que ya existe en la receta debe sumar o actualizar la cantidad sin crear una fila duplicada.
- **FR-025 (Costo de Alimento / COGS Automático):** El sistema debe computar en tiempo real el costo teórico de cada variante multiplicando los insumos de su receta por el costo unitario promedio ponderado.

### Subsistema 7: Promociones y Combos
- **FR-026 (Definición de Combos):** Registro de promociones con nombre, descripción, precio cerrado e imagen.
- **FR-027 (Restricciones de Activación):** Configuración de días de la semana y rango de horas en que la promoción es válida.
- **FR-028 (Composición de Variantes):** Desglose de qué variantes y en qué cantidad componen la promoción. Al venderse el combo en el POS, se descuenta el stock de cada variante componente.

### Subsistema 8: Preparación Diaria (Mise en Place) y Transformaciones
- **FR-029 (Registro de Preparación):** Pantalla para registrar las unidades de pizzas pre-elaboradas para el turno. Incrementa el stock de la variante y descuenta los insumos crudos según receta.
- **FR-030 (Cantidades Negativas / Faltantes):** Admite registrar cantidades menores a 0 para documentar pizzas demandadas pero no preparadas anticipadamente.
- **FR-031 (Sobrantes de Fin de Turno):** Permite clasificar las unidades sobrantes en "Llevar para mañana" (traslado de stock) o "Enviar a Merma" (descarte justificado). En preparación, las selecciones de sobrantes se mantienen en borrador y se aplican junto con el formulario al guardar.
- **FR-052 (Caja abierta para preparar):** La app exige una sesión de caja abierta antes de ingresar o guardar la preparación y antes de ejecutar movimientos de preparación que afectan inventario.
- **FR-032 (Motor de Transformaciones):** Permite convertir una pizza preparada en otra (ej. Americana a Hawaiana agregando piña) descontando la base física y el insumo adicional sin duplicar el producto físico.

### Subsistema 9: Motor Heurístico de Sugerencias de Producción
- **FR-033 (Algoritmo de Planificación):** Calcula la cantidad óptima a preparar según la fórmula:
  $$\text{Sugerencia} = \max\left(0, \text{Round}\left( (\bar{V}_{\text{mismo\_día}} \times F_{\text{estacionalidad}}) + Faltantes_{\text{último\_ciclo}} - Sobrantes_{\text{válidos}} \right)\right)$$
- **FR-034 (Aplicación con Un Toque):** Botón flotante para transferir automáticamente todas las sugerencias calculadas a la planilla de preparación del día.

### Subsistema 10: Punto de Venta (POS) y Facturación
- **FR-035 (Bloqueo por Caja Cerrada):** El POS no permite iniciar ventas si no existe una sesión de caja en estado `abierta`.
- **FR-036 (Carrito de Compras):** Permite agregar variantes y promociones, modificar cantidades, ingresar notas personalizadas por ítem y editar el precio de venta en caliente sin alterar el catálogo.
- **FR-037 (Cortesías):** Permite marcar ítems con precio S/ 0.00, descontando el recurso inventariable correspondiente.
- **FR-053 (Bebida servida por vaso):** Una variante de la categoría Bebidas con presentación “Vaso” debe consumir su receta por cada unidad vendida o entregada como cortesía. La receta incluye volumen en ml o litros y el insumo del vaso; el movimiento no debe equivaler a descontar una botella completa.
- **FR-038 (Cálculo de Vuelto):** Para cobros en efectivo con monto recibido, calcula el vuelto y valida que el dinero recibido sea suficiente.
- **FR-039 (Feedback Sensorial):** Tras confirmar el cobro, el sistema debe reproducir un sonido local de éxito (embebido en assets) y desplegar una animación de verificación (Check).

### Subsistema 11: Emisión Persistente de Boletas PDF
- **FR-040 (Generación Determinística de PDF):** Guarda cada ticket en `getApplicationDocumentsDirectory()/boletas/boleta_{id}.pdf`.
- **FR-054 (Detalle tributario y de efectivo en boleta):** La boleta muestra monto recibido y vuelto si se ingresó efectivo recibido. Desglosa base imponible e IGV incluido al 18 % a partir de un precio final que ya incluye IGV (`IGV = total × 18 / 118`).
- **FR-041 (Visor y Compartición):** El modal de éxito post-venta provee accesos directos a "Ver Boleta" (abre visor nativo) y "Compartir" (dispara Share Sheet nativo del dispositivo).
- **FR-042 (Recreación de Boletas):** El historial de ventas permite consultar y regenerar cualquier comprobante a partir de los registros de base de datos si el archivo local fuera eliminado.

### Subsistema 12: Control de Mermas
- **FR-043 (Registro de Desperdicios):** Permite asentar pérdidas de insumos crudos o pizzas preparadas con fecha, cantidad, motivo categorizado, responsable y costo económico derivado.

### Subsistema 13: Sesiones de Caja y Arqueo Ciego
- **FR-044 (Ciclo Operativo Nocturno):** La sesión conserva la fecha de apertura como identificador del ciclo comercial, aun cuando el cierre ocurra en horas de la madrugada del día siguiente.
- **FR-045 (Arqueo Ciego):** El cajero ingresa el dinero físico contado sin conocer el monto teórico esperado por el sistema.
- **FR-046 (Cálculo de Balance y Diferencia):**
  $$\text{Diferencia} = \text{Efectivo Contado} - (\text{Apertura} + \text{Ventas Efectivo} - \text{Salidas Efectivo})$$
- **FR-047 (Semáforo de Balance):** Verde ($\text{Diferencia} = 0$), Rojo ($\text{Diferencia} < 0$), Naranja ($\text{Diferencia} > 0$).
- **FR-048 (Reapertura Excepcional):** Una sesión cerrada solo puede ser reabierta por un usuario Administrador, quedando asentado el motivo y la auditoría.

### Subsistema 14: Reportes y Dashboard
- **FR-049 (Estado de Resultados P&L):** Cálculo de Ingresos, Costo de Mercadería (COGS), Gastos y Beneficio Neto por rangos de fecha flexibles.
- **FR-050 (Exportación PDF de Reportes):** Genera informe ejecutivo con resumen financiero y tabla de productos más vendidos.
- **FR-051 (Dashboard Ejecutivo):** Despliegue en tiempo real de métricas del día, alertas de stock mínimo y accesos directos operacionales con soporte Pull-to-Refresh.

### Subsistema 15: Gestión de Usuarios y Perfil
- **FR-055 (Administración de usuarios):** La administradora puede crear, editar, bloquear/desbloquear y dar de baja cuentas. La app persiste los roles disponibles (`admin` y `empleado`) y los datos de perfil admitidos.
- **FR-056 (Perfil y recuperación local):** El usuario puede editar su perfil y cerrar sesión. La administradora puede generar o renovar una clave de rescate que se muestra una sola vez; el restablecimiento del administrador usa esa clave sin depender de correo o internet.

### Subsistema 16: Copias de Seguridad
- **FR-057 (Copia portátil protegida):** La app permite exportar y restaurar una copia portátil cifrada, después de validar archivo, contraseña y confirmación del reemplazo de datos.
- **FR-058 (Copia local automática):** La app crea copias diarias cifradas en almacenamiento privado, conserva hasta siete y permite restaurar la más reciente en el mismo dispositivo.

### Requisitos transversales de inventario y usabilidad
- **FR-059 (Traslado idempotente de sobrantes):** Pasar un sobrante al formulario de hoy no suma stock preparado nuevamente ni vuelve a consumir su receta. El traslado, la merma seleccionada y la preparación nueva se guardan de forma atómica.
- **FR-060 (Conversión por paquete):** Al registrar un insumo en paquetes, el usuario indica cuántas unidades contiene cada paquete. La receta puede descontar unidades individuales y convertirlas a una fracción de paquete.
- **FR-061 (Navegación lateral y separación de ajustes):** El Dashboard proporciona un menú lateral compacto para Configuración del negocio y Gestión de usuarios (solo administrador) y Copias de seguridad. Los módulos operativos permanecen en el Dashboard y el perfil personal se abre desde su acceso propio, sin ajustes globales.

---

## 4. REQUISITOS NO FUNCIONALES (NFR)

### 4.1 Rendimiento y Eficiencia (NFR-001 a NFR-004)
- **NFR-001:** El tiempo de inicio de la aplicación (cold start) no debe exceder los 2.0 segundos en dispositivos de gama media (ej. 4GB RAM).
- **NFR-002:** El procesamiento del cobro de una venta y la generación del archivo PDF debe completarse en menos de 800 milisegundos.
- **NFR-003:** La interfaz de usuario debe mantener una tasa constante de 60 cuadros por segundo (FPS) sin bloqueos del hilo principal (UI thread).
- **NFR-004:** La base de datos SQLite debe utilizar índices sobre todas las columnas de búsqueda frecuente (`fecha`, `ciclo_operativo`, `sesion_caja_id`, `producto_id`, `variante_id`).

### 4.2 Seguridad y Protección de Datos (NFR-005 a NFR-008)
- **NFR-005:** Todos los datos persistidos en disco deben estar cifrados mediante SQLCipher con algoritmo AES-256 bits.
- **NFR-006:** Prohibido el almacenamiento de contraseñas o claves de rescate en texto plano. Se debe aplicar hash criptográfico con Sal (PBKDF2 / SHA-256).
- **NFR-007:** La exportación o compartición de boletas en PDF debe restringirse a los canales nativos del sistema operativo (`SharePlus`) sin enviar datos a servidores externos no autorizados.
- **NFR-008:** Control estricto de permisos en memoria durante el tiempo de ejecución (RBAC en memoria vinculado a la sesión de usuario).

### 4.3 Disponibilidad y Autonomía Offline (NFR-009 a NFR-011)
- **NFR-009:** El sistema debe operar con el 100% de sus funcionalidades sin necesidad de conexión a internet o redes locales.
- **NFR-010:** Los recursos multimedia críticos (sonidos de cobro, íconos de UI, animaciones Lottie) deben estar empaquetados dentro del binario de la aplicación (`assets/`), sin descargas en caliente por HTTP.
- **NFR-011:** Recuperación automática ante cierres abruptos: Todas las operaciones de escritura deben ser atómicas (`transactions`) para evitar la corrupción de la base de datos ante apagones o reinicios del dispositivo.

### 4.4 Usabilidad y Ergonomía en Cocina (NFR-012 a NFR-015)
- **NFR-012:** Las zonas de toque (touch targets) en pantallas operativas (POS y Preparación) deben tener un tamaño mínimo de 48x48 dp para facilitar la operación con manos enguantadas o húmedas.
- **NFR-013:** La interfaz debe presentar contrastes de color accesibles según directrices WCAG 2.1 AA.
- **NFR-014:** Confirmación de acciones destructivas (ej. eliminar insumo, anular venta, descartar preparación) mediante cuadros de diálogo de confirmación modal obligatorios.
- **NFR-015:** Retroalimentación háptica (vibración leve) y auditiva al confirmar operaciones exitosas en el Punto de Venta.
- **NFR-016:** El contenido y los accesos inferiores del Dashboard respetan el área de navegación del sistema en teléfonos, evitando que los controles táctiles del dispositivo cubran acciones de la app.

---

## 5. REGLAS DE NEGOCIO TRANSVERSALES (BR)

- **BR-001 (Independencia del Precio Base):** Modificar el precio de un producto en una venta particular jamás altera el precio catálogo configurado en el producto o variante.
- **BR-002 (Cortesías Contables):** Una cortesía no suma a los ingresos en efectivo ni banco, pero sí genera descuento físico de inventario y se registra contablemente como costo promocional.
- **BR-003 (Idempotencia de Categorías):** Las categorías del sistema son inmutables y no pueden duplicarse por variaciones de mayúsculas o espacios.
- **BR-004 (Unicidad en Recetas):** Un insumo solo puede existir una vez dentro de la receta de una variante.
- **BR-005 (Conservación de Ciclo Operativo):** Toda transacción ocurrida entre la apertura y el cierre de una caja pertenece a la fecha de apertura del ciclo, sin importar la fecha calendario del sistema operativo.
- **BR-006 (Integridad Referencial en Eliminación):** No se permite eliminar insumos o variantes que posean historial de ventas o movimientos de preparación; solo se permite marcarlos como `activo = 0`.
- **BR-007 (Atomicidad de Cobro):** Si la generación del PDF o la inserción del movimiento de caja falla, la venta completa se aborta y el stock permanece intacto.
