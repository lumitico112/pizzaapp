# KIMI PIZZA — Plan de implementación por fases

> **Nota de vigencia (18/10/2026):** este roadmap es referencia de diseño por módulos (08/10/2026). La ejecución real del proyecto se rigió por el plan de auditoría `C-01`…`C-31` / `H-01`…`H-13` (fases `F0`–`F15`), **cerrado y verificado** (suite 75/75; `flutter analyze` 0 issues): ver `kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md` §4 y `agent.md` en la raíz. La iniciativa activa sugerida es el endurecimiento de seguridad de esta edición (ver `docs/SECURITY_CONTROL_MATRIX.md` y `docs/SECURITY_TEST_PLAN.md`). La ejecución de ese endurecimiento se organiza en `docs/SECURITY_ACTION_PLAN.md` (fases `FS-0`–`FS-9`), con prompts listos por fase en `docs/SECURITY_PHASE_PROMPTS.md`.

## Objetivo

Implementar y estabilizar la aplicación Flutter sobre el código existente, priorizando primero las reglas de dominio y los flujos que afectan múltiples módulos. El objetivo no es rehacer la aplicación completa, sino corregir la arquitectura y avanzar de forma incremental, verificable y reversible.

## Principio de ejecución

No implementar todas las funcionalidades a la vez.

Cada fase debe cerrar con:

1. análisis del código existente;
2. cambios mínimos y estructurados;
3. pruebas de la regla modificada;
4. pruebas de regresión de módulos relacionados;
5. revisión de duplicidad y arquitectura;
6. validación visual cuando corresponda;
7. actualización de documentación si cambia una regla de negocio.

---

# FASE 0 — Auditoría técnica y mapa real del proyecto

### Objetivo
Conocer la implementación real antes de modificarla.

### Revisar

- estructura de `lib/`;
- `pubspec.yaml` y dependencias;
- arquitectura actual;
- gestión de estado;
- navegación;
- inyección de dependencias;
- modelos, DTOs, entidades y mappers;
- repositorios y datasources;
- persistencia local;
- API/backend;
- autenticación y autorización;
- tema y componentes reutilizables;
- manejo de imágenes;
- PDFs;
- fechas y moneda;
- manejo de errores;
- tests existentes.

### Entregables

- mapa de módulos reales;
- mapa de dependencias;
- lista de duplicidades;
- lista de clases/archivos críticos;
- lista de bugs conocidos;
- diferencias entre documentación y código real.

### Criterio de salida
No comenzar refactorizaciones grandes hasta tener identificado qué código existente puede reutilizarse.

---

# FASE 1 — Fundaciones compartidas y arquitectura

### Objetivo
Establecer las piezas que todos los módulos compartirán.

### Implementar o consolidar

- DI;
- navegación/routing;
- manejo de estados;
- errores/exceptions/failures;
- validadores;
- fechas;
- moneda y cantidades;
- almacenamiento seguro;
- cliente HTTP y configuración de entornos;
- image picker/camera;
- PDF viewer/generator;
- dialogs, loading, empty/error states;
- design system;
- componentes comunes.

### Regla
No crear una abstracción por adelantado si el proyecto ya tiene una equivalente funcional.

### Pruebas

- validadores;
- conversión de unidades;
- cálculos monetarios;
- manejo de errores;
- persistencia de sesión;
- componentes críticos compartidos.

---

# FASE 2 — Usuarios, autenticación y configuración

### Objetivo
Dejar estable el control de acceso y la configuración global antes de exponer funciones sensibles.

### Implementar

- autenticación;
- restauración de sesión;
- roles/permisos;
- perfil propio;
- edición administrativa del perfil cuando corresponda;
- configuración global;
- configuración del QR de ventas;
- selección/reemplazo de QR;
- acceso del QR desde Ventas;
- auditoría de cambios administrativos.

### Reglas críticas

- Flutter no valida contraseñas comparándolas localmente como mecanismo de seguridad.
- Los permisos sensibles deben validarse también en backend cuando exista backend.
- El QR se configura una vez y se reutiliza en pagos Yape/Plin.

### Criterio de salida
Un usuario puede iniciar sesión, mantener sesión, cerrar sesión y acceder solamente a las funciones permitidas por su rol.

---

# FASE 3 — Catálogos, productos, variantes y recetas

### Objetivo
Crear la base de catálogo que consumen preparación, ventas y sugerencias.

### Implementar/consolidar

- categorías de productos;
- categorías predefinidas e idempotentes;
- productos;
- variantes;
- receta;
- prevención de insumos duplicados en receta;
- promociones;
- unidad de medida en receta;
- conversiones kg/g, L/ml y paquetes/unidades.

