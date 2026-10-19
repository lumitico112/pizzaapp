# MATRIZ MAESTRA DE TRAZABILIDAD — KIMI PIZZA

## 1. Propósito

Esta matriz conecta módulos, eventos de negocio, datos afectados, permisos, dependencias y pruebas. Debe utilizarse antes de implementar correcciones o funcionalidades que afecten más de una capa o módulo.

La regla fundamental es:

> Una operación de negocio importante debe poder rastrearse desde la interacción del usuario hasta la persistencia, los efectos secundarios y las pruebas que la protegen.

---

## 2. Leyenda

- **UI**: interacción/presentación.
- **Dominio**: regla de negocio y cálculos.
- **Datos**: repositorio, datasource, API, DB o almacenamiento.
- **Auditoría**: registro de quién, cuándo y qué cambió.
- **Permiso**: autorización requerida.

---

## 3. Matriz de módulos y dependencias

| Módulo | Fuente principal | Depende de | Impacta | Permisos críticos | Pruebas mínimas |
|---|---|---|---|---|---|
| Usuarios | User / Role / Permission | Auth, Storage | Sesión, configuración, auditoría | Admin para gestión sensible | login, permisos, edición, sesión |
| Configuración | AppSettings / QR | Usuarios, Storage | Ventas, cobros | Admin | guardar, reemplazar, fallback |
| Activos Fijos | Asset | Categorías, Compras | Compras, reportes, auditoría | Según rol | contado, crédito, alquiler, cantidad |
| Insumos | Ingredient | Categorías, Unidades | Compras, recetas, preparación, stock, mermas | Según rol | duplicidad, unidades, stock |
| Proveedores | Supplier | Compras, CxP | Compras, cuentas por pagar | Según rol | duplicidad, editar, desactivar |
| Compras | Purchase / PurchaseItem | Insumos, Activos, Proveedores | Stock, CxP, reportes | Según rol | compra, stock, pago, idempotencia |
| Cuentas por Pagar | Payable | Compras, Proveedores, Pagos | Caja/reportes | Según rol | saldo, adelanto, pago |
| Productos | Product / Variant | Categorías, recetas | Ventas, preparación, promociones | Según rol | variantes, duplicidad |
| Recetas | Recipe / RecipeItem | Insumos, unidades | Preparación, consumo | Según rol | conversiones, duplicidad |
| Preparación | Preparation | Productos, recetas, transformaciones | Ventas, stock, sugerencias, mermas | Según rol | positivo, cero, negativo, sobrantes |
| Transformaciones | TransformationRule / Movement | Productos, insumos, recetas | Preparación, ventas, stock | Según rol | base → variante/producto derivado |
| Ventas | Sale / SaleItem | Productos, preparación, promociones, configuración | Stock, caja, PDF, reportes | Empleado/Admin | precio editable, carrito, stock |
| Pagos | Payment | Venta, configuración QR | Caja, historial | Empleado/Admin | efectivo, Yape/Plin, cortesía |
| Boletas | Receipt / PDF | Venta | Historial, almacenamiento | Según rol | generación, persistencia, visualización |
| Caja | CashSession | Ventas, gastos, pagos | Reportes, sesión | Apertura/cierre restringidos | balance, medianoche, reapertura |
| Mermas | Waste | Insumos/preparación | Stock, reportes | Según rol | motivo, cantidad, doble registro |
| Sugerencias | Suggestion | Ventas, preparación | Preparación | Según rol | día de semana, faltantes, sobrantes |
| Reportes | Read models / consultas | Todos los módulos transaccionales | Dashboard | Según rol | consistencia con fuentes |

---

## 4. Trazabilidad de eventos críticos

### E01 — Registrar usuario

**Entrada:** formulario de usuario.

**Cadena:**

UI → validación → caso de uso CreateUser → repository → persistencia → auditoría si corresponde → actualización de listado.

**Reglas:**
- usuario/correo identificador no debe duplicarse si existe una regla de unicidad;
- asignar únicamente permisos permitidos;
- no almacenar contraseña en texto plano;
- no permitir escalación de privilegios desde un rol inferior.

**Pruebas:** duplicado, rol, contraseña, permisos, persistencia.

### E02 — Editar perfil del administrador

UI → validación → caso de uso UpdateOwnProfile → repository → persistencia → refrescar sesión/perfil.

