# KIMI PIZZA — Compras, Proveedores, Cuentas por Pagar, Activos Fijos, Mermas y Reportes

## 1. Objetivo

Formalizar las reglas de negocio de las áreas que completan el ciclo de entrada de recursos, obligaciones de pago, activos, pérdidas y explotación de información.

Principios:
- una sola fuente de verdad por entidad;
- trazabilidad de movimientos;
- idempotencia en operaciones sensibles;
- no duplicidad;
- integración con inventario y caja;
- separación de compra de insumos y compra de activos dentro de un flujo único de compras;
- separación entre obligación pendiente y pago realizado;
- una misma lógica de merma aunque se origine desde diferentes módulos;
- reportes derivados de las mismas fuentes transaccionales del sistema.

---

## 2. Compra como operación de entrada

Una compra representa una adquisición real registrada en el sistema.

Tipos principales:
- compra de insumos;
- compra de activos fijos.

No debe existir un flujo paralelo de “Gasto/Egreso” dentro del formulario de nueva compra. Esa opción se elimina del flujo de compras.

El hecho de que una compra tenga impacto financiero no la convierte en un “egreso” separado. La compra mantiene su propia entidad y trazabilidad.

---

## 3. Nueva compra

Flujo:

Nueva compra
→ seleccionar tipo de compra
→ seleccionar/crear entidad correspondiente
→ cantidad
→ costos
→ proveedor
→ forma de pago / cuenta por pagar
→ evidencia documental
→ fecha
→ guardar
→ generar movimientos derivados

La UI no debe ejecutar directamente todos estos pasos. La coordinación debe pertenecer al dominio/caso de uso correspondiente.

---

## 4. Compra de insumos

Debe permitir como mínimo:
- insumo;
- cantidad;
- unidad contextual;
- costo total;
- costo por unidad;
- proveedor;
- cuenta por pagar sí/no;
- adelanto opcional;
- nota/motivo;
- foto;
- imagen/documento;
- fecha de compra.

### Regla de costo unitario

Si el costo unitario es derivable:

costo unitario = costo total / cantidad

Debe existir una única implementación del cálculo.

No duplicar el cálculo en formulario, repositorio y reporte.

---

## 5. Compra de activos fijos

La compra de un activo debe poder registrarse desde el sistema de compras y quedar vinculada al activo creado.

Una compra de activo debe poder alimentar:
- registro del activo;
- historial de adquisición;
- costo de adquisición;
- proveedor cuando exista;
- condición de pago;
- cuenta por pagar cuando corresponda;
- reportes.

No crear una segunda compra independiente para representar el mismo activo.

### Integración crítica

Cuando un activo se registra como comprado, el sistema debe garantizar la relación:

Compra de activo ↔ Activo fijo

La existencia del activo en activos fijos no implica automáticamente que deba aparecer como una compra distinta creada por duplicado. Debe existir una referencia común o mecanismo de vinculación equivalente.

---

## 6. Cuenta por pagar

Una cuenta por pagar representa una obligación económica pendiente derivada de una compra.

Debe separar conceptualmente:
- monto total de la compra;
- adelanto pagado;
- saldo pendiente;
- estado de la obligación;
- pagos posteriores.

### Fórmula base

saldo pendiente = total compra - suma de pagos aplicados

El adelanto inicial es el primer pago aplicado, no una modificación del costo de compra.

### Estados

Como mínimo, el dominio debe poder distinguir:
- pendiente;
- parcialmente pagada;
- pagada;
- anulada, si el backend/proyecto contempla anulaciones.

No usar un simple booleano como única representación si eso impide expresar estados intermedios.

---

## 7. Cuenta por pagar y proveedor

La compra debe poder referenciar un proveedor existente.

El proveedor no debe pertenecer exclusivamente al caso “por pagar”. Una compra pagada también puede tener proveedor.

El botón para agregar proveedor debe llevar al formulario de proveedores y permitir regresar al contexto de la compra.

No crear un proveedor temporal embebido dentro de Purchase.

---

## 8. Proveedores

Operaciones:
- listar;
- agregar;
- editar;
- eliminar/desactivar según las reglas del sistema.

### No duplicidad

Antes de crear:
- validar identidad empresarial o clave única disponible;
- validar datos obligatorios;
- comprobar existencia en fuente de verdad.

Si ya existe, mostrar mensaje de negocio apropiado, por ejemplo:

“El proveedor ya existe.”

La protección contra duplicados no debe depender solamente de la UI. Cuando exista backend/base de datos, debe existir una restricción o validación equivalente del lado servidor.

### Eliminación

No eliminar físicamente un proveedor si eso rompe el historial de compras o cuentas por pagar. Preferir desactivación cuando la arquitectura lo permita.

Las compras históricas deben continuar mostrando el proveedor asociado.

---

## 9. Evidencia de compra

El formulario puede manejar:
- fotografía;
- imagen/documento;
- lectura de factura cuando exista.

