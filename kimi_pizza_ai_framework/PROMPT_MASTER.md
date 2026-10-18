# PROMPT MAESTRO DE INGENIERÍA DE SOFTWARE — KIMI PIZZA
**Versión:** 3.0.0 (Consolidated Audit & Approved Business Rules Edition)  
**Estado:** Especificación Canónica para Evolución de KIMI PIZZA POS (`com.kimipizza.pos`)  
**Plataforma Objetivo:** Flutter (Android) — Offline-First, Cifrado Local SQLCipher, POS & ERP Integral para Pizzerías  
**Documentos Rectores Vinculados:** [`AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/AGENTS.md) y [`docs/AUDIT_CONSOLIDATED.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md)  

---

## 1. Directiva Principal de Identidad y Rol

Actúa como **Chief Software Architect**, **Lead Flutter Engineer** y **Principal Financial Systems Designer** especializado en sistemas de Punto de Venta (POS) y Planificación de Recursos Empresariales (ERP) para el sector gastronómico de alta rotación (Pizzerías).

Tu misión es evolucionar la solución integral **KIMI PIZZA** sobre la aplicación y los datos existentes. Antes de proponer o implementar cambios, inspecciona el código y las migraciones actuales; conserva compatibilidad y asegura que cada componente, módulo, modelo de datos y línea de código responda a altos estándares de ingeniería de software:
- **Clean Architecture & Feature-First**: Desacoplamiento estricto entre UI, Dominio y Persistencia.
- **Offline-First & Cifrado Robusto**: Autonomía total sin conexión mediante SQLite cifrado a nivel de hardware (SQLCipher con clave aleatoria de 256 bits en `FlutterSecureStorage` y respaldos `.kpzbackup` con PBKDF2-HMAC-SHA256 310k + AES-256-GCM).
- **Consistencia Matemática Transversal**: Cero discrepancias entre recetas, stock de insumos, stock de variantes pre-hechas, arqueo de caja y estados financieros P&L.
- **Principios SOLID, DRY y KISS**: Responsabilidad única, inversión de dependencias y erradicación total de código o lógica duplicada.
- **UI/UX Operativa de Alto Rendimiento**: Diseñada para entornos ruidosos y de ritmo acelerado en cocina y mostrador (retroalimentación háptica, animaciones de confirmación, síntesis visual en semáforos, soporte para pantallas táctiles).

---

## 2. Visión del Producto y Problema de Negocio

### 2.1 Contexto Operativo
Una pizzería artesanal/comercial opera bajo una dinámica mixta crítica:
1. **Materia Prima heterogénea:** Insumos que se compran en unidades macro (sacos de 50 kg de harina, bidones de aceite, barras de queso de 3 kg, cajas de embutidos) y se consumen en recetas con unidades fraccionarias mínimas (gramos, mililitros, unidades).
2. **Producción Anticipada (Mise en Place):** Antes del servicio se elaboran bases precocidas o pizzas pre-armadas listas para hornear. Esto requiere un doble inventario: insumos crudos y productos preparados disponibles.
3. **Transformaciones en Vivo:** Durante el despacho, un cliente solicita una pizza "Hawaiana", pero en inventario preparado solo quedan "Pizzas Americanas". El pizzero agrega piña sobre la americana pre-hecha. El sistema debe consumir la pizza americana base y la porción de piña adicional sin duplicar el producto físico ni desfasar el stock.
4. **Ciclo Operativo Nocturno (`RN-06`):** El turno comienza a las 18:00 y finaliza a las 02:00 del día calendario siguiente. El cierre de caja y los reportes financieros se consolidan bajo la **sesión de caja activa (`sesion_caja_id`)**, no según el cambio de fecha calendario a las 00:00.
5. **Múltiples Canales de Cobro sin Conexión (`RN-04`):** Cobro en **Efectivo** (con cálculo exacto de vuelto) y **Digital/Bancario** (`Yape/Plin`, `Transferencia`, `Tarjeta`) mediante código QR administrable, con validación de arqueo ciego centralizada en `CashCloseSummary`.

---

## 3. Principios de Arquitectura e Invariantes No Negociables

### 3.1 Separación Estricta de Capas (Clean Architecture)
```
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   Screens, Widgets atómicos, Dialogs, State Providers  │
└───────────────────────────▲────────────────────────────┘
                            │ (Inversión de dependencias)
┌───────────────────────────┴────────────────────────────┐
│                      DOMAIN LAYER                      │
│     Entities, Value Objects, Use Cases, Core Rules,    │
│            Calculators & Unit Conversion Logic         │
└───────────────────────────▲────────────────────────────┘
                            │ (Implementación de interfaces)
┌───────────────────────────┴────────────────────────────┐
│                       DATA LAYER                       │
│    Repositories, SQLite DAOs, SQLCipher Encryption,    │
│         Local File System (PDFs, Images, Receipts)     │
└────────────────────────────────────────────────────────┘
```

1. **La UI jamás ejecuta lógica de negocio ni cálculos matemáticos:** Ningún widget o método `build()` puede calcular stock, conversiones de gramos a kilogramos, balance de caja o totales de venta. Toda lógica reside en servicios y casos de uso del dominio.
2. **La UI jamás accede directamente a la base de datos:** La capa de presentación se comunica exclusivamente a través de Controladores / Notifiers (State Management con `ChangeNotifier` / `Provider`), los cuales orquestan Servicios de Dominio y Repositorios.
3. **Transaccionalidad Atómica (ACID):** Toda operación que afecte más de una tabla (por ejemplo: Venta -> DetalleVenta -> Descuento Stock -> Movimiento Caja -> Generación de Boleta) DEBE ejecutarse dentro de un bloque `db.transaction((txn) async { ... })`. Si un paso falla, el sistema realiza rollback completo.
4. **Fuente Única de Verdad (SSOT) e Higiene de Sesión (`C-18`):** No existen variables paralelas en memoria que almacenen el mismo dato con riesgo de desincronización. Al cerrar sesión (`logout()`) o restaurar un respaldo, todos los controladores en memoria (como el carrito de `PosController`) deben limpiarse.
5. **Cero Dependencias de Red Obligatorias (`C-21`):** La aplicación funciona al 100% de manera offline. Las fuentes tipográficas (`Poppins`) y sonidos deben estar empaquetados localmente en `assets/` (`GoogleFonts.config.allowRuntimeFetching = false`).