**Reglas:**
- el administrador puede modificar únicamente los campos autorizados;
- no convertir edición de perfil en edición general de permisos;
- no invalidar sesión sin una razón de seguridad definida.

**Pruebas:** cambio válido, cancelación, datos inválidos, sesión conservada.

### E03 — Configurar QR

UI → ImagePicker/Camera → validación → UpdatePaymentQr → almacenamiento → configuración global.

**Reglas:**
- solo administrador puede cambiarlo;
- reemplazar QR anterior sin crear registros incoherentes;
- ventas deben leer el QR configurado, no una copia local obsoleta;
- si no existe QR, cobro Yape/Plin debe mostrar estado controlado.

### E04 — Registrar compra de insumo

UI → PurchaseUseCase → validación → persistencia compra → movimiento de inventario → CxP si corresponde → auditoría → reportes.

**Reglas:**
- idempotencia para evitar doble registro;
- actualizar stock una sola vez;
- proveedor válido si es requerido;
- costo total y unitario coherentes;
- compra al crédito genera saldo pendiente correcto.

### E05 — Registrar compra de activo

UI → Purchase/Asset flow → guardar compra → crear/asociar activo → persistencia → auditoría → reportes.

**Regla crítica:** no crear un activo duplicado por el mismo evento.

### E06 — Registrar receta

UI → validación → RecipeUseCase → verificar insumo no duplicado → persistencia.

**Reglas:**
- cantidades > 0;
- unidad de receta válida;
- conversión a unidad base centralizada;
- no duplicar el mismo insumo dentro de una receta.

### E07 — Preparar producto

UI → PreparationUseCase → validar cantidades → calcular consumo de insumos → registrar movimientos → generar disponibilidad preparada.

**Regla crítica:** la preparación es la operación que consume insumos para generar disponibilidad de producto preparado.

### E08 — Transformar preparado

Ejemplo: Americana → Hawaiana.

UI → TransformationUseCase → consumir una unidad/base disponible → consumir insumo adicional según regla → registrar transformación → actualizar disponibilidad derivada.

**Regla crítica:** no duplicar físicamente unidades base.

### E09 — Registrar venta

UI → carrito → validación → SaleUseCase → validar caja abierta → validar disponibilidad → registrar venta → consumir disponibilidad → registrar pago → actualizar caja → generar/guardar boleta.

**Reglas:**
- precio editado aplica solo a la venta;
- no modificar precio maestro;
- no vender más de lo disponible, salvo una regla explícita del negocio;
- evitar doble submit;
- una venta confirmada no debe procesarse dos veces.

### E10 — Registrar cortesía

Venta → SaleItem con indicador de cortesía → precio cobrado = 0 → consumo del recurso correspondiente → auditoría.

**Reglas:**
- registrar pero no cobrar;
- no confundir cortesía con producto gratuito del catálogo;
- para bebidas de cortesía se consume desde el recurso preparado configurado.

### E11 — Registrar merma

UI → WasteUseCase → validar cantidad → registrar merma → generar StockMovement negativo → actualizar inventario → auditoría.

**Reglas:**
- no registrar dos veces la misma merma por doble submit;
- motivo obligatorio cuando lo exija el negocio;
- distinguir merma de sobrante reutilizable.

### E12 — Cerrar caja

Ventas/gastos/pagos → cálculo consolidado → arqueo físico → balance → persistencia de CashSession → cerrar estado → almacenar fecha/hora/usuario.

**Reglas:**
- caja no debe cerrarse dos veces;
- balance automático;
- conservar ciclo operativo;
- cierre 00:30 debe pertenecer al ciclo de apertura correspondiente.

### E13 — Reabrir caja excepcionalmente

Caja cerrada → autenticar usuario autorizado → registrar motivo → abrir/reabrir ciclo según regla → registrar fecha/hora → auditoría.

**Reglas:**
- requiere contraseña/autorización válida;
- no almacenar contraseña directamente para comparaciones en Flutter;
- registrar motivo y actor;
- mantener trazabilidad del ciclo previo.

---

## 5. Matriz de efectos por evento

