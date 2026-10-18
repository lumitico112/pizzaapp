---
name: flutter-debugging
description: Protocolo metódico de diagnóstico de errores en Flutter, análisis de causa raíz, resolución de RenderFlex Overflows y excepciones de compilación.
---

# Skill: Diagnóstico de Errores y Depuración Flutter

## 1. Protocolo de Diagnóstico de Causa Raíz
1. **Inspección de Logs:**
   - Leer el StackTrace completo antes de realizar cambios.
   - Identificar si el fallo es de tipo:
     - `Compilation Error`: Sintaxis, tipos incompatibles o directivas mal ubicadas.
     - `RenderFlex Overflow`: Desbordes visuales en UI por falta de `Flexible`, `Expanded` o `SingleChildScrollView`.
     - `Async Gap Issue`: Uso de `BuildContext` tras `await` sin verificar `if (!mounted) return;`.
     - `Database Constraint`: Violación de llaves foráneas o `CHECK constraints` en SQLite.
2. **Aislamiento del Problema:**
   - Reproducir el error con el flujo mínimo necesario.
   - Verificar si el problema reside en la capa de Presentación, Controlador, Servicio o Repositorio.
3. **Cero Parches Superficiales:**
   - No ocultar excepciones con bloques `catch (_) {}` vacíos.
   - Resolver la causa de raíz en el modelo o en la lógica de dominio.
