import 'package:pizzaapp/features/purchases/data/repositories/purchase_repository.dart';
import 'package:pizzaapp/features/purchases/domain/entities/compra_ocasional.dart';
import 'package:pizzaapp/models/compra.dart';
import 'package:pizzaapp/models/cuenta_por_pagar.dart';
import 'package:pizzaapp/repositories/gasto_repository.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/features/purchases/domain/entities/payable_balance.dart';
import 'package:pizzaapp/features/purchases/domain/usecases/register_payable_payment.dart';

/// Coordinates purchase, payable, expense, and cash-session effects.
class CompraService {
  final PurchaseRepository _repository;
  final GastoRepository _gastoRepo;
  final AuthService _authService;
  final RegisterPayablePayment _registerPayablePayment;

  CompraService(
    this._repository,
    this._gastoRepo,
    this._authService,
    this._registerPayablePayment,
  );

  Future<List<Compra>> obtenerHistorialCompras() async {
    final rows = await _repository.getHistorialCompras();
    return rows.map(Compra.fromMap).toList();
  }

  Future<List<CompraOcasional>> obtenerComprasOcasionales() async {
    final rows = await _repository.getComprasOcasionales();
    return rows.map(CompraOcasional.fromMap).toList();
  }

  Future<int> registrarCompraOcasional(CompraOcasional compra) {
    return _repository.registrarCompraOcasional(
      compra.copyWith(usuarioId: _authService.currentUser?.id),
    );
  }

  Future<void> corregirCompraOcasional(CompraOcasional compra) {
    return _repository.corregirCompraOcasional(
      compra.copyWith(usuarioId: _authService.currentUser?.id),
    );
  }

  Future<void> eliminarCompraOcasional(int compraId) {
    return _repository.eliminarCompraOcasional(
      compraId,
      usuarioId: _authService.currentUser?.id,
    );
  }

  Future<List<CuentaPorPagar>> obtenerCuentasPorPagar() async {
    final rows = await _repository.getCuentasPorPagar();
    return rows.map(CuentaPorPagar.fromMap).toList();
  }

  Future<void> registrarCompraDirecta({
    required int insumoId,
    required double cantidad,
    required double costoTotal,
    String? motivo,
    String? facturaRuta,
    String? fecha,
    String metodoPago = 'efectivo',
    int? proveedorId,
  }) async {
    await _repository.registrarCompra(
      insumoId: insumoId,
      cantidad: cantidad,
      costoTotal: costoTotal,
      motivo: motivo,
      facturaRuta: facturaRuta,
      fecha: fecha,
      usuarioId: _authService.currentUser?.id,
      metodoPago: metodoPago,
      proveedorId: proveedorId,
    );
  }

  Future<void> registrarCompraPorPagar({
    required int insumoId,
    required double cantidad,
    required double costoTotal,
    String? proveedor,
    int? proveedorId,
    String? factura,
    String? facturaRuta,
    double adelanto = 0,
    String? fecha,
    String metodoPago = 'efectivo',
    int cuotas = 1,
  }) async {
    if (adelanto < 0 || adelanto > costoTotal) {
      throw Exception('El adelanto no puede ser negativo ni superar el total.');
    }
    await _repository.registrarCompraPorPagar(
      insumoId: insumoId,
      cantidad: cantidad,
      costoTotal: costoTotal,
      adelanto: adelanto,
      proveedor: proveedor,
      proveedorId: proveedorId,
      factura: factura,
      facturaRuta: facturaRuta,
      fecha: fecha,
      usuarioId: _authService.currentUser?.id,
      metodoPago: metodoPago,
      cuotas: cuotas,
    );
  }

  Future<void> corregirCompra({
    required int movimientoId,
    required double cantidad,
    required double costoTotal,
    int? nuevoInsumoId,
    String? fecha,
    String? motivo,
    String? proveedor,
    int? proveedorId,
    String? facturaRuta,
    bool? esPorPagar,
    double? adelanto,
    int cuotas = 1,
    String metodoPago = 'efectivo',
  }) =>
      _repository.corregirCompra(
        movimientoId: movimientoId,
        cantidad: cantidad,
        costoTotal: costoTotal,
        nuevoInsumoId: nuevoInsumoId,
        fecha: fecha,
        motivo: motivo,
        proveedor: proveedor,
        proveedorId: proveedorId,
        facturaRuta: facturaRuta,
        esPorPagar: esPorPagar,
        adelanto: adelanto,
        cuotas: cuotas,
        metodoPago: metodoPago,
        usuarioId: _authService.currentUser?.id,
      );

  Future<void> eliminarCompra(int movimientoId) => _repository.eliminarCompra(
        movimientoId,
        usuarioId: _authService.currentUser?.id,
      );

  Future<void> eliminarGasto(int gastoId) => _repository.eliminarGasto(
        gastoId,
        usuarioId: _authService.currentUser?.id,
      );

  Future<List<Map<String, dynamic>>> obtenerGastosRaw() =>
      _gastoRepo.getGastosRaw();

  Future<void> pagarCuentaPorPagar(
    int cuentaId,
    double montoAbono, {
    String metodoPago = 'efectivo',
    String? nota,
  }) async {
    await _registerPayablePayment(
      PayablePayment(
        accountId: cuentaId,
        amount: montoAbono,
        paymentMethod: metodoPago,
        note: nota,
        userId: _authService.currentUser?.id,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialPagos(int cuentaId) =>
      _repository.getPaymentHistory(cuentaId);

  Future<void> anularPagoCuentaPorPagar(int pagoId) =>
      _repository.anularPagoCuentaPorPagar(
        pagoId,
        usuarioId: _authService.currentUser?.id,
      );
}
