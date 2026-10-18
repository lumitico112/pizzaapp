# CATÁLOGO DE REGLAS DE NEGOCIO CANÓNICAS — KIMI PIZZA POS
**Documento:** BR-2026-V3.0 (Consolidated Audit & Approved Business Decisions Edition)  
**Proyecto:** KIMI PIZZA POS (`com.kimipizza.pos`)  
**Estado:** Especificación de Dominio Oficial e Inmutable  

---

## 1. SEGURIDAD, AUTENTICACIÓN Y ROLES (BR-SEC)

- **BR-SEC-01 (Inicialización Atómica — `C-30`):** Cuando la base de datos no contiene usuarios (`COUNT(Usuarios) == 0`), el sistema bloquea todos los accesos operativos y ejecuta el flujo de "Onboarding Administrador". La grabación de la configuración inicial del negocio y la creación del usuario administrador deben ejecutarse en una **única transacción atómica** para impedir estados de inicialización parcial.
- **BR-SEC-02 (Criptografía de Contraseñas y Migración Legacy — `C-06`):** Las contraseñas deben procesarse mediante derivación de claves `PBKDF2-HMAC-SHA256` con sal aleatoria individual por usuario (`HashUtils.hashPassword`), manteniendo soporte de verificación transparente para hashes legacy SHA-256 de 64 caracteres hexadecimales (actualizando el hash automáticamente al iniciar sesión). Longitud mínima: 8 caracteres.
- **BR-SEC-03 (Clave de Rescate Autónoma):** Durante la creación del administrador, se genera un token de 24 caracteres en bloques `XXXXXX-XXXXXX-XXXXXX-XXXXXX` usando `Random.secure()`. En base de datos solo se persiste el hash de este token (`HashUtils.hashRecoveryCode`).
- **BR-SEC-04 (Restablecimiento Sin Red con Caducidad y Límite — `C-06`):** Un administrador puede restablecer su contraseña proveyendo su `username` exacto y la clave de rescate física, sujeto a validación de intentos máximos y vigencia, devolviendo mensajes genéricos que no filtren estados internos.
- **BR-SEC-05 (Roles disponibles en la app):** La app persiste los roles `admin` y `empleado` (presentado como cajero/preparador). Cada acción sensible debe validar su autorización en el servicio/repositorio que la ejecuta y no depender solamente de que un botón esté oculto.
- **BR-SEC-06 (Persistencia e Higiene de Sesión — `C-18`):** La sesión del usuario permanece abierta al navegar; al ejecutar "Cerrar Sesión" (`logout()`) o tras restaurar una copia de seguridad, **se debe limpiar obligatoriamente el carrito del POS (`PosController`) y reiniciar el estado en memoria de los controladores** para evitar fugas de información entre sesiones.
- **BR-SEC-07 (Autenticación exclusiva por `username` y Bloqueo Efectivo — `RN-10` / `C-05` / `C-27`):** El inicio de sesión autentica exclusivamente por nombre de usuario (`username`), filtrando obligatoriamente `activo = 1 AND bloqueado = 0` tanto en el login general como en reautenticaciones administrativas. La etiqueta visual del campo de acceso debe decir únicamente **`Usuario`**.
- **BR-SEC-08 (Ciclo de Vida y Reactivación Auditada de Usuarios — `RN-11` / `C-28`):** El administrador puede bloquear/desbloquear temporalmente (`bloqueado = 1 / 0`) y desactivar/reactivar usuarios dados de baja lógica (`activo = 0 / 1`). Queda prohibido el auto-bloqueo o auto-desactivación del administrador con sesión activa, y todo cambio de estado debe quedar registrado en `LogsAuditoria`.

---

## 2. INVENTARIO, INSUMOS Y CONVERSIONES (BR-INV)

