import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/models/usuario.dart'
new_model = """class Usuario {
  final int? id;
  final String nombre;
  final String username;
  final String? correo;
  final String passwordHash;
  final String rol;
  final String? fotoRuta;
  final int activo;
  final int bloqueado;
  final String? recoveryCode;
  final String? createdAt;

  Usuario({
    this.id,
    required this.nombre,
    required this.username,
    this.correo,
    required this.passwordHash,
    required this.rol,
    this.fotoRuta,
    this.activo = 1,
    this.bloqueado = 0,
    this.recoveryCode,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'username': username,
      'correo': correo,
      'password_hash': passwordHash,
      'rol': rol,
      'foto_ruta': fotoRuta,
      'activo': activo,
      'bloqueado': bloqueado,
      'recovery_code': recoveryCode,
      'created_at': createdAt,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nombre: map['nombre'],
      username: map['username'],
      correo: map['correo'],
      passwordHash: map['password_hash'],
      rol: map['rol'],
      fotoRuta: map['foto_ruta'],
      activo: map['activo'] ?? 1,
      bloqueado: map['bloqueado'] ?? 0,
      recoveryCode: map['recovery_code'],
      createdAt: map['created_at'],
    );
  }
}
"""
with open(path, 'w', encoding='utf-8') as f:
    f.write(new_model)