---

## 4. Especificación Detallada de los Módulos del Sistema

### MÓDULO 01: Autenticación, Onboarding y Recuperación Criptográfica
- **Primer Arranque Atómico (`C-30`):**
  - Si la base de datos no contiene usuarios, la aplicación bloquea el acceso y presenta la pantalla de Inicialización del Administrador Maestro.
  - Solicita: Nombre completo, Usuario/Alias (`username`), Contraseña (mínimo 8 caracteres), Correo de contacto y Foto de perfil.
  - El guardado de la configuración inicial del negocio y la creación del administrador deben ejecutarse en una **única transacción atómica**.
  - **Generación de Clave de Rescate (Emergency Recovery Kit):** El sistema genera automáticamente una clave alfanumérica criptográfica de 24 caracteres agrupada en 4 bloques (`XXXXXX-XXXXXX-XXXXXX-XXXXXX`) calculada mediante `Random.secure()`.
  - La clave de rescate se almacena en base de datos únicamente en formato hash (`HashUtils.hashRecoveryCode`).
- **Credencial de Acceso y Bloqueo Efectivo (`RN-10` / `C-05` / `C-27`):**
  - El login autentica exclusivamente por `username` y exige obligatoriamente `activo = 1 AND bloqueado = 0` tanto en inicio de sesión como en reautenticaciones administrativas. La etiqueta visual del campo debe decir únicamente **`Usuario`**.
- **Roles y Permisos (RBAC):**
  - `Admin`: Acceso irrestricto a Dashboard, Reportes Financieros, Modificación de Recetas, Costos, Activos, Apertura/Cierre de Caja y Gestión de Usuarios.
  - `Empleado`: Cajero/Preparador. Los permisos efectivos se validan en la capa de servicio/repositorio.
- **Seguridad y Cifrado (`C-06`):**
  - Contraseñas almacenadas mediante `PBKDF2-HMAC-SHA256` con sal aleatoria por usuario (`HashUtils.hashPassword`), con migración transparente al iniciar sesión para hashes legacy SHA-256 de 64 caracteres hex.
  - Recuperación de cuenta mediante la Clave de Rescate con límite de intentos y vigencia.

### MÓDULO 02: Configuración del Negocio y Billeteras Digitales (Yape/Plin QR)
- **Perfil de la Empresa:** Razón Social / Nombre Comercial, RUC / Identificador Tributario, Dirección física, Teléfono y Mensaje de pie de ticket de venta.
- **Autorización y navegación:** El nombre de la pizzería se ingresa durante el primer inicio y luego se edita en Configuración del negocio. Solo `admin` puede abrir o modificar esa pantalla y el QR. Perfil personal y gestión de usuarios se mantienen separados. El menú lateral compacto agrupa los accesos administrativos y copias de seguridad; los módulos operativos siguen en el Dashboard.
- **Gestión del Código QR de Cobro:**
  - Solo el administrador puede seleccionar desde la galería la imagen del código QR oficial de la pizzería (Yape, Plin o cuenta bancaria), desde **Configuración del negocio** en el menú lateral.
  - La ruta de la imagen se conserva en la configuración local del negocio; la imagen seleccionada se copia al directorio persistente de documentos de la app.
  - **Comportamiento en POS:** Al seleccionar el método de pago `Yape/Plin`, el POS muestra la imagen del QR configurado; al tocar la imagen se abre un visor ampliado. Si no hay QR válido, la app informa que el administrador debe configurarlo.

### MÓDULO 03: Activos Fijos y Control Operativo de Equipamiento
- **Registro Exhaustivo de Activos:** Horno pizzero, amasadora, refrigerador industrial, mesas de acero, palas pizzeros, cortadoras, etc.
- **Campos del Activo:** Nombre, Categoría, Cantidad física, Fotografía obligatoria/opcional, Fecha de adquisición (editable con DatePicker), Estado físico y Notas.
- **Modalidades de Adquisición:**
  1. `Comprado`: Costo total, Costo unitario derivado, Forma de pago (`Contado` o `Crédito`).
     - Si es `Contado`: Genera egreso automático en Gastos y salida de Caja si hay sesión abierta.
     - Si es `Crédito` (`C-09`): Registra `Adelanto` inicial (egreso en caja si > 0), número de `Cuotas` acordadas, y crea automáticamente una **Cuenta por Pagar** vinculada con `insumo_id = NULL` y `activo_fijo_id` apuntando al activo (prohibido usar el valor centinela `insumo_id = 0`).
  2. `Alquilado`: Costo del canon y Periodicidad (`Diario`, `Semanal`, `Mensual`, `Anual`).
  3. `Prestado`: Registro con valor estimado de reposición sin generar egreso de compra.
  4. `Regalado / Donado`: Valoración simbólica para inventario físico sin egreso de capital.
- **Semáforo de Estado Operativo:**
  - `En Uso` / `Bueno`: Verde.
  - `En Reparación`: Amarillo ámbar.
  - `Fuera de Servicio` / `Baja`: Rojo carmesí.
- **Categorías disponibles:** Maquinaria, Muebles, Tecnología, Vehículos, Electrodomésticos y Otros. La inicialización debe crear únicamente las categorías que falten, sin duplicar las existentes.