- **BR-INV-01 (Unidades Canónicas Universales):**
  - Masa: Kilogramos (`Kg`), Gramos (`g`). Factor: $1 \text{ Kg} = 1000 \text{ g}$.
  - Volumen: Litros (`L`), Mililitros (`ml`). Factor: $1 \text{ L} = 1000 \text{ ml}$.
  - Conteo: Unidades (`Und`), Paquetes (`Pqte`). Factor: $1 \text{ Pqte} = n \text{ Und}$ (donde $n$ es `contenido_paquete` definido por insumo).
- **BR-INV-02 (Centralización de Conversiones):** Ningún cálculo de conversión puede realizarse en vistas o pantallas. Todo cómputo debe ejecutarse a través del conversor centralizado de dominio (`UnitConverter` / `ConversionesHelper`).
- **BR-INV-03 (Semáforo Dinámico de Stock):**
  - $\text{Verde} \iff \text{Stock} > 1.5 \times \text{Stock Mínimo}$.
  - $\text{Amarillo} \iff \text{Stock Mínimo} \le \text{Stock} \le 1.5 \times \text{Stock Mínimo}$.
  - $\text{Rojo} \iff \text{Stock} < \text{Stock Mínimo}$ (Alerta crítica).
- **BR-INV-04 (Principio de Causalidad del Stock):** Toda modificación al valor de stock de un insumo o variante debe derivar de un evento trazable escrito mediante `StockMovementWriter` dentro de la misma transacción: Compra, Preparación, Venta, Cortesía, Transformación, Merma o Ajuste Físico Justificado.
- **BR-INV-05 (Costo Promedio Ponderado):** Al ingresar una nueva compra de insumos, el costo unitario del insumo se recalcula según:
  $$\overline{CU}_{\text{nuevo}} = \frac{(\text{Stock Actual} \times \overline{CU}_{\text{anterior}}) + (\text{Cantidad Comprada} \times CU_{\text{compra}})}{\text{Stock Actual} + \text{Cantidad Comprada}}$$
- **BR-INV-06 (Contenido de paquete):** Cuando la unidad de stock de un insumo es `Paquetes`, se guarda el número de unidades contenidas. Una receta que consume unidades convierte esa cantidad a fracción de paquete antes de modificar el stock.

---

## 3. PROVEEDORES, COMPRAS Y CUENTAS POR PAGAR (BR-PUR)

- **BR-PUR-01 (Flujo Unificado de Compras):** Toda adquisición de materia prima o activos fijos pasa por el módulo unificado de compras/activos con trazabilidad completa.
- **BR-PUR-02 (Cálculo de Costo Unitario):** El costo unitario es un valor derivado obligatorio:
  $$CU = \frac{\text{Costo Total}}{\text{Cantidad}}$$
- **BR-PUR-03 (Condición de Pago Contado):** Una compra con método de pago `Contado` genera un egreso inmediato en la sesión de caja activa.
- **BR-PUR-04 (Condición de Pago Crédito y CxP):**
  - Si la compra es a `Crédito`, puede registrarse un `Adelanto` inicial ($0 \le \text{Adelanto} \le \text{Total}$).
  - El adelanto genera salida en la caja activa si $\text{Adelanto} > 0$.
  - Se genera automáticamente una única fila en `CuentasPorPagar` con $\text{Saldo Pendiente} = \text{Costo Total} - \text{Adelanto}$.
- **BR-PUR-05 (Amortización de Cuentas por Pagar):** El pago de cuotas de una CxP registra el abono en `PagosCuentaPorPagar`, actualiza `monto_pagado` y asienta el gasto y el egreso en la sesión de caja abierta mediante IDs explícitos.
- **BR-PUR-06 (Edición de Compras a Crédito con Abonos Previos — `RN-01` / `C-01`):**
  - Se permite corregir una compra a crédito que ya tenga abonos posteriores en `PagosCuentaPorPagar`, recalculando siempre:
    $$\text{Monto Pagado Total} = \text{Adelanto Inicial Actualizado} + \sum \text{Abonos Posteriores (`PagosCuentaPorPagar`)}$$
    $$\text{Nuevo Saldo Pendiente} = \text{Nuevo Costo Total} - \text{Monto Pagado Total}$$
  - **Restricción:** Si $\text{Nuevo Costo Total} < \text{Monto Pagado Total}$, la edición se rechaza con excepción de negocio.
  - **No duplicidad de adelanto:** Editar el adelanto inicial jamás debe duplicar filas en `Gastos` ni en `MovimientosCaja`; debe actualizar o compensar el registro original vinculado por ID.