La evidencia debe quedar asociada al registro correcto de compra.

No almacenar la misma evidencia varias veces por accidente.

Si la lectura automática de factura falla, debe permitirse continuar con carga/manual según el flujo existente, sin perder datos previamente introducidos.

---

## 10. Fechas de compra

Por defecto:
- fecha = fecha actual del dispositivo/servidor según política del sistema.

Debe poder seleccionarse una fecha anterior mediante el selector común de fechas.

No permitir silenciosamente una fecha futura si el negocio no la contempla.

Conservar:
- fecha de registro técnico;
- fecha operativa/de compra cuando sean distintas.

---

## 11. Idempotencia de compras

Una misma acción de guardado no debe crear dos compras por doble toque, reintento o repetición accidental.

La operación de persistencia debe tener estrategia de idempotencia/transacción de acuerdo con la arquitectura del backend.

Ejemplo de fallo que debe evitarse:

Usuario pulsa Guardar Compra dos veces
→ dos Purchase creadas
→ stock aumentado dos veces
→ cuenta por pagar duplicada.

---

## 12. Movimiento de inventario por compra

Una compra de insumo debe producir el movimiento de entrada correspondiente.

Conceptualmente:

Purchase
→ PurchaseItem
→ StockMovement(IN)
→ stock actualizado

El stock NO debe incrementarse una vez en UI y otra vez en repositorio.

Debe existir una única fuente de verdad para aplicar el movimiento.

### Reversión/corrección

Si una compra puede anularse o corregirse, el sistema debe registrar un movimiento compensatorio en lugar de editar el stock manualmente sin trazabilidad.

Las correcciones de una compra conservan el registro original y guardan los
valores anteriores/nuevos en `CorreccionesCompra`. Si cambia la cantidad, el
inventario recibe solo la diferencia como movimiento compensatorio. La corrección
actualiza el gasto o la obligación vinculada dentro de la misma transacción; no
se permite modificar desde el formulario una compra ligada a una caja cerrada.

---

## 13. Activos fijos

Campos de dominio relevantes:
- identificación;
- nombre;
- categoría;
- cantidad;
- condición/adquisición;
- costo;
- forma de pago;
- cuotas si aplica;
- adelanto si aplica;
- tipo de alquiler si aplica;
- valor unitario cuando corresponda;
- estado;
- fecha;
- observaciones;
- fotografía.

### Estados

Como mínimo:
- nuevo;
- bueno;
- regular;
- malo;
- en reparación;
- fuera de servicio;
- en uso.

La presentación de estados debe usar los tokens globales de color, no colores hardcodeados.

---

## 14. Activo comprado a crédito

Si condición/adquisición = comprado y forma de pago = crédito:
- registrar cuotas;
- registrar adelanto si existe;
- generar o vincular cuenta por pagar;
- conservar costo total del activo.

La deuda no debe alterar el valor de adquisición del activo.

---

## 15. Activo alquilado

Si condición = alquilado:
- costo del alquiler;
- periodicidad: diario, semanal, mensual o anual.

No tratar un activo alquilado como un activo comprado simplemente porque exista un precio.

---

## 16. Activo prestado/regalado

Si condición = prestado o regalado:
- no inventar costo de adquisición si realmente no existe;
- mantener los datos necesarios para trazabilidad;
- permitir valor unitario cuando corresponda a cantidades múltiples según las reglas de negocio.

---

## 17. Activos y compras

Debe poder contestarse de forma consistente:

- ¿de qué compra proviene este activo?
- ¿cuándo se adquirió?
- ¿cuánto costó?
- ¿cómo se pagó?
- ¿existe deuda pendiente?

No duplicar datos sin una razón de dominio clara.

---

## 18. Mermas

Una merma representa una pérdida o baja de recurso.

Puede originarse desde:
- módulo de mermas;
- insumos;
- preparación;
- otros orígenes habilitados.

Todos deben utilizar la misma operación de dominio de merma.

---

## 19. Datos mínimos de una merma

- entidad afectada;
- tipo/origen;
- cantidad;
- unidad;
- fecha;
- motivo;
- observación;
- usuario responsable;
- referencia al movimiento de inventario.

Si existe costo valorizado, debe conservarse de acuerdo con la política de valoración del proyecto.

---

## 20. Merma de insumos

Al registrar merma de un insumo:

Insumo
→ validar stock disponible
→ registrar Waste
→ registrar StockMovement(OUT/WASTE)
→ recalcular stock

No permitir que la misma merma se descuente dos veces.

---

## 21. Merma de preparación

Una preparación sobrante que ya no puede venderse puede convertirse en merma.

Ejemplo:

Preparado = 10
Vendido = 7
Sobrante = 3

Si 3 pasan a merma:

Disponibilidad = 0
Merma = 3

El historial debe conservar el origen.

---

## 22. Sobras y merma no son lo mismo

Sobrante:
- todavía utilizable;
- puede continuar al día siguiente según reglas.

