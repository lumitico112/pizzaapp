import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/auth_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

sig_old = "Future<Usuario> createAdmin(String nombre, String username, String password) async {"
sig_new = "Future<Usuario> createAdmin(String nombre, String username, String password, {String? correo, String? fotoRuta}) async {"
text = text.replace(sig_old, sig_new)

old_admin = """    final admin = Usuario(
      nombre: nombre.trim(),
      username: username.trim(),
      passwordHash: passwordHash,
      rol: 'admin',
    );"""
new_admin = """    final admin = Usuario(
      nombre: nombre.trim(),
      username: username.trim(),
      correo: correo,
      fotoRuta: fotoRuta,
      passwordHash: passwordHash,
      rol: 'admin',
    );"""
text = text.replace(old_admin, new_admin)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