- **BR-PUR-07 (Bloqueo de Eliminación Directa de Gastos Vinculados y Reversión por ID — `RN-02` / `C-02`):**
  - Queda prohibido eliminar desde la bandeja genérica de Gastos cualquier registro originado por una compra o por un abono de `CuentasPorPagar`.
  - La anulación de un abono solo se ejecuta desde el módulo de **Cuentas por Pagar**, revirtiendo en una sola transacción el registro en `PagosCuentaPorPagar`, el saldo en `CuentasPorPagar`, el `Gasto` y el `MovimientoCaja` mediante claves foráneas/IDs explícitos (prohibido el borrado por coincidencia aproximada de monto y fecha).

---

## 4. ACTIVOS FIJOS (BR-AST)

- **BR-AST-01 (Modalidades de Adquisición):**
  - `Comprado`: Requiere costo total; aplica lógica de compra al contado o crédito (CxP).
  - `Alquilado`: Requiere costo de canon y periodicidad (`Diario`, `Semanal`, `Mensual`, `Anual`).
  - `Prestado`: Registro patrimonial con valor referencial sin egreso de caja.
  - `Regalado`: Valoración simbólica para auditoría de inventario físico.
- **BR-AST-02 (Semáforo de Estado Operativo de Activos):**
  - `En Uso` / `Bueno`: Verde.
  - `En Reparación`: Amarillo.
  - `Fuera de Servicio` / `Baja`: Rojo.
- **BR-AST-03 (Integridad Referencial en Activos a Crédito — `C-07` / `C-09`):**
  - Un activo fijo comprado a crédito genera su obligación en `CuentasPorPagar` con `insumo_id = NULL` y `activo_fijo_id` apuntando al activo creado. Queda prohibido usar el valor centinela `insumo_id = 0`.

---

## 5. CATÁLOGO, RECETAS Y PRECIOS (BR-CAT)

- **BR-CAT-01 (Jerarquía Producto-Variante):** Los clientes compran variantes, no productos genéricos. Cada variante (Personal, Mediana, Familiar) tiene su propio precio de venta y stock físico.
- **BR-CAT-02 (Unicidad en Recetas / Upsert):** Un insumo solo puede figurar una vez por receta de variante. Si se agrega un insumo ya existente, se incrementa o actualiza la dosificación.
- **BR-CAT-03 (Costeo Automático de Recetas - COGS):** El costo de una variante se computa sumando las cantidades de sus ingredientes multiplicadas por sus costos unitarios promedio ponderados:
  $$\text{COGS}_{\text{variante}} = \sum_{i=1}^{m} (\text{Cantidad Insumo}_i \times \overline{CU}_i)$$
- **BR-CAT-04 (Independencia del Precio Base):** Editar el precio de un ítem en una venta del POS jamás sobreescribe el precio catálogo de la variante en base de datos.
- **BR-CAT-05 (Receta por variante):** La receta es propia de cada variante independiente. Usar los mismos insumos no implica compartir dosificaciones; las variantes derivadas solo incorporan receta heredada cuando la relación base está configurada.

---

## 6. PREPARACIÓN DIARIA, TRANSFORMACIONES Y FALTANTES (BR-PRP)

- **BR-PRP-01 (Doble Inventario Operativo):** El sistema mantiene dos inventarios paralelos e interrelacionados:
  1. Inventario de Materia Prima (Insumos en almacén/despensa).
  2. Inventario de Producto Preparado (Pizzas listas para venta en cocina).
