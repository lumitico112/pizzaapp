import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/repositories/usuario_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_auth = """  Future<Usuario?> authenticate(String username, String password) async {
    final db = await dbHelper.database;
    final hash = HashUtils.hashPassword(password);

    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'username = ? AND password_hash = ? AND activo = 1',
      whereArgs: [username, hash],
    );"""
new_auth = """  Future<Usuario?> authenticate(String username, String password) async {
    final db = await dbHelper.database;
    final hash = HashUtils.hashPassword(password);

    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: '(username = ? OR correo = ?) AND password_hash = ? AND activo = 1 AND bloqueado = 0',
      whereArgs: [username, username, hash],
    );"""

if "where: 'username = ?" in text:
    text = text.replace(old_auth, new_auth)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Done")
