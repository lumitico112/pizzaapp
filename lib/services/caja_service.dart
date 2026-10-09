import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pizzaapp/core/utils/pdf_helper.dart';
import 'package:pizzaapp/models/sesion_caja.dart';
import 'package:pizzaapp/models/movimiento_caja.dart';
import 'package:pizzaapp/repositories/caja_repository.dart';

class CajaService {
  final CajaRepository _repository;

  CajaService(this._repository);

  Future<SesionCaja?> getSesionActiva() async {
    return await _repository.getSesionActiva();
  }

  Future<void> abrirCaja(double montoApertura) async {
    final activa = await getSesionActiva();
    if (activa != null) {
      throw Exception('Ya hay una sesiÃ³n de caja abierta.');
    }
    final hoyIso = DateTime.now().toIso8601String();
    
    final nuevaSesion = SesionCaja(
      fechaApertura: hoyIso,
      montoApertura: montoApertura,
      estado: 'abierta',
    );
    
    final id = await _repository.crearSesion(nuevaSesion);

    if (montoApertura > 0) {
      await _repository.insertMovimiento(MovimientoCaja(
        sesionCajaId: id,
        tipo: 'apertura',
        metodoPago: 'efectivo',
        monto: montoApertura,
        descripcion: 'Apertura de caja',
        fecha: hoyIso,
      ));
    }
  }

  Future<void> registrarMovimiento(int sesionId, String tipo, String descripcion, double monto, String metodoPago) async {
    final hoyIso = DateTime.now().toIso8601String();
    await _repository.insertMovimiento(MovimientoCaja(
      sesionCajaId: sesionId,
      tipo: tipo,
      monto: monto,
      descripcion: descripcion,
      metodoPago: metodoPago,
      fecha: hoyIso,
    ));

    // Si es una salida manual, registrarla como Gasto para que aparezca en los Reportes Globales (P&L)
    if (tipo == 'salida') {
      final db = await _repository.dbHelper.database;
      await db.insert('Gastos', {
        'fecha': hoyIso.split('T')[0],
        'categoria': 'Salida Manual de Caja',
        'monto': monto,
        'descripcion': descripcion,
      });
    }
  }
  Future<void> cerrarCaja(double efectivoContado, String nota) async {
    final activa = await getSesionActiva();
    if (activa == null) {
      throw Exception('No hay ninguna sesiÃ³n de caja abierta.');
    }

    final movimientos = await _repository.getMovimientos(activa.id!);
    
    double efectivoSistema = activa.montoApertura;
    double yapePlinSistema = 0.0;
    double gastosSistema = 0.0;

    for (var m in movimientos) {
      if (m.tipo == 'apertura') continue; 
      
      if (m.tipo == 'entrada' || m.tipo == 'venta') {
        if (m.metodoPago == 'efectivo') efectivoSistema += m.monto;
        else if (m.metodoPago == 'yape' || m.metodoPago == 'plin') yapePlinSistema += m.monto;
      } else if (m.tipo == 'salida' || m.tipo == 'compra') {
        if (m.metodoPago == 'efectivo') {
          efectivoSistema -= m.monto;
          gastosSistema += m.monto;
        } else if (m.metodoPago == 'yape' || m.metodoPago == 'plin') {
          yapePlinSistema -= m.monto;
          gastosSistema += m.monto;
        }
      }
    }

    final diferencia = efectivoContado - efectivoSistema;
    final hoyIso = DateTime.now().toIso8601String();

    final sesionCerrada = SesionCaja(
      id: activa.id,
      fechaApertura: activa.fechaApertura,
      montoApertura: activa.montoApertura,
      estado: 'cerrada',
      fechaCierre: hoyIso,
      totalEfectivoSistema: efectivoSistema,
      totalYapePlin: yapePlinSistema,
      efectivoContado: efectivoContado,
      diferencia: diferencia,
      totalGastos: gastosSistema,
      nota: nota,
    );

    await _repository.actualizarSesion(sesionCerrada);
  }

  Future<String?> generarArqueoPDF(SesionCaja sesion) async {
    final pdf = pw.Document();
    
    final movimientos = await _repository.getMovimientos(sesion.id!);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Arqueo de Caja', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Estado: ${sesion.estado}'),
            pw.Text('Fecha Apertura: ${sesion.fechaApertura}'),
            if (sesion.fechaCierre != null) pw.Text('Fecha Cierre: ${sesion.fechaCierre}'),
            pw.Text('Monto Apertura: S/ ${sesion.montoApertura.toStringAsFixed(2)}'),
            pw.SizedBox(height: 10),
            pw.Text('Total Efectivo (Sistema): S/ ${sesion.totalEfectivoSistema.toStringAsFixed(2)}'),
            pw.Text('Total Yape/Plin (Sistema): S/ ${sesion.totalYapePlin.toStringAsFixed(2)}'),
            pw.Text('Total Gastos/Salidas: S/ ${sesion.totalGastos.toStringAsFixed(2)}'),
            pw.SizedBox(height: 10),
            pw.Text('Efectivo Contado: S/ ${sesion.efectivoContado.toStringAsFixed(2)}'),
            pw.Text('Diferencia: S/ ${sesion.diferencia.toStringAsFixed(2)}', 
              style: pw.TextStyle(color: sesion.diferencia < 0 ? PdfColors.red : PdfColors.green)),
            if (sesion.nota != null && sesion.nota!.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('Notas: ${sesion.nota}'),
            ],
            pw.SizedBox(height: 20),
            pw.Text('Movimientos:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Fecha', 'Tipo', 'Monto', 'MÃ©todo', 'DescripciÃ³n'],
                for (var m in movimientos)
                  [
                    m.fecha.split('T')[1].substring(0, 5), 
                    m.tipo, 
                    m.monto.toStringAsFixed(2), 
                    m.metodoPago ?? '-', 
                    PdfHelper.sanitize(m.descripcion ?? '-')
                  ]
              ],
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/arqueo_caja_${sesion.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}