### Regla crítica
El producto y su receta deben ser fuentes claras de la lógica de consumo; la UI nunca debe contener las fórmulas de negocio.

### Criterio de salida
Se puede crear un producto, asociar receta y variantes sin duplicidad y calcular correctamente el consumo esperado de insumos.

---

# FASE 4 — Insumos e inventario

### Objetivo
Construir una única fuente confiable para el stock.

### Implementar/consolidar

- insumos;
- categorías predefinidas;
- unidades de medida;
- contenido de paquetes;
- stock;
- stock mínimo/configurable;
- movimientos de inventario;
- entradas por compra;
- salidas por consumo;
- ajustes;
- estado visual del stock.

### Regla crítica
Todo cambio de stock debe poder explicarse mediante un movimiento o evento de negocio.

### Prohibiciones

- modificar stock en la UI sin pasar por la lógica de dominio;
- mantener varias fuentes independientes de stock;
- descontar dos veces por el mismo evento.

### Criterio de salida
Una compra aumenta stock y cada salida válida lo disminuye exactamente una vez.

---

# FASE 5 — Compras, proveedores y cuentas por pagar

### Objetivo
Garantizar que las entradas de inventario y obligaciones financieras queden registradas de manera consistente.

### Implementar/consolidar

- nueva compra;
- compra de insumos;
- compra de activos;
- proveedor;
- unicidad de proveedor;
- proveedor desde compra;
- lectura de factura si existe;
- fotografía/imagen;
- fecha de compra;
- costo total;
- costo unitario;
- contado/crédito;
- adelanto;
- saldo pendiente;
- cuentas por pagar.

### Regla crítica
No mantener un flujo independiente de “gasto/egreso” dentro de Nueva Compra si el modelo definitivo es compra unificada.

### Criterio de salida
Una compra crea correctamente sus efectos en inventario y/o activos y, cuando corresponda, en cuentas por pagar.

---

# FASE 6 — Activos fijos

### Objetivo
Registrar y administrar activos sin duplicarlos con compras ni inventario de insumos.

### Implementar/consolidar

- foto;
- categoría;
- cantidad;
- comprado;
- contado/crédito;
- alquilado;
- tipo de alquiler;
- prestado;
- regalado;
- valor unitario cuando aplique;
- estado;
- fecha;
- observaciones;
- lista con adquisición, fecha, costo y estado;
- indicadores visuales de estado.

### Criterio de salida
Un activo comprado puede ser trazado desde la compra hasta el registro del activo sin crear registros duplicados.

---

# FASE 7 — Preparación y disponibilidad

### Objetivo
Convertir las recetas y el stock de insumos en disponibilidad operativa para venta.

### Implementar/consolidar

- lista diaria de preparación;
- cantidades positivas;
- cantidades negativas;
- notas por producto;
- nota general;
- sobrantes;
- pasar a mañana;
- merma de preparados;
- consumo de insumos por preparación;
- disponibilidad vendible.

### Regla crítica
Preparación representa producto físico/operativo disponible para vender. La venta no debe volver a descontar de la receta los mismos insumos consumidos en la preparación.

---

# FASE 8 — Transformaciones de producto

### Objetivo
Permitir que un producto preparado pueda transformarse en otro sin falsificar el stock.

### Caso base

```text
Americana preparada
        ↓ transformación
Hawaiana
        + consumo de piña
```

### Reglas

- no crear unidades ficticias;
- descontar la cantidad transformada de la base disponible;
- agregar la variante/producto transformado únicamente como resultado operativo;
- consumir ingredientes adicionales;
- permitir futuras transformaciones sin hardcodear Americana → Hawaiana.

### Criterio de salida
Una transformación cambia la disponibilidad real y deja trazabilidad del origen y de los insumos adicionales consumidos.

---

# FASE 9 — Ventas, promociones y cortesías

### Objetivo
Construir el flujo de venta sobre la disponibilidad preparada.

### Implementar/consolidar

- categorías;
- promociones;
- modal de selección;
- precio editable solo para la venta actual;
- carrito;
- cantidades;
- subtotales;
- cortesías;
- bebidas de cortesía;
- validación de disponibilidad;
- historial;
- registro de ventas anteriores;
- precio histórico editable.

### Regla crítica
Cambiar el precio durante una venta nunca debe cambiar el precio maestro del producto.

### Criterio de salida
La venta registrada descuenta disponibilidad una sola vez, refleja correctamente promociones/cortesías y conserva el precio realmente cobrado.

---

# FASE 10 — Pagos y boleta PDF

### Objetivo
Cerrar una venta de forma idempotente y auditable.

### Implementar/consolidar

- efectivo;
- monto recibido opcional;
- vuelto cuando exista monto recibido;
- Yape/Plin;
- QR configurado;
- ampliación del QR;
- confirmación de pago;
- generación de PDF;
- almacenamiento del PDF;
- visualización posterior;
- descarga.

