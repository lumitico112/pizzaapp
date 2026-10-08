class Proveedor {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? notas;
  final bool activo;

  const Proveedor({
    this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.notas,
    this.activo = true,
  });

  Proveedor copyWith({
    int? id, String? nombre, String? telefono, String? email,
    String? direccion, String? notas, bool? activo,
  }) => Proveedor(
    id: id ?? this.id, nombre: nombre ?? this.nombre,
    telefono: telefono ?? this.telefono, email: email ?? this.email,
    direccion: direccion ?? this.direccion, notas: notas ?? this.notas,
    activo: activo ?? this.activo,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'nombre': nombre, 'telefono': telefono,
    'email': email, 'direccion': direccion, 'notas': notas,
    'activo': activo ? 1 : 0,
  };

  factory Proveedor.fromMap(Map<String, dynamic> map) => Proveedor(
    id: map['id'],
    nombre: map['nombre'],
    telefono: map['telefono'],
    email: map['email'],
    direccion: map['direccion'],
    notas: map['notas'],
    activo: (map['activo'] ?? 1) == 1,
  );
}