### MÓDULO 04: Insumos, Unidades de Medida y Conversiones Universales
- **Categorización Idempotente:** Harinas y Masas, Quesos y Lácteos, Carnes y Embutidos, Verduras y Frutas, Salsas y Condimentos, Empaques y Descartables, Bebidas.
- **Sistema Universal de Unidades de Medida:**
  - Masa: Kilogramos (`Kg`), Gramos (`g` / `gr`). Relación: $1 \text{ Kg} = 1000 \text{ g}$.
  - Volumen: Litros (`L` / `Lt`), Mililitros (`ml`). Relación: $1 \text{ L} = 1000 \text{ ml}$.
  - Conteo: Unidades (`Und`), Paquetes (`Pqte`). Un paquete almacena su equivalencia interna obligatoria en unidades (`unidadesPorPaquete`).
- **Compras en la unidad de stock:** La cantidad de una compra se registra usando la unidad configurada para el insumo. Si los vasos se controlan por paquetes, el stock se expresa en paquetes y la receta puede consumir unidades individuales mediante `contenido_paquete`.
- **Conversor Centralizado de Dominio (`UnitConverter` / `ConversionesHelper`):**
  - Todas las conversiones entre unidades de compra (ej. saco de harina en Kg) y formulación de recetas (ej. 250 g de masa) se resuelven exclusivamente mediante este helper. Prohibida la multiplicación/división dispersa en la UI.
- **Semáforo de Stock Dinámico:**
  - `Verde`: Stock actual $> 1.5 \times \text{Stock Mínimo}$.
  - `Amarillo`: $\text{Stock Mínimo} \le \text{Stock actual} \le 1.5 \times \text{Stock Mínimo}$.
  - `Rojo`: Stock actual $< \text{Stock Mínimo}$ (Alerta de reabastecimiento urgente).

### MÓDULO 05: Proveedores, Compras Unificadas y Cuentas por Pagar (CxP)
- **Directorio de Proveedores:** RUC/DNI, Razón Social, Teléfono, Correo, Dirección y Catálogo de insumos suministrados.
- **Flujo Unificado de Compras:**
  - Toda adquisición de materia prima o activos fijos pasa por el módulo unificado de compras.
  - Selección de insumo existente o creación rápida mediante botón `+` sin salir del formulario y sin duplicar registros.
  - Ingreso de Cantidad, Costo Total y cálculo automático del Costo Unitario en tiempo real.
  - Adjunto fotográfico de la factura/ticket físico.
- **Financiamiento, Corrección de Compras y Cuentas por Pagar (`RN-01`, `RN-02` / `C-01`, `C-02`):**
  - Compra al Contado: Salida directa de efectivo de la sesión de caja actual.
  - Compra al Crédito: Registro de Adelanto inicial (si aplica) y generación de una fila consolidada en `CuentasPorPagar` con el saldo adeudado ($Costo Total - Adelanto$).
  - Gestión de Pagos de CxP: Amortización progresiva de cuotas en `PagosCuentaPorPagar` con actualización de saldo pendiente y asiento de gasto/egreso en caja vinculados por ID explícito.
  - **Edición de Compra a Crédito con Abonos (`RN-01`):** Al corregir una compra a crédito, se recalcula `monto_pagado = adelanto_actualizado + SUM(PagosCuentaPorPagar)`. Si el nuevo total es menor a `monto_pagado`, se rechaza la edición. El ajuste del adelanto inicial no duplica registros en `Gastos` ni `MovimientosCaja`.
  - **Bloqueo de Eliminación Directa de Gastos Vinculados (`RN-02`):** Los gastos originados por compras o abonos de `CuentasPorPagar` no pueden eliminarse desde la lista genérica de Gastos; la anulación de un abono se realiza exclusivamente desde Cuentas por Pagar revirtiendo deuda, gasto y movimiento de caja por ID exacto.

### MÓDULO 06: Catálogo de Productos, Variantes y Recetas Escalares
- **Estructura Jerárquica del Catálogo:**
  ```
  Producto (ej. "Pizza Margherita")
    ├── Imagen representativa
    ├── Categoría ("Pizzas Tradicionales", "Pizzas Especiales", "Bebidas", "Postres")
    └── Variantes de Venta:
          ├── Variante Personal (ej. "4 Porciones" - Precio S/ 18.00) -> Receta propia
          ├── Variante Mediana (ej. "8 Porciones" - Precio S/ 32.00)  -> Receta propia
          └── Variante Familiar (ej. "12 Porciones" - Precio S/ 48.00) -> Receta propia
  ```
- **Motor de Recetas y Costeo Automático (Food Cost / COGS):**
  - Cada variante posee su receta compuesta por una lista de insumos con cantidad y unidad de formulación.
  - Regla de Upsert en recetas: Agregar un insumo ya existente a una receta actualiza la cantidad en lugar de duplicar la fila.
  - El costo de producción teórico (COGS) de cada variante se calcula automáticamente sumando el costo unitario prorrateado de sus insumos:
    $$\text{Costo Receta} = \sum_{i=1}^{n} (\text{Cantidad Insumo}_i \times \text{Costo Unitario Insumo}_i)$$
- **Independencia por variante:** Cada receta se identifica por `variante_id`; variantes independientes pueden utilizar los mismos insumos con cantidades distintas. Una variante derivada puede heredar la receta base y añadir componentes propios solo cuando esa relación esté configurada explícitamente.
- **Bebidas servidas por vaso:** Para una variante cuyo nombre contenga “Vaso” y pertenezca a la categoría Bebidas, la receta debe incluir el volumen de bebida en ml o litros y al menos un insumo cuyo nombre identifique el vaso. El volumen y el vaso se registran por cada unidad vendida.

### MÓDULO 07: Promociones, Combos y Descuentos Temporales
- **Definición de Combos y Promociones:**
  - Título, Descripción, Imagen de banner y Precio Promocional cerrado.
  - Reglas de Activación Temporal: Días de la semana permitidos (Checkboxes L-M-M-J-V-S-D), Hora de Inicio y Hora de Fin (TimePicker).
  - Composición de Productos: Selección de múltiples variantes con cantidades específicas (ej. "1 Pizza Familiar + 1 Gaseosa 1.5L + 1 Porción de Pan al Ajo").
  - Al vender una promoción, el sistema descuenta automáticamente el stock de cada variante individual involucrada.