### Regla crítica
El proceso de cobrar debe ser idempotente. Un doble toque o reintento no debe crear dos ventas.

---

# FASE 11 — Caja y cierres

### Objetivo
Alinear ventas y pagos con el ciclo operativo de caja.

### Implementar/consolidar

- apertura;
- cierre;
- fecha/hora;
- efectivo;
- Yape/Plin;
- gastos;
- efectivo esperado;
- arqueo;
- balance;
- diferencia;
- notas;
- apertura excepcional;
- autorización administrativa;
- ciclo operativo después de medianoche.

### Regla crítica
La fecha de cierre no debe confundirse con la fecha del ciclo de caja.

### Criterio de salida
Toda venta pertenece a una sesión/ciclo de caja válido y los totales de caja son reproducibles desde las transacciones.

---

# FASE 12 — Mermas y ajustes

### Objetivo
Unificar las mermas en una única lógica de dominio.

### Implementar/consolidar

- merma de insumos;
- merma de productos preparados;
- cantidad;
- motivo;
- observación;
- fecha;
- impacto en stock;
- historial;
- acceso desde módulos de origen.

### Regla crítica
“Merma” y “sobrante para mañana” son estados distintos y nunca deben tratarse como la misma operación.

---

# FASE 13 — Sugerencias y analítica operativa

### Objetivo
Construir sugerencias a partir de datos reales y por día de la semana.

### Entradas

- ventas;
- faltantes;
- negativos de preparación;
- sobrantes;
- comportamiento histórico del mismo día de la semana.

### Implementar

- algoritmo centralizado;
- parámetros configurables cuando sea necesario;
- trazabilidad de por qué se recomienda una cantidad.

### Criterio de salida
El algoritmo es testeable y no depende de fórmulas incrustadas en widgets.

---

# FASE 14 — Reportes y dashboard

### Objetivo
Mostrar información derivada de las mismas fuentes de verdad.

### Implementar/consolidar

- fecha;
- hora;
- ventas;
- gastos;
- ganancias;
- reportes;
- filtros temporales;
- consistencia entre reportes y transacciones.

### Regla crítica
Un reporte no debe inventar una fórmula diferente a la utilizada por el módulo transaccional.

---

# FASE 15 — Endurecimiento, pruebas de regresión y limpieza

### Objetivo
Cerrar deuda técnica antes de seguir agregando funcionalidades.

### Revisar

- duplicidad;
- clases gigantes;
- dependencias innecesarias;
- código muerto;
- imports innecesarios;
- recursos sin liberar;
- validaciones faltantes;
- permisos;
- logs sensibles;
- pruebas faltantes;
- errores de UX;
- rendimiento.

### Resultado
Una versión candidata estable y documentada.

---

# Orden de prioridad para arreglar bugs actuales

Cuando existan muchos bugs, priorizar en este orden:

1. **Integridad de datos e inventario.**
2. **Ventas y doble descuento.**
3. **Compras y entrada de stock.**
4. **Caja y pagos.**
5. **Preparación y transformaciones.**
6. **Cuentas por pagar.**
7. **Usuarios/seguridad.**
8. **UI y experiencia visual.**
9. **Reportes y mejoras secundarias.**

Un bug de UI no debe ocultar un problema de dominio más profundo.

---

# Estrategia para cada bug

Antes de cambiar código, crear mentalmente o documentar:

```text
BUG
 ↓
REPRODUCCIÓN
 ↓
CAUSA RAÍZ
 ↓
MÓDULOS AFECTADOS
 ↓
REGLA DE NEGOCIO
 ↓
CAMBIO
 ↓
PRUEBA DIRECTA
 ↓
PRUEBAS DE REGRESIÓN
```

Nunca corregir únicamente el síntoma si existe una causa de dominio o arquitectura.

---

# Regla para integrar cambios entre fases

Cuando una fase modifique una entidad usada por otra fase:

1. identificar consumidores;
2. actualizar interfaces, mappers y repositorios afectados;
3. ejecutar pruebas del productor;
4. ejecutar pruebas de consumidores;
5. actualizar la matriz de trazabilidad;
6. actualizar documentación de reglas si cambia el comportamiento.

---

# Definition of Done del proyecto

La aplicación no se considera terminada solo porque compile.

Debe cumplirse:

- arquitectura consistente;
- reglas críticas implementadas;
- tests de dominio críticos;
- pruebas de integración de flujos principales;
- no doble descuento de stock;
- no duplicidad de entidades;
- permisos funcionando;
- pagos y caja reconciliables;
- PDFs persistidos;
- errores manejados;
- documentación actualizada;
- regresiones revisadas.
