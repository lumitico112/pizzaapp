import sys
import re

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/compra_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Modify class constructor
import_gasto = "import 'package:pizzaapp/models/gasto.dart';\nimport 'package:pizzaapp/repositories/gasto_repository.dart';\n"
if "gasto_repository" not in text:
    text = import_gasto + text

old_class = """class CompraService {
  final InsumoRepository _repository;

  CompraService(this._repository);"""
new_class = """class CompraService {
  final InsumoRepository _repository;
  final GastoRepository _gastoRepo;

  CompraService(this._repository, this._gastoRepo);"""
text = text.replace(old_class, new_class)

old_pagar = """  Future<void> pagarCuentaPorPagar(int cuentaId) async {
    await _repository.pagarCuenta(cuentaId);
  }"""
new_pagar = """  Future<void> pagarCuentaPorPagar(int cuentaId, double montoAbono) async {
    // 1. Obtener datos de la cuenta
    final cuentas = await _repository.obtenerCuentasPorPagar(soloPendientes: false);
    final cuenta = cuentas.firstWhere((c) => c.id == cuentaId);
    
    // 2. Registrar el abono en SQLite
    await _repository.abonarCuenta(cuentaId, montoAbono);
    
    // 3. Registrar el gasto
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _gastoRepo.insertGasto(Gasto(
      categoria: 'Cuentas por Pagar',
      monto: montoAbono,
      descripcion: 'Abono/Pago de: ${cuenta.motivo}',
      fecha: hoy,
    ));
  }"""
text = text.replace(old_pagar, new_pagar)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