### MÓDULO 08: Preparación Diaria (Mise en Place), Faltantes y Transformaciones
- **Control de Producción Diaria:**
  - Pantalla especializada con controles incrementales de alta velocidad (`-`, `Cantidad directa`, `+`) para el pizzero.
  - Visualización del stock disponible en tiempo real por cada variante.
  - **Soporte de Cantidades Negativas (Faltantes):** Si la demanda superó a la preparación previa, el sistema permite registrar cantidades negativas que representan "Pizzas preparadas bajo demanda urgente / faltantes", alimentando el algoritmo de sugerencias.
- **Gestión de Sobrantes de Fin de Turno e Invariante Física (`RN-03` / `C-03`, `C-04`, `C-10`):**
  - Al culminar el turno, las unidades preparadas que no se vendieron se clasifican como:
    a) `Llevar para mañana` (`llevado_manana`): Traslada de forma idempotente (`UPSERT` verificando `1` fila afectada en el origen) el stock de producto preparado al ciclo del día siguiente.
    b) `Enviar a Merma` (`enviado_merma`): Descarta el producto registrando la pérdida justificada.
  - **Invariante obligatoria:** Se valida estrictamente que `enviado_merma + llevado_manana <= cantidad_preparada` y que la cantidad a descontar nunca supere el `stock_actual` preparado de la variante (prohibido registrar merma mayor a lo descontado).
  - **Actualización de `sobrante`:** Al cerrar sobrantes, `ItemsPreparacion.sobrante` se actualiza con `enviado_merma + llevado_manana` para alimentar el algoritmo de sugerencias.
- **Control de caja y borrador de sobrantes:** La preparación requiere una sesión de caja abierta. Al entrar, si existen sobrantes pendientes de días anteriores, la app muestra la lista para decidir cuánto añadir a la preparación de hoy y cuánto registrar como merma. Las selecciones quedan en el formulario; se persisten en una única operación al pulsar Guardar. Trasladar unidades ya preparadas no vuelve a crear stock ni a descontar su receta.
- **Motor de Transformaciones de Productos:**
  - Permite convertir una variante pre-hecha en otra sin duplicar la base física.
  - Regla: Variante Origen + Insumo Adicional = Variante Destino.
  - Ejemplo: `1 Pizza Americana Pre-armada` + `100 g de Piña en conserva` $\rightarrow$ `1 Pizza Hawaiana`.
  - El sistema descuenta 1 unidad de la Americana pre-hecha, 100 g de piña del inventario de insumos, e incrementa 1 unidad en la Hawaiana disponible para venta.

### MÓDULO 09: Motor Heurístico de Sugerencias Inteligentes de Producción
- **Algoritmo de Planificación de Cocina (`RN-03` / `C-10`):**
  - Calcula la recomendación de cuántas unidades de cada pizza preparar antes de abrir el local.
  - Fórmula Matemática Canónica:
    $$\text{Sugerencia} = \max\left(0, \text{Round}\left( (\bar{V}_{\text{mismo\_día}} \times F_{\text{estacionalidad}}) + Faltantes_{\text{último\_ciclo}} - Sobrantes_{\text{válidos}} \right)\right)$$
    Donde:
    - $\bar{V}_{\text{mismo\_día}}$: Promedio histórico de ventas de los últimos 4 turnos correspondientes al mismo día de la semana (ej. promedio de los últimos 4 viernes).
    - $Faltantes_{\text{último\_ciclo}}$: Cantidades preparadas en negativo o demandas insatisfechas del último turno.
    - $Sobrantes_{\text{válidos}}$: Columna `ItemsPreparacion.sobrante` (`enviado_merma + llevado_manana`) del turno anterior.
- **Visualización Desglosada:** Cada tarjeta en la pantalla muestra la fórmula transparente ("Promedio: 20 | Faltantes: +4 | Sobrantes: -2 $\rightarrow$ Sugerencia: 22") con botón de un solo toque: *"Aplicar Sugerencias a Preparación de Hoy"*.

### MÓDULO 10: Punto de Venta (POS), Carrito, Cortesías y Modos de Cobro
- **Catálogo Interactivo con Filtrado Rápido:** Categorías con scroll horizontal, barra de búsqueda en tiempo real, visualización de stock actual en cada card.
- **Bloqueo Estricto de Productos al Momento (`RN-07`):** Un producto de preparación `'momento'` o `'ambos'` no puede venderse si no tiene receta activa configurada o si alguno de sus insumos no tiene stock suficiente, mostrando un mensaje claro al cajero.
- **Gestión del Carrito de Ventas:**
  - Incremento, decremento, notas especiales por ítem (ej. "sin orégano", "bien dorada").
  - Modificación de precio en caliente para la venta en curso (sin alterar el precio base del catálogo).
- **Venta de bebidas por vaso:** En la categoría Bebidas, una variante llamada “Vaso” se muestra como una unidad servida (por ejemplo, “1 vaso de Gaseosa”). Cada venta o cortesía consume la receta completa de esa variante: mililitros/litros servidos y el vaso. El POS no exige stock de producto preparado para esta modalidad; la receta debe contener ambos recursos y la operación se bloquea si falta uno.
- **Gestión de Cortesías de Bebidas y Productos:**
  - El personal puede marcar un ítem como "Cortesía".
  - Regla de inventario: el precio cobrado pasa a S/ 0.00 y se consume el recurso correspondiente según el modelo del producto. Una cortesía no debe omitir el movimiento de inventario.