Merma:
- deja de formar parte de la disponibilidad utilizable.

No convertir automáticamente todo sobrante en merma.

---

## 23. Reportes

Los reportes deben consumir datos transaccionales ya registrados.

No deben crear una segunda contabilidad interna.

Fuentes principales:
- ventas;
- compras;
- cuentas por pagar;
- stock/movimientos;
- mermas;
- caja;
- activos.

### Regla

La misma operación que actualiza el dominio debe alimentar los reportes mediante consultas/proyecciones apropiadas.

Evitar que el reporte tenga fórmulas diferentes a las del dominio.

---

## 24. Reporte de compras

Debe poder analizar:
- periodo;
- cantidad de compras;
- monto total;
- compras de insumos;
- compras de activos;
- compras con deuda;
- compras pagadas;
- proveedores.

---

## 25. Reporte de inventario

Debe poder relacionar:
- stock actual;
- entradas por compra;
- salidas por preparación;
- salidas por venta;
- cortesías;
- mermas;
- ajustes.

Los totales deben derivarse del mismo historial de movimientos.

---

## 26. Reporte de mermas

Debe poder filtrar por:
- fecha/periodo;
- insumo;
- producto preparado;
- motivo;
- usuario;
- cantidad.

---

## 27. Reporte de cuentas por pagar

Debe mostrar:
- proveedor;
- compra relacionada;
- monto original;
- adelantos/pagos;
- saldo;
- estado;
- fechas.

No calcular saldo de una forma distinta a la lógica de cuentas por pagar.

---

## 28. Reporte de activos

Debe mostrar al menos:
- activo;
- categoría;
- cantidad;
- adquisición;
- fecha;
- costo;
- estado.

Debe poder identificar si existe deuda relacionada cuando corresponda.

---

## 29. Consistencia entre módulos

### Compra de insumo

Compra
→ stock aumenta
→ reporte de compras cambia
→ cuentas por pagar cambia si aplica
→ reportes de inventario cambian

### Compra de activo

Compra
→ activo relacionado
→ historial de adquisición
→ cuenta por pagar si aplica
→ reportes de activos/compras

### Merma

Merma
→ stock disminuye
→ reporte de mermas cambia
→ inventario cambia
→ preparación/venta disponible cambia si la merma proviene de preparación

---

## 30. Anulaciones

No borrar transacciones históricas para “corregir” errores sin dejar trazabilidad.

Preferir:
- reversión;
- anulación;
- movimiento compensatorio;
- auditoría.

Los nombres concretos deben adaptarse al backend existente.

---

## 31. Auditoría

Registrar en operaciones sensibles:
- usuario;
- fecha/hora;
- acción;
- entidad;
- identificador;
- valores relevantes antes/después cuando aplique;
- motivo en correcciones.

Especialmente:
- compras;
- cambios de proveedor;
- cuentas por pagar;
- mermas;
- ajustes de activos;
- anulaciones.

---

## 32. Transacciones y consistencia

Cuando una operación produzca múltiples efectos, se debe preferir una transacción de backend o mecanismo equivalente.

Ejemplo de compra de insumo a crédito:

Purchase
+ PurchaseItem
+ StockMovement
+ Payable
+ audit/reference

No debe quedar una compra creada sin stock ni deuda cuando todas forman parte de una única operación de negocio.

---

## 33. Reglas de UI derivadas del dominio

La UI debe reflejar el estado real y no inferir datos críticos de forma independiente.

Ejemplos:
- “Por pagar” se basa en el estado de la obligación.
- “Pagada” se basa en saldo pendiente.
- color de stock se basa en regla central de disponibilidad.
- estado del activo se basa en su estado de dominio.
- merma se muestra según registros existentes.

---

## 34. Errores que deben evitarse

- crear una compra y sumar stock dos veces;
- crear una compra y una cuenta por pagar desconectadas;
- registrar un proveedor duplicado;
- borrar un proveedor que rompería compras históricas;
- modificar el stock directamente para corregir una compra;
- registrar la misma merma dos veces;
- crear activos duplicados desde compras y activos;
- generar reportes con fórmulas diferentes al dominio;
- hacer que los reportes modifiquen datos operativos;
- perder la fecha original al editar una transacción histórica.

---

## 35. Criterios de aceptación

Una implementación se considera correcta solo si:

1. La compra aparece en el listado.
2. El stock se actualiza exactamente una vez cuando la compra corresponde a insumos.
3. El activo queda relacionado con su adquisición cuando corresponde.
4. Las cuentas por pagar reflejan correctamente total, adelanto y saldo.
5. Los proveedores no se duplican.
6. Las mermas se registran y descuentan exactamente una vez.
7. Los reportes coinciden con los módulos transaccionales.
8. Las fechas son correctas.
9. Los documentos/evidencias quedan relacionados con la entidad correcta.
10. Las operaciones no se duplican por doble toque o reintento.
11. La autorización se respeta.
12. Las pruebas de regresión no muestran inconsistencias.
