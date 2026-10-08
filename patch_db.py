import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/core/database/database_helper.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update auto-patch
patch_old = "    try { await database.execute('ALTER TABLE CuentasPorPagar ADD COLUMN monto_pagado REAL DEFAULT 0'); } catch (_) {}"
patch_new = patch_old + """
    try { await database.execute('ALTER TABLE Usuarios ADD COLUMN correo TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE Usuarios ADD COLUMN bloqueado INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE Usuarios ADD COLUMN recovery_code TEXT'); } catch (_) {}"""
text = text.replace(patch_old, patch_new)

# 2. Update CREATE TABLE
create_old = """      CREATE TABLE Usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL CHECK(rol IN ('admin','empleado')),
        foto_ruta TEXT,
        activo INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now'))
      )"""
create_new = """      CREATE TABLE Usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        correo TEXT,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL CHECK(rol IN ('admin','empleado')),
        foto_ruta TEXT,
        activo INTEGER DEFAULT 1,
        bloqueado INTEGER DEFAULT 0,
        recovery_code TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )"""
text = text.replace(create_old, create_new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