- **Pasarela de Cobro y Validación Financiera (`RN-04` / `C-11`):**
  - Modal de cobro con rubros oficiales: **Efectivo** (`efectivo`) y **Digital/Bancario** (`yape/plin`, `transferencia`, `tarjeta`). La opción `mixto` permanece deshabilitada hasta contar con estructura de desglose de montos.
  - En Efectivo: Campo "Se pagó con" opcional; cálculo instantáneo del vuelto/cambio. Validación que el monto recibido sea $\ge$ total a pagar.
  - En Yape/Plin: Despliegue del QR del negocio; confirmación tras verificación visual de la captura.
  - **Experiencia de Usuario de Cierre de Venta:** Al confirmar, se reproduce retroalimentación auditiva local y se despliega confirmación visual con dos acciones directas:
    1. *"Ver Boleta"* (Abre el visor PDF).
    2. *"Descargar / Compartir"* (Invoca `SharePlus` nativo).

### MÓDULO 11: Emisión Persistente de Boletas de Venta en Formato PDF
- **Almacenamiento Persistente Obligatorio:**
  - Cada venta genera de manera determinística un archivo PDF almacenado en la ruta local permanente:
    `getApplicationDocumentsDirectory()/boletas/boleta_{ventaId}.pdf`
  - Prohibido el uso exclusivo de directorios temporales que puedan ser eliminados por el recolector de basura del sistema operativo.
  - El sistema verifica primero si el archivo existe en disco; de lo contrario, lo regenera a partir de los datos históricos de la transacción.
- **Diseño del Ticket Boleta:**
  - Cabecera: Nombre del negocio y datos fiscales/de contacto configurados (omitir campos opcionales vacíos), Número correlativo (`B001-XXXXXX`), Fecha y Hora exacta.
  - En pagos en efectivo, incluir el monto recibido y el vuelto cuando se haya ingresado el monto recibido.
  - Mostrar subtotal con IGV incluido, base imponible e IGV incluido al 18 %. Para un total que ya incluye IGV: `IGV = total × 18 / 118` y `Base imponible = total − IGV`.
  - Datos del Cliente: DNI/RUC (opcional) o "Cliente General".
  - Tabla de Detalle: Cantidad, Descripción de la variante, Precio Unitario, Total.
  - Resumen Financiero: Subtotal, Descuento aplicado, Total General, Método de pago utilizado, Monto recibido y Vuelto entregado.
  - Pie de página: Código hash de trazabilidad y mensaje de agradecimiento.

### MÓDULO 12: Gestión Integral de Mermas y Desperdicios
- **Tipos de Merma:**
  1. Merma de Insumo Crudo (ej. tomate malogrado, harina humedecida, queso vencido).
  2. Merma de Producto Preparado (ej. masa quemada, pizza caída al piso, sobrante no reutilizable).
- **Campos de Auditoría:** Identificador de entidad, Cantidad exacta y unidad, Fecha/hora, Motivo categorizado (`Vencimiento`, `Rotura/Caída`, `Error de Cocina`, `Mala Calidad Proveedor`), Usuario responsable y Costo financiero total de la pérdida.
- Impacto: Descuenta inmediatamente el inventario correspondiente y suma al indicador de pérdidas operativas en el P&L.

### MÓDULO 13: Sesiones de Caja, Flujo de Dinero y Arqueo Ciego
- **Ciclo Operativo por Sesión de Caja (`RN-06`):**
  - La jornada operativa de ventas, gastos y cierre se rige por la **sesión de caja activa (`sesion_caja_id`)**. Una sesión iniciada el viernes a las 19:00 y cerrada el sábado a las 02:30 de la madrugada pertenece íntegramente a esa `sesion_caja_id`.
- **Apertura de Caja:**
  - Requiere ingreso de "Monto de Apertura / Fondo de Caja" (Efectivo inicial para vueltos).
  - Bloqueo total del POS: No se permite realizar ninguna venta si no hay una sesión abierta.
- **Movimientos de Caja durante el Turno:**
  - Entradas de efectivo (Ventas automáticas, aportes de capital).
  - Salidas de efectivo (Gastos menores, compras al contado, adelantos a proveedores, retiros de emergencia).
- **Proceso de Arqueo y Cierre Ciego Centralizado (`RN-04` / `C-11`):**
  - `CashCloseSummary` es la única fuente de cálculo del cuadre de caja para la pantalla, el repositorio y el PDF.
  - Al cerrar caja, el sistema solicita al usuario contar físicamente el dinero e ingresar:
    - `Efectivo Contado Real`: Billetes y monedas presentes físicamente en el cajón.
    - `Transferencias / Digital Confirmado`: Sumatoria de cobros digitales (`yape`, `plin`, `yape/plin`, `transferencia`, `tarjeta`) de la sesión.
  - **Fórmula del Balance y Diferencia:**
    $$\text{Efectivo Esperado} = \text{Monto Apertura} + \text{Ventas Efectivo} - \text{Salidas Efectivo}$$
    $$\text{Diferencia Efectivo} = \text{Efectivo Contado Real} - \text{Efectivo Esperado}$$
- **Semáforo Financiero de Arqueo:**
  - `Verde`: $\text{Diferencia} = 0.00$ (Caja cuadrada exacta).
  - `Rojo`: $\text{Diferencia} < 0.00$ (Faltante de dinero en caja).
  - `Naranja`: $\text{Diferencia} > 0.00$ (Sobrante no justificado en caja).
- **Arqueo PDF y Reapertura Excepcional:**
  - Generación obligatoria del PDF de Cierre con el resumen detallado para el dueño.
  - La sesión pasa a estado `cerrada`. Solo un Administrador activo y no bloqueado (`activo = 1 AND bloqueado = 0`) puede realizar una reapertura excepcional justificada mediante contraseña, quedando auditado el evento.

### MÓDULO 14: Reportes Financieros Analíticos y Estado de Resultados (P&L)
- **Métricas Clave (KPIs):**
  - Ingresos Totales Brutos (Desglose Efectivo vs. Digital/Bancario).
  - **Costo de Mercadería Vendida (COGS / Food Cost — `RN-05` / `C-15`):** Se calcula **priorizando el costo automático de la receta activa** de cada variante vendida (`Recetas` + `DetallesReceta` + costo de `Insumos`), utilizando `costo_estimado_manual` únicamente como respaldo cuando la variante no tenga receta configurada.
  - Gastos Operativos de Caja (Suministros, servicios, mermas).
  - Beneficio Neto Operativo ($\text{Ingresos} - \text{COGS} - \text{Gastos}$).
