class CategoriaActivo {
  final int? id;
  final String nombre;

  CategoriaActivo({this.id, required this.nombre});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  factory CategoriaActivo.fromMap(Map<String, dynamic> map) {
    return CategoriaActivo(
      id: map['id'],
      nombre: map['nombre'],
    );
  }
}
