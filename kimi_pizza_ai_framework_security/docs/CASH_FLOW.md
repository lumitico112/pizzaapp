# KIMI PIZZA — Reglas críticas de Caja y Cierre

## 1. Concepto

KIMI PIZZA trabaja con **sesiones operativas de caja**. La fecha calendario y la fecha operativa del ciclo no deben confundirse.

`CashSession` es la fuente de verdad del ciclo de caja.

## 2. Estados

Una sesión debe poder distinguir al menos:
- `open`;
- `closed`;
- `exceptionally_reopened` cuando el diseño lo requiera.

No permitir ventas normales si no existe una sesión válida y abierta.

## 3. Apertura

Al abrir caja registrar:
- identificador de sesión;
- fecha/hora real de apertura;
- usuario responsable;
- monto inicial, si el sistema lo maneja;
- ciclo operativo correspondiente.

## 4. Cierre después de medianoche

Si la caja se abre el 01/10/2026 y se cierra el 02/10/2026 a las 00:30, el cierre corresponde al ciclo operativo iniciado el 01/10/2026.

No utilizar simplemente `DateTime.now().day` para decidir la sesión.

## 5. Resumen del cierre

Debe mostrar:
- ventas Yape/Plin;
- ventas en efectivo;
- gastos;
- efectivo esperado;
- efectivo real arqueado;
- transferencias Yape/Plin;
- balance;
- balance total/diferencia;
- notas.

## 6. Cálculos

La fórmula concreta depende del modelo financiero implementado, pero los importes deben provenir de movimientos persistidos y de la sesión actual.

Conceptualmente:

`Efectivo esperado = efectivo inicial + ventas efectivo - gastos efectivo +/- ajustes autorizados`.

`Transferencias = suma de ventas confirmadas por Yape/Plin de la sesión`.

`Balance = efectivo real + transferencias`.

`Diferencia = Balance - referencia esperada`, usando exactamente la definición financiera adoptada por el sistema.

No duplicar estas fórmulas en varias pantallas.

## 7. Colores del balance

- diferencia = 0 -> verde;
- diferencia menor a lo esperado -> rojo;
- diferencia mayor a lo esperado -> naranja.

Los colores provienen del sistema de diseño, no de literales dispersos.

## 8. Cerrar caja

Al cerrar:
1. impedir nuevos cobros normales;
2. consolidar ventas y gastos de la sesión;
3. guardar arqueo;
4. calcular y persistir resumen;
5. registrar fecha/hora de cierre;
6. registrar usuario;
7. registrar observaciones;
8. marcar sesión como cerrada;
9. mostrar el balance del día/ciclo.

El cierre debe ser idempotente: presionar dos veces no debe crear dos cierres.

## 9. Reapertura excepcional

Una caja cerrada puede abrirse únicamente mediante autorización del rol permitido por negocio.

La contraseña nunca se almacena ni compara localmente como texto plano.

Debe registrarse:
- usuario que autoriza;
- fecha/hora;
- motivo;
- sesión/ciclo reabierto.

## 10. Operación posterior al cierre

Una venta excepcional después de un cierre debe quedar ligada al ciclo reabierto y auditada.

No crear silenciosamente una nueva caja independiente para la misma fecha operativa salvo que el negocio lo defina explícitamente.

## 11. Sesión de usuario

Cerrar caja no debe confundirse con cerrar sesión de la cuenta: el comportamiento requerido por el negocio es que la aplicación permanezca autenticada hasta que el usuario cierre sesión o hasta el evento definido en los requisitos de cierre.

La implementación concreta debe respetar la regla de `USERS_CONFIGURATION.md`.

## 12. Criterios de aceptación

- ventas en efectivo alimentan caja automáticamente;
- Yape/Plin alimenta transferencias automáticamente;
- gastos afectan el efectivo según su método y regla;
- el arqueo real se compara con la referencia;
- cero = verde, menor = rojo, mayor = naranja;
- cierre a las 00:30 conserva el ciclo iniciado el día anterior;
- reapertura requiere autorización;
- apertura/cierre registran fecha y hora;
- doble cierre no duplica datos.
