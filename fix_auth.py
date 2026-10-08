import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/auth_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re

# Find the createAdmin method and replace it
old_method_pattern = r"Future<Usuario> createAdmin\(String nombre, String username, String password\) async \{.*?\s*return admin;\n\s*\}"
new_method = """Future<Usuario> createAdmin(String nombre, String username, String password, {String? correo, String? fotoRuta}) async {
    if (nombre.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
      throw Exception('Todos los campos son obligatorios.');
    }
    
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    final adminExists = await _repository.adminExists();
    if (adminExists) {
      throw Exception('Ya existe un administrador registrado en el sistema.');
    }

    final passwordHash = HashUtils.hashPassword(password);
    final admin = Usuario(
      nombre: nombre.trim(),
      username: username.trim(),
      correo: correo?.trim(),
      fotoRuta: fotoRuta,
      passwordHash: passwordHash,
      rol: 'admin',
    );

    await _repository.insertUser(admin);
    return admin;
  }"""

text = re.sub(old_method_pattern, new_method, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
