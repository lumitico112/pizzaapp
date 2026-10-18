class Categoria {
  final int? id;
  final String nombre;
  final String? icono;
  final int orden;

  Categoria({this.id, required this.nombre, this.icono, this.orden = 0});

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'icono': icono,
    'orden': orden,
  };

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
    id: map['id'],
    nombre: map['nombre'],
    icono: map['icono'],
    orden: map['orden'],
  );
}

class Producto {
  final int? id;
  final String nombre;
  final int? categoriaId;
  final String? descripcion;
  final String? fotoRuta;
  final String tipoPreparacion;
  final int? bebidaCortesiaInsumoId;
  final double bebidaCortesiaCantidad;
  final int activo;
  final int? derivaDeProductoId;

  Producto({
    this.id,
    required this.nombre,
    this.categoriaId,
    this.descripcion,
    this.fotoRuta,
    this.tipoPreparacion = 'momento',
    this.bebidaCortesiaInsumoId,
    this.bebidaCortesiaCantidad = 1,
    this.activo = 1,
    this.derivaDeProductoId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'categoria_id': categoriaId,
    'descripcion': descripcion,
    'foto_ruta': fotoRuta,
    'tipo_preparacion': tipoPreparacion,
    'bebida_cortesia_insumo_id': bebidaCortesiaInsumoId,
    'bebida_cortesia_cantidad': bebidaCortesiaCantidad,
    'activo': activo,
    'deriva_de_producto_id': derivaDeProductoId,
  };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
    id: map['id'],
    nombre: map['nombre'],
    categoriaId: map['categoria_id'],
    descripcion: map['descripcion'],
    fotoRuta: map['foto_ruta'],
    tipoPreparacion: map['tipo_preparacion'],
    bebidaCortesiaInsumoId: map['bebida_cortesia_insumo_id'],
    bebidaCortesiaCantidad:
        (map['bebida_cortesia_cantidad'] as num?)?.toDouble() ?? 1,
    activo: map['activo'],
    derivaDeProductoId: map['deriva_de_producto_id'] as int?,
  );
}

class VarianteProducto {
  final int? id;
  final int productoId;
  final String nombreVariante;
  final double precioVenta;
  final double costoEstimadoManual;
  final int? empaqueInsumoId;
  final String? imagen;
  final int stock;
  final int active;
  final int? varianteBaseId;

  VarianteProducto({
    this.id,
    required this.productoId,
    required this.nombreVariante,
    required this.precioVenta,
    this.costoEstimadoManual = 0,
    this.empaqueInsumoId,
    this.imagen,
    this.stock = 0,
    this.active = 1,
    this.varianteBaseId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'producto_id': productoId,
    'nombre_variante': nombreVariante,
    'precio_venta': precioVenta,
    'costo_estimado_manual': costoEstimadoManual,
    'empaque_insumo_id': empaqueInsumoId,
    'imagen': imagen,
    'stock': stock,
    'active': active,
    'variante_base_id': varianteBaseId,
  };

  factory VarianteProducto.fromMap(Map<String, dynamic> map) =>
      VarianteProducto(
        id: map['id'],
        productoId: map['producto_id'],
        nombreVariante: map['nombre_variante'],
        precioVenta: (map['precio_venta'] ?? 0.0).toDouble(),
        costoEstimadoManual: (map['costo_estimado_manual'] ?? 0.0).toDouble(),
        empaqueInsumoId: map['empaque_insumo_id'],
        imagen: map['imagen'],
        stock: map['stock'] ?? 0,
        active: (map['active'] as num?)?.toInt() ?? 1,
        varianteBaseId: map['variante_base_id'] as int?,
      );
}
