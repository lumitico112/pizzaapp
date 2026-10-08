class CategoriaInsumo {
  final int? id;
  final String nombre;
  
  CategoriaInsumo({this.id, required this.nombre});
  
  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre};
  
  factory CategoriaInsumo.fromMap(Map<String, dynamic> map) => CategoriaInsumo(
    id: map['id'], 
    nombre: map['nombre']
  );
}
