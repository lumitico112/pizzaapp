# Arquitectura de KIMI PIZZA

## Objetivo

Diseñar una aplicación Flutter modular y evolutiva. La estructura concreta debe respetar la arquitectura actual cuando esta sea válida, pero debe conducir a una separación clara de responsabilidades.

## Capas

### Presentation
Responsable de:
- widgets;
- pantallas;
- navegación;
- estado de UI;
- validaciones de presentación simples;
- eventos del usuario.

No contiene reglas de negocio complejas.

### Domain
Responsable de:
- entidades;
- value objects cuando aporten valor;
- contratos de repositorio;
- casos de uso;
- reglas de inventario;
- conversiones;
- reglas de preparación;
- transformaciones;
- sugerencias;
- reglas de caja;
- validaciones de dominio.

Debe ser la capa más fácil de probar sin Flutter UI.

### Data
Responsable de:
- implementaciones de repositorios;
- API;
- almacenamiento local;
- mappers;
- DTOs;
- persistencia;
- manejo de errores de infraestructura.

## Core

Debe contener infraestructura transversal:
- errores/excepciones;
- red;
- almacenamiento seguro;
- configuración;
- tema;
- rutas;
- utilidades realmente compartidas;
- widgets compartidos.

No usar `core` como depósito de todo.

## Dependencias

Regla conceptual:

presentation -> domain

data -> domain

El dominio no debe depender de Flutter UI, HTTP concreto ni base de datos concreta.

## Estado

Usar un único patrón principal de estado en todo el proyecto. La elección debe respetar la tecnología ya adoptada; no introducir otra librería solo para una pantalla.

## Inyección de dependencias

Centralizar creación de implementaciones. Las dependencias no deben ser instanciadas indiscriminadamente dentro de widgets.

## Reutilización

Crear componentes compartidos únicamente cuando haya una responsabilidad común real. Evitar abstracciones genéricas excesivas.

## Organización por feature

Las funcionalidades de negocio deben permanecer agrupadas por feature para facilitar mantenimiento:
- usuarios;
- configuración;
- activos;
- insumos;
- proveedores;
- compras;
- productos;
- ventas;
- preparación;
- sugerencias;
- caja;
- reportes;
- mermas.

## Regla de refactor

Un refactor debe reducir complejidad o duplicidad. No cambiar arquitectura por estética.