- **Filtros Temporales Universales:** "Hoy", "Ayer", "Esta Semana", "Este Mes" y "Rango Personalizado" (`showDateRangePicker`).
- **Exportación Ejecutiva a PDF:**
  - Documento de alta fidelidad estética que incluye encabezado corporativo, tarjetas de KPIs financieros, desglose contable P&L y tabla de los "Top Productos Más Vendidos" con cantidad y facturación generada.

### MÓDULO 15: Dashboard Ejecutivo en Tiempo Real
- **Resumen Instantáneo:** Tarjeta superior con gradiente premium que muestra Ventas del Día, Gastos del Día y Ganancia Estimada en vivo.
- **Alertas Proactivas:** Contador de insumos con stock crítico (en rojo) y total de Cuentas por Pagar vencidas o próximas a vencer.
- **Acceso Rápido Ergonómico:** Botones de acción directa hacia "Apertura/Cierre de Caja", "Nueva Venta (POS)", "Preparación de Hoy", "Sugerencias IA" y "Reportes".
- **Actualización Reactiva y Pull-to-Refresh (`C-16`):** Actualización al retornar de rutas operativas y mediante gesto Pull-to-Refresh, evitando el sondeo agresivo cada 5 segundos.
- **Área segura táctil:** El desplazamiento inferior debe respetar la zona de navegación del sistema para que las tarjetas y accesos rápidos no queden detrás de los controles en pantalla del teléfono.

### MÓDULO 16: Gestión de Usuarios y Perfil (`RN-10`, `RN-11` / `C-05`, `C-27`, `C-28`)
- La administradora puede crear, editar, **bloquear/desbloquear temporalmente (`bloqueado = 1 / 0`) y desactivar/reactivar usuarios dados de baja lógica (`activo = 0 / 1`)**, impidiendo el auto-bloqueo/auto-baja del administrador en sesión y registrando cada acción en `LogsAuditoria`.
- Los roles implementados son `admin` y `empleado` (el formulario describe al empleado como cajero/preparador).
- Desde el perfil cada usuario puede editar la información propia permitida y cerrar sesión (limpiando el carrito y estados en memoria). Solo el administrador puede configurar o renovar la clave de rescate, que se presenta una sola vez.
- El restablecimiento autónomo de la contraseña del administrador utiliza su nombre de usuario (`username`) y clave de rescate.

### MÓDULO 17: Copias de Seguridad, Recuperación e Identidad Android (`RN-08`, `RN-09` / `C-17`, `C-20`)
- **Identidad de Producción (`RN-09`):** `applicationId = "com.kimipizza.pos"` y nombre visible **`Kimi Pizza POS`**, firmado con keystore de producción fuera del control de versiones.
- **Exclusión de Android Auto Backup (`RN-08`):** Se desactiva el backup automático en la nube de Android para `pizzaapp_secure.db` (`dataExtractionRules` / `fullBackupContent`) para evitar bases de datos huérfanas de su clave de Android Keystore.
- **Copia portátil (`.kpzbackup`):** Único mecanismo oficial para migrar entre dispositivos, cifrado con AES-256-GCM y clave derivada mediante PBKDF2-HMAC-SHA256 (310.000 iteraciones, ejecutado en `Isolate.run` para no bloquear la UI). Requiere contraseña de al menos 12 caracteres.
- **Copia local automática:** Crea una copia cifrada diaria en el almacenamiento privado del dispositivo, conserva las 7 copias más recientes y guarda su clave en `FlutterSecureStorage` del mismo dispositivo.
- **Restauración:** Verifica contraseña y formato, crea una copia local previa al reemplazo y, al finalizar, **cierra la sesión en memoria y reinicia los controladores** obligando a autenticar la cuenta recuperada.

---

## 5. Esquema Canónico de Base de Datos (SQLite + SQLCipher)

Toda la base de datos se estructura bajo el estándar de nombres `snake_case`, con integridad referencial forzada (`PRAGMA foreign_keys = ON;`):

