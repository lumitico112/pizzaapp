import 'package:pizzaapp/models/proveedor.dart';
import 'package:pizzaapp/repositories/proveedor_repository.dart';

class ProveedorService {
  final ProveedorRepository _repo;
  ProveedorService(this._repo);

  Future<List<Proveedor>> obtenerProveedores() => _repo.getProveedores();

  Future<Proveedor> guardarProveedor(Proveedor p) async {
    if (p.nombre.trim().isEmpty) throw Exception('El nombre del proveedor es obligatorio.');
    final existe = await _repo.existeNombre(p.nombre, exceptoId: p.id);
    if (existe) throw Exception('El proveedor ya existe.');
    if (p.id == null) {
      final id = await _repo.insertProveedor(p);
      return p.copyWith(id: id);
    } else {
      await _repo.updateProveedor(p);
      return p;
    }
  }

  Future<void> eliminarProveedor(int id) => _repo.desactivarProveedor(id);
}