- **BR-PRP-02 (Descuento de Insumos por Preparación):** Registrar $K$ unidades de una variante en la planilla de preparación incrementa el stock de dicha variante en $+K$ y descuenta de inmediato los insumos de su receta en almacén.
- **BR-PRP-03 (Cantidades Negativas / Faltantes):** Se admiten cantidades menores a 0 en la planilla de preparación para documentar pizzas demandadas y horneadas de urgencia durante el servicio sin registro previo.
- **BR-PRP-04 (Invariante Física de Sobrantes, Merma y Traslado — `RN-03` / `C-03` / `C-04` / `C-10`):**
  - Las unidades preparadas no vendidas se declaran como `Llevar para mañana` (`llevado_manana`) o `Enviar a Merma` (`enviado_merma`).
  - **Invariante obligatoria:** En todo momento debe cumplirse:
    $$\text{enviado\_merma} + \text{llevado\_manana} \le \text{cantidad\_preparada}$$
    y la cantidad descontada por merma/traslado nunca puede superar el `stock_actual` preparado disponible de la variante (prohibido registrar en `Merma` una cantidad mayor al stock realmente descontado).
  - **Idempotencia en traslado (`llevarParaManana`):** El `UPDATE` sobre el ítem de origen debe verificar exactamente `1` fila afectada antes de insertar o acumular (`UPSERT`) en la preparación del día siguiente.
  - **Persistencia de `sobrante`:** Al cerrar sobrantes, la columna `ItemsPreparacion.sobrante` se actualiza con la suma $(\text{enviado\_merma} + \text{llevado\_manana})$ para alimentar el algoritmo de sugerencias.
- **BR-PRP-05 (Regla de Transformaciones en Vivo):** Una pizza base preparada puede transformarse en otra variante mediante la adición de ingredientes:
  $$\text{Variante Origen} + \text{Insumo Adicional} \longrightarrow \text{Variante Destino}$$
  - Descuenta 1 unidad física de `Variante Origen`, descuenta la cantidad especificada de `Insumo Adicional` del almacén e incrementa 1 unidad física en `Variante Destino`.
- **BR-PRP-06 (Caja abierta y borrador de sobrantes):** El ingreso/guardado de preparación requiere caja abierta. La decisión sobre sobrantes anteriores se guarda en borrador hasta confirmar el formulario. Un traslado no vuelve a sumar unidades al stock ni a consumir otra vez la receta; la merma sí descuenta stock preparado.

---

## 7. MOTOR HEURÍSTICO DE SUGERENCIAS (BR-SUG)

- **BR-SUG-01 (Fórmula Canónica de Planificación — `RN-03` / `C-10`):**
  $$\text{Sugerencia} = \max\left(0, \text{Round}\left( (\bar{V}_{\text{mismo\_día}} \times F_{\text{estacional}}) + Faltantes_{\text{anterior}} - Sobrantes_{\text{válidos}} \right)\right)$$
  - $\bar{V}_{\text{mismo\_día}}$: Promedio de ventas de los últimos 4 ciclos correspondientes al mismo día de la semana.
  - $Sobrantes_{\text{válidos}}$: Se alimenta de la columna `ItemsPreparacion.sobrante` ($\text{enviado\_merma} + \text{llevado\_manana}$).

---

## 8. PUNTO DE VENTA (POS), COBROS Y BOLETAS (BR-POS)

- **BR-POS-01 (Requisito de Caja Abierta):** Ninguna venta puede iniciarse ni cobrarse si no existe una sesión de caja en estado `abierta`.
- **BR-POS-02 (Cortesías):** Cualquier producto o bebida puede marcarse como cortesía (precio S/ 0.00), descontando siempre el recurso inventariable correspondiente (stock preparado o receta).
- **BR-POS-03 (Validación de Efectivo y Vuelto):**
  - Si el método es `Efectivo` y se indica monto recibido, debe cumplirse: $\text{Monto Recibido} \ge \text{Total Venta}$ y $\text{Vuelto} = \text{Monto Recibido} - \text{Total Venta}$.