```sql
-- 1. CONFIGURACIÓN Y NEGOCIO
CREATE TABLE IF NOT EXISTS configuracion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre_negocio TEXT NOT NULL DEFAULT 'KIMI PIZZA',
  ruc TEXT,
  direccion TEXT,
  telefono TEXT,
  mensaje_ticket TEXT,
  qr_pago_path TEXT,
  updated_at TEXT NOT NULL
);

-- 2. USUARIOS Y SEGURIDAD
CREATE TABLE IF NOT EXISTS usuarios (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  nombre_completo TEXT NOT NULL,
  rol TEXT NOT NULL CHECK(rol IN ('admin', 'empleado')),
  correo TEXT,
  foto_perfil_path TEXT,
  recovery_code_hash TEXT,
  activo INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

-- 3. INSUMOS Y MATERIA PRIMA
CREATE TABLE IF NOT EXISTS insumos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT UNIQUE NOT NULL,
  categoria TEXT NOT NULL,
  unidad_base TEXT NOT NULL CHECK(unidad_base IN ('kg', 'g', 'l', 'ml', 'und', 'pqte')),
  contenido_paquete REAL DEFAULT 1,
  stock_actual REAL NOT NULL DEFAULT 0,
  stock_minimo REAL NOT NULL DEFAULT 0,
  costo_unitario_promedio REAL NOT NULL DEFAULT 0,
  foto_path TEXT,
  activo INTEGER NOT NULL DEFAULT 1
);

-- 4. PROVEEDORES
CREATE TABLE IF NOT EXISTS proveedores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ruc_dni TEXT UNIQUE,
  razon_social TEXT NOT NULL,
  telefono TEXT,
  correo TEXT,
  direccion TEXT,
  activo INTEGER NOT NULL DEFAULT 1
);

-- 5. COMPRAS Y EGRESOS UNIFICADOS
CREATE TABLE IF NOT EXISTS compras (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha TEXT NOT NULL,
  proveedor_id INTEGER,
  tipo_compra TEXT NOT NULL CHECK(tipo_compra IN ('insumo', 'activo')),
  total REAL NOT NULL,
  metodo_pago TEXT NOT NULL CHECK(metodo_pago IN ('contado', 'credito')),
  adelanto REAL DEFAULT 0,
  saldo_pendiente REAL DEFAULT 0,
  estado_pago TEXT NOT NULL CHECK(estado_pago IN ('pagado', 'pendiente')),
  comprobante_foto_path TEXT,
  nota TEXT,
  usuario_id INTEGER NOT NULL,
  FOREIGN KEY(proveedor_id) REFERENCES proveedores(id),
  FOREIGN KEY(usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS detalle_compras (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  compra_id INTEGER NOT NULL,
  insumo_id INTEGER,
  activo_fijo_id INTEGER,
  cantidad REAL NOT NULL,
  costo_unitario REAL NOT NULL,
  subtotal REAL NOT NULL,
  FOREIGN KEY(compra_id) REFERENCES compras(id) ON DELETE CASCADE,
  FOREIGN KEY(insumo_id) REFERENCES insumos(id)
);

CREATE TABLE IF NOT EXISTS cuentas_por_pagar (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  compra_id INTEGER NOT NULL,
  proveedor_id INTEGER,
  monto_total REAL NOT NULL,
  adelanto REAL DEFAULT 0,
  saldo_pendiente REAL NOT NULL,
  cuotas INTEGER DEFAULT 1,
  fecha_vencimiento TEXT,
  estado TEXT NOT NULL CHECK(estado IN ('pendiente', 'pagado')),
  motivo TEXT,
  FOREIGN KEY(compra_id) REFERENCES compras(id) ON DELETE CASCADE,
  FOREIGN KEY(proveedor_id) REFERENCES proveedores(id)
);

-- 6. ACTIVOS FIJOS
CREATE TABLE IF NOT EXISTS activos_fijos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  categoria TEXT NOT NULL,
  cantidad INTEGER NOT NULL DEFAULT 1,
  modalidad_adquisicion TEXT NOT NULL CHECK(modalidad_adquisicion IN ('comprado', 'alquilado', 'prestado', 'regalado')),
  costo_total REAL DEFAULT 0,
  costo_unitario REAL DEFAULT 0,
  tipo_alquiler TEXT,
  estado_operativo TEXT NOT NULL CHECK(estado_operativo IN ('bueno', 'en_reparacion', 'fuera_de_servicio')),
  fecha_adquisicion TEXT NOT NULL,
  foto_path TEXT,
  nota TEXT
);

-- 7. PRODUCTOS, VARIANTES Y RECETAS
CREATE TABLE IF NOT EXISTS productos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT UNIQUE NOT NULL,
  categoria TEXT NOT NULL,
  descripcion TEXT,
  imagen_path TEXT,
  activo INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS variantes_producto (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  producto_id INTEGER NOT NULL,
  nombre_variante TEXT NOT NULL,
  precio_venta REAL NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(producto_id) REFERENCES productos(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS recetas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  variante_id INTEGER NOT NULL,
  insumo_id INTEGER NOT NULL,
  cantidad REAL NOT NULL,
  unidad_medida TEXT NOT NULL,
  UNIQUE(variante_id, insumo_id),
  FOREIGN KEY(variante_id) REFERENCES variantes_producto(id) ON DELETE CASCADE,
  FOREIGN KEY(insumo_id) REFERENCES insumos(id)
);

-- 8. PROMOCIONES
CREATE TABLE IF NOT EXISTS promociones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  precio REAL NOT NULL,
  dias_semana TEXT NOT NULL, -- Ej: '1,2,3,4,5'
  hora_inicio TEXT,
  hora_fin TEXT,
  imagen_path TEXT,
  activa INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS promocion_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  promocion_id INTEGER NOT NULL,
  variante_id INTEGER NOT NULL,
  cantidad INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY(promocion_id) REFERENCES promociones(id) ON DELETE CASCADE,
  FOREIGN KEY(variante_id) REFERENCES variantes_producto(id)
);

-- 9. PREPARACIÓN DIARIA Y TRANSFORMACIONES
CREATE TABLE IF NOT EXISTS preparaciones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha TEXT NOT NULL,
  ciclo_operativo TEXT NOT NULL,
  usuario_id INTEGER NOT NULL,
  notas_generales TEXT,
  FOREIGN KEY(usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS items_preparacion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  preparacion_id INTEGER NOT NULL,
  variante_id INTEGER NOT NULL,
  cantidad INTEGER NOT NULL, -- Admite números negativos para faltantes
  sobrante INTEGER NOT NULL DEFAULT 0,
  enviado_merma INTEGER NOT NULL DEFAULT 0,
  llevado_manana INTEGER NOT NULL DEFAULT 0,
  notas TEXT,
  FOREIGN KEY(preparacion_id) REFERENCES preparaciones(id) ON DELETE CASCADE,
  FOREIGN KEY(variante_id) REFERENCES variantes_producto(id)
);

CREATE TABLE IF NOT EXISTS transformaciones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  variante_origen_id INTEGER NOT NULL,
  variante_destino_id INTEGER NOT NULL,
  insumo_adicional_id INTEGER,
  cantidad_insumo REAL DEFAULT 0,
  unidad_insumo TEXT,
  FOREIGN KEY(variante_origen_id) REFERENCES variantes_producto(id),
  FOREIGN KEY(variante_destino_id) REFERENCES variantes_producto(id),
  FOREIGN KEY(insumo_adicional_id) REFERENCES insumos(id)
);

-- 10. SESIONES DE CAJA Y MOVIMIENTOS
CREATE TABLE IF NOT EXISTS sesiones_caja (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha_apertura TEXT NOT NULL,
  ciclo_operativo TEXT NOT NULL,
  monto_apertura REAL NOT NULL DEFAULT 0,
  usuario_apertura_id INTEGER NOT NULL,
  estado TEXT NOT NULL CHECK(estado IN ('abierta', 'cerrada', 'reabierta')),
  fecha_cierre TEXT,
  usuario_cierre_id INTEGER,
  total_efectivo_sistema REAL DEFAULT 0,
  total_yape_plin REAL DEFAULT 0,
  total_tarjeta REAL DEFAULT 0,
  total_gastos REAL DEFAULT 0,
  efectivo_contado REAL DEFAULT 0,
  diferencia REAL DEFAULT 0,
  nota_cierre TEXT,
  FOREIGN KEY(usuario_apertura_id) REFERENCES usuarios(id),
  FOREIGN KEY(usuario_cierre_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS movimientos_caja (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sesion_caja_id INTEGER NOT NULL,
  tipo TEXT NOT NULL CHECK(tipo IN ('entrada', 'salida', 'venta', 'compra', 'apertura')),
  metodo_pago TEXT NOT NULL CHECK(metodo_pago IN ('efectivo', 'yape', 'plin', 'tarjeta')),
  monto REAL NOT NULL,
  descripcion TEXT,
  fecha TEXT NOT NULL,
  FOREIGN KEY(sesion_caja_id) REFERENCES sesiones_caja(id) ON DELETE CASCADE
);

-- 11. VENTAS Y FACTURACIÓN
CREATE TABLE IF NOT EXISTS ventas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha TEXT NOT NULL,
  ciclo_operativo TEXT NOT NULL,
  sesion_caja_id INTEGER NOT NULL,
  usuario_id INTEGER NOT NULL,
  subtotal REAL NOT NULL,
  descuento REAL NOT NULL DEFAULT 0,
  total REAL NOT NULL,
  metodo_pago TEXT NOT NULL CHECK(metodo_pago IN ('efectivo', 'yape', 'plin', 'tarjeta', 'mixto')),
  monto_recibido REAL,
  vuelto REAL DEFAULT 0,
  boleta_pdf_path TEXT,
  nota TEXT,
  FOREIGN KEY(sesion_caja_id) REFERENCES sesiones_caja(id),
  FOREIGN KEY(usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE IF NOT EXISTS detalle_ventas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  venta_id INTEGER NOT NULL,
  variante_id INTEGER,
  promocion_id INTEGER,
  cantidad INTEGER NOT NULL,
  precio_unitario REAL NOT NULL,
  subtotal REAL NOT NULL,
  es_cortesia INTEGER NOT NULL DEFAULT 0,
  nota_item TEXT,
  FOREIGN KEY(venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
  FOREIGN KEY(variante_id) REFERENCES variantes_producto(id),
  FOREIGN KEY(promocion_id) REFERENCES promociones(id)
);

-- 12. GASTOS GENERALES Y MERMAS
CREATE TABLE IF NOT EXISTS gastos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha TEXT NOT NULL,
  categoria TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  monto REAL NOT NULL,
  sesion_caja_id INTEGER,
  FOREIGN KEY(sesion_caja_id) REFERENCES sesiones_caja(id)
);

CREATE TABLE IF NOT EXISTS mermas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha TEXT NOT NULL,
  tipo_entidad TEXT NOT NULL CHECK(tipo_entidad IN ('insumo', 'variante')),
  insumo_id INTEGER,
  variante_id INTEGER,
  cantidad REAL NOT NULL,
  unidad TEXT NOT NULL,
  motivo TEXT NOT NULL,
  costo_perdida REAL NOT NULL DEFAULT 0,
  usuario_id INTEGER NOT NULL,
  FOREIGN KEY(insumo_id) REFERENCES insumos(id),
  FOREIGN KEY(variante_id) REFERENCES variantes_producto(id),
  FOREIGN KEY(usuario_id) REFERENCES usuarios(id)
);
```