| Evento | Stock | Caja | CxP | PDF | Reportes | Auditoría |
|---|---:|---:|---:|---:|---:|---:|
| Compra insumo | + | -/según pago | sí si crédito | opcional factura/adjunto | sí | sí |
| Compra activo | no insumo | -/según pago | sí si crédito | opcional | sí | sí |
| Pago CxP | no | sí | disminuye | opcional | sí | sí |
| Preparación | - insumos / + disponibilidad preparada | - | - | - | sí | sí |
| Transformación | puede consumir base + adicional | - | - | - | sí | sí |
| Venta normal | disminuye disponibilidad | + | - | sí | sí | sí |
| Venta cortesía | disminuye recurso | +0 | - | sí | sí | sí |
| Merma | - | - | - | - | sí | sí |
| Gasto | - | - | - | - | sí | sí |
| Cierre caja | - | consolidación | - | - | sí | sí |

---

## 6. Matriz de permisos críticos

| Acción | Administrador | Empleado |
|---|---|---|
| Iniciar sesión | Sí | Sí |
| Editar propio perfil | Sí | Sí, dentro de sus campos permitidos |
| Gestionar usuarios | Sí | Según permiso explícito |
| Modificar QR | Sí | No |
| Registrar compra | Según permiso | Según permiso |
| Gestionar proveedores | Según permiso | Según permiso |
| Registrar venta | Sí | Sí |
| Registrar cortesía | Sí | Sí, según reglas |
| Abrir/cerrar caja normal | Según política | Según política |
| Reapertura excepcional | Sí | Solo si el sistema autoriza expresamente |
| Cambiar configuraciones sensibles | Sí | No |
| Ajustes de inventario | Restringido | Restringido |
| Ver reportes | Según permiso | Según permiso |

Los permisos reales configurados por el proyecto prevalecen sobre esta matriz conceptual.

---

## 7. Matriz de regresión

Cuando se modifique un módulo, como mínimo revisar:

| Módulo modificado | Regresión obligatoria |
|---|---|
| Usuarios | login, sesión, permisos, configuración sensible |
| Configuración QR | cobro Yape/Plin, ventas, persistencia de QR |
| Insumos | compras, recetas, preparación, mermas, stock |
| Recetas | preparación, conversiones, stock, sugerencias |
| Preparación | ventas, sobrantes, mermas, sugerencias |
| Transformaciones | preparación, ventas, stock, recetas |
| Ventas | stock, caja, pagos, boleta, historial, reportes |
| Compras | stock, CxP, proveedores, activos, reportes |
| Proveedores | compras, CxP, duplicidad |
| CxP | compras, proveedores, caja, reportes |
| Caja | ventas, pagos, gastos, cierre, dashboard |
| Mermas | stock, preparación, insumos, reportes |
| Reportes | consistencia con todas las fuentes |

---

## 8. Reglas de aceptación transversal

Una funcionalidad se considera completa únicamente si:

1. Funciona en el caso normal.
2. Tiene validaciones.
3. Maneja errores.
4. No genera duplicados.
5. No rompe datos existentes.
6. Respeta permisos.
7. Mantiene trazabilidad.
8. Actualiza todos los efectos secundarios que correspondan.
9. Tiene pruebas de la regla de negocio crítica.
10. Fue revisada por regresión en los módulos dependientes.

---

## 9. Protocolo de diagnóstico de bugs

Cuando se reporte un bug:

### Paso 1 — Identificar el evento

Ejemplo: `RegistrarCompraDeInsumo`.

### Paso 2 — Seguir la cadena completa

UI → estado → caso de uso → dominio → repository → datasource → persistencia → efectos secundarios.

### Paso 3 — Comparar esperado vs real

Documentar:
- resultado esperado;
- resultado actual;
- primer punto donde divergen.

### Paso 4 — Revisar módulos afectados

Consultar esta matriz y los documentos de negocio relacionados.

### Paso 5 — Corregir causa raíz

No aplicar un cambio solamente a la pantalla si el defecto pertenece al dominio o datos.

### Paso 6 — Pruebas

Agregar o actualizar una prueba que reproduzca el bug y pruebas de regresión de sus dependencias.

### Paso 7 — Verificación final

Confirmar que el flujo completo continúa consistente.

---

## 10. Trazabilidad mínima por código

Cuando sea posible, usar identificadores de caso de uso/evento en nombres de pruebas, documentación o commits.

Ejemplo:

```text
E04 Registrar compra de insumo
E09 Registrar venta
E12 Cerrar caja
```

Esto permite conectar:

```text
requisito → regla → caso de uso → implementación → prueba
```

sin depender de comentarios dispersos.
