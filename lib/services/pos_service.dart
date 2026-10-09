import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/models/venta.dart';
import 'package:pizzaapp/repositories/producto_repository.dart';
import 'package:pizzaapp/repositories/venta_repository.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/core/utils/pdf_helper.dart';

class PosItem {
  final Producto producto;
  final VarianteProducto variante;
  PosItem(this.producto, this.variante);
}

class CartItem {
  final Producto? producto;
  final VarianteProducto? variante;
  int cantidad;
  double? precioPersonalizado;
  bool esCortesia;
  bool esPromocion;
  int? promocionId;
  String? nombrePromocion;
  double? precioPromocion;

  CartItem({
    this.producto,
    this.variante,
    this.cantidad = 1,
    this.precioPersonalizado,
    this.esCortesia = false,
    this.esPromocion = false,
    this.promocionId,
    this.nombrePromocion,
    this.precioPromocion,
  });
  
  double get total => esCortesia ? 0.0 : ((precioPersonalizado ?? (esPromocion ? precioPromocion! : variante!.precioVenta)) * cantidad);
  double get precioFinal => esCortesia ? 0.0 : (precioPersonalizado ?? (esPromocion ? precioPromocion! : variante!.precioVenta));
}

class PosService {
  final ProductoRepository _productoRepo;
  final VentaRepository _ventaRepo;
  final CajaRepository _cajaRepo;

  PosService(this._productoRepo, this._ventaRepo, this._cajaRepo);

  Future<List<Categoria>> getCategorias() async {
    return await _productoRepo.getCategorias();
  }

  Future<List<PosItem>> getPosItems(int? categoriaId) async {
    final prods = await _productoRepo.getProductos(categoriaId: categoriaId);
    List<PosItem> flatItems = [];
    for (var p in prods) {
      final vars = await _productoRepo.getVariantesPorProducto(p.id!);
      for (var v in vars) {
        flatItems.add(PosItem(p, v));
      }
    }
    return flatItems;
  }

  Future<String?> registrarVenta({
    required List<CartItem> carrito,
    required String metodoPago,
    required double totalCalculado,
    required String observaciones,
    String? fechaPersonalizada,
  }) async {
    if (carrito.isEmpty) {
      throw Exception('El carrito está vacío.');
    }

    final now = DateTime.now();
    String fecha = fechaPersonalizada ?? now.toIso8601String().split('T')[0];

    String notasFinales = observaciones;
    if (carrito.any((item) => item.esCortesia)) {
      notasFinales = (notasFinales.isEmpty) ? "(Cortesía)" : "$notasFinales (Cortesía)";
    }

    final venta = Venta(
      fecha: fecha,
      hora: "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      subtotal: totalCalculado,
      total: totalCalculado,
      metodoPago: metodoPago,
      nota: notasFinales,
    );

    final detalles = carrito.map((item) => DetalleVenta(
      ventaId: 0, // El repository lo autogenera
      varianteId: item.variante?.id,
      promocionId: item.promocionId,
      cantidad: item.cantidad,
      precioUnitario: item.precioFinal,
    )).toList();

    int ventaId = await _ventaRepo.registrarVentaCompleta(venta, detalles);
    
    final ventaRegistrada = Venta(
      id: ventaId,
      fecha: venta.fecha,
      hora: venta.hora,
      subtotal: venta.subtotal,
      total: venta.total,
      metodoPago: venta.metodoPago,
      nota: venta.nota,
    );

    // Registrar en Caja si hay sesión activa
    final sesionActiva = await _cajaRepo.getSesionActiva();
    if (sesionActiva != null) {
      await _cajaRepo.insertMovimiento(MovimientoCaja(
        sesionCajaId: sesionActiva.id!,
        tipo: 'venta',
        metodoPago: metodoPago,
        monto: totalCalculado,
        descripcion: 'Venta #$ventaId',
        fecha: now.toIso8601String(),
      ));
    }

    return await generarBoletaPDF(ventaRegistrada, detalles, carrito);
  }

  Future<String?> generarBoletaPDF(Venta venta, List<DetalleVenta> detalles, [List<CartItem>? carrito]) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Boleta de Venta', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text('Fecha: ${venta.fecha} ${venta.hora}'),
              pw.Text('Total: S/ ${venta.total}'),
              if (venta.nota != null && venta.nota!.isNotEmpty)
                pw.Text('Notas: ${venta.nota}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Producto', 'Cant', 'Precio', 'Subtotal'],
                  for (int i = 0; i < detalles.length; i++)
                    [
                      carrito != null 
                        ? (carrito[i].esPromocion ? PdfHelper.sanitize("PROMO: ${carrito[i].nombrePromocion}") : PdfHelper.sanitize("${carrito[i].producto!.nombre} - ${carrito[i].variante!.nombreVariante}"))
                        : (detalles[i].promocionId != null ? "Promo ID: ${detalles[i].promocionId}" : detalles[i].varianteId.toString()),
                      detalles[i].cantidad.toString(),
                      detalles[i].precioUnitario.toStringAsFixed(2),
                      (detalles[i].cantidad * detalles[i].precioUnitario).toStringAsFixed(2)
                    ]
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/boleta_${venta.id ?? DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