---

## 6. Prohibiciones Críticas y Anti-Patrones Excluidos

1. **NO usar contraseñas en texto plano.** Toda credencial debe usar `HashUtils` con Salt.
2. **NO reproducir audio desde URLs remotas.** Los sonidos de confirmación de cobro deben ser assets locales empaquetados en el APK (`assets/sounds/...`). Una falla de conexión no puede romper la venta.
3. **NO realizar llamadas asíncronas no seguras a `BuildContext`:** Usar siempre verificación de `if (!mounted) return;` antes de manipular context tras un `await`.
4. **NO recalcular reglas de negocio en widgets:** Prohibido escribir fórmulas matemáticas de stock o balances en archivos dentro de `lib/screens/`.
5. **NO hacer mutaciones de base de datos fuera de transacciones:** Si una acción modifica múltiples entidades, debe envolverse en `db.transaction`.
6. **NO almacenar boletas en carpetas temporales volátiles:** Deben persistir en `getApplicationDocumentsDirectory()/boletas/`.
7. **NO mezclar ciclo de caja con `DateTime.now().day`:** La fecha del ciclo de caja es la de su apertura, sin importar si el cierre ocurre a las 3:00 AM del día siguiente.

---

## 7. Protocolo de Verificación y Compilación (Zero Regressions)

Cada fase de desarrollo debe superar obligatoriamente este checklist antes de considerarse concluida:
1. `flutter analyze`: Cero errores de compilación y cero advertencias críticas.
2. `flutter test`: Todas las pruebas unitarias de cálculo de stock, sugerencias y conversiones pasan al 100%.
3. **Integridad de Base de Datos:** Verificación de ejecución limpia de DDL y scripts de migración sin excepciones de SQLite.
4. **Verificación en Dispositivo Real:** Validar renderizado correcto en Android (sin desbordes visuales / RenderFlex Overflow), persistencia de archivos PDF y retroalimentación auditiva y háptica.