- **BR-POS-04 (Persistencia de Boletas PDF):** Todo cobro confirmado debe persistir su boleta en `getApplicationDocumentsDirectory()/boletas/boleta_{id}.pdf`.
- **BR-POS-05 (Confirmación Sensorial Offline):** Cada venta exitosa emite confirmación mediante recursos locales empaquetados (sin llamadas a URLs remotas).
- **BR-POS-06 (Bebidas por vaso):** Una variante de categoría Bebidas con nombre que incluya `Vaso` consume por unidad una receta que contenga volumen en ml/litros y el insumo del vaso.
- **BR-POS-07 (Detalle tributario de boleta):** Para precios que incluyen IGV del 18 %, `IGV = total × 18 / 118` y `base imponible = total − IGV`.
- **BR-POS-08 (Bloqueo estricto de productos `'momento'` o `'ambos'` sin receta o sin stock — `RN-07`):** No se permite vender una variante configurada como `'momento'` o `'ambos'` si carece de receta activa o si alguno de sus insumos no tiene stock suficiente, mostrando un mensaje claro al cajero.

---

## 9. SESIONES DE CAJA, ARQUEO Y CICLO NOCTURNO (BR-CSH)

- **BR-CSH-01 (Prevalencia de la Sesión de Caja en Operación Nocturna — `RN-06`):** La jornada operativa de ventas, gastos y cierre se rige por la **sesión de caja activa (`sesion_caja_id`)**, sin importar si las operaciones o el cierre ocurren después de las `00:00` (medianoche).
- **BR-CSH-02 (Arqueo Ciego y Fuente Única `CashCloseSummary` — `RN-04` / `C-11`):**
  - `CashCloseSummary` es la única fuente de verdad para calcular el cuadre de caja en pantalla, repositorio y PDF.
  - Los cobros se agrupan en dos rubros oficiales: **Efectivo** (`efectivo`) y **Digital/Bancario** (`yape`, `plin`, `yape/plin`, `transferencia`, `tarjeta`). El método `mixto` permanece deshabilitado hasta que exista desglose explícito de montos.
- **BR-CSH-03 (Fórmula de Balance de Caja):**
  $$\text{Efectivo Esperado} = \text{Monto Apertura} + \text{Ventas Efectivo} - \text{Salidas Efectivo}$$
  $$\text{Diferencia} = \text{Efectivo Contado Real} - \text{Efectivo Esperado}$$
- **BR-CSH-04 (Semáforo de Balance):**
  - $\text{Diferencia} = 0.00 \implies$ Verde (Caja Cuadrada).
  - $\text{Diferencia} < 0.00 \implies$ Rojo (Faltante de Caja).
  - $\text{Diferencia} > 0.00 \implies$ Naranja (Sobrante de Caja).
- **BR-CSH-05 (Reapertura Excepcional):** Una caja cerrada solo puede ser reabierta por un usuario con rol `admin` activo y no bloqueado (`activo = 1 AND bloqueado = 0`), indicando motivo obligatorio en auditoría.

---

## 10. ESTADO DE RESULTADOS (P&L), REPORTES Y RESPALDOS (BR-REP / BR-BCK)

- **BR-REP-01 (Fórmula del Beneficio Neto):**
  $$\text{Beneficio Neto} = \text{Ingresos Totales} - \text{COGS (Costo de Receta)} - \text{Gastos Operativos}$$
- **BR-REP-02 (Prioridad del Costo Automático de Receta sobre Costo Manual — `RN-05` / `C-15`):** En los reportes globales y de rentabilidad (`ReportesService`), el costo de mercadería vendida debe calcularse **priorizando el costo automático de la receta activa de la variante vendida**, utilizando `costo_estimado_manual` únicamente como valor de respaldo cuando la variante no tenga receta configurada.
- **BR-BCK-01 (Exclusión de Android Auto Backup y Uso Exclusivo de `.kpzbackup` — `RN-08` / `RN-09` / `C-20`):** La aplicación de producción (`com.kimipizza.pos` — **Kimi Pizza POS**) desactiva el backup automático en la nube de Android para `pizzaapp_secure.db` y utiliza exclusivamente los archivos portátiles cifrados `.kpzbackup` para migración y restauración entre dispositivos.
