---
name: flutter-architecture
description: Directivas de arquitectura Clean Architecture, separación en capas, gestión de estado con Provider y desacoplamiento para KIMI PIZZA.
---

# Skill: Arquitectura de Software Flutter (Clean & Modular)

## 1. Misión del Arquitecto
Garantizar que todo componente, pantalla o servicio de KIMI PIZZA se adhiera a Clean Architecture, preservando la separación estricta entre Capa de Presentación, Capa de Dominio y Capa de Datos.

## 2. Invariantes de Capa

### Capa de Presentación (`lib/screens/`, `lib/controllers/`, `lib/core/widgets/`)
- Los Widgets son puramente declarativos. Prohibido colocar lógica de cálculo financiero, transformaciones de stock o SQL directo en `build()`.
- La UI se comunica con el sistema únicamente a través de Controladores (`ChangeNotifier`) inyectados con `Provider`.
- Manejo explícito de los 4 estados de pantalla: `Cargando (Loading)`, `Datos Listos (Success)`, `Vacío (Empty)` y `Error con reintento (Error)`.
- Verificación obligatoria de `if (!mounted) return;` después de cualquier llamada asíncrona (`await`) antes de utilizar el `BuildContext`.

### Capa de Dominio (`lib/services/`, `lib/models/`, `lib/core/utils/`)
- Contiene las reglas puras del negocio: algoritmos de sugerencias, cálculo de Food Cost/COGS, motor de balance de caja y conversiones universales.
- Es completamente independiente de la UI. Los servicios no conocen Widgets ni `BuildContext`.
- Es 100% testeable mediante pruebas unitarias puras (`flutter test`).

### Capa de Datos (`lib/repositories/`, `lib/core/database/`)
- Encapsula el acceso a la base de datos local SQLite con cifrado `SQLCipher`.
- Toda mutación que involucre dos o más tablas (ej. Venta + Detalle + MovimientoCaja + Stock) se ejecuta dentro de un bloque `db.transaction((txn) async { ... })`.
- Mapea de manera segura los registros relacionales a entidades tipadas de Dart (`fromMap` / `toMap`).

## 3. Protocolo de Inspección Previa
Antes de introducir una nueva clase o modificar una existente:
1. Inspecciona el árbol de carpetas para identificar si ya existe un repositorio o servicio equivalente.
2. Identifica si el cambio afecta la consistencia de inventario o finanzas.
3. Respeta los contratos abstractos existentes antes de cambiar firmas públicas.
