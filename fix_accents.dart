import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    content = content.replaceAll(RegExp(r'empaqu[^A-Za-z0-9_]?eInsumoId'), 'empaqueInsumoId');
    content = content.replaceAll(RegExp(r'empaqu[^A-Za-z0-9_]?e_insumo_id'), 'empaque_insumo_id');
    content = content.replaceAll(RegExp(r'M[^A-Za-z0-9_ \n]?dulo'), 'Módulo');
    content = content.replaceAll(RegExp(r'M[^A-Za-z0-9_ \n]{2,}dulo'), 'Módulo');
    
    // Some corrupted chars might be 2 or 3 bytes (like ǭ or ǟ)
    content = content.replaceAll(RegExp(r'Cat[^A-Za-z0-9_ \n]{1,3}logo'), 'Catálogo');
    content = content.replaceAll(RegExp(r'Categor[^A-Za-z0-9_ \n]{1,3}a'), 'Categoría');
    content = content.replaceAll(RegExp(r'Categor[^A-Za-z0-9_ \n]{1,3}as'), 'Categorías');
    content = content.replaceAll(RegExp(r'construcci[^A-Za-z0-9_ \n]{1,3}n'), 'construcción');
    content = content.replaceAll(RegExp(r'Descripci[^A-Za-z0-9_ \n]{1,3}n'), 'Descripción');
    content = content.replaceAll(RegExp(r'Tama[^A-Za-z0-9_ \n]{1,3}o'), 'Tamaño');
    content = content.replaceAll(RegExp(r'A[^A-Za-z0-9_ \n]{1,3}adir'), 'Añadir');
    content = content.replaceAll(RegExp(r'da[^A-Za-z0-9_ \n]{1,3}ado'), 'dañado');
    content = content.replaceAll(RegExp(r'aqu[^A-Za-z0-9_ \n]{1,3}'), 'aquí');
    content = content.replaceAll(RegExp(r'reci[^A-Za-z0-9_ \n]{1,3}n'), 'recién');
    content = content.replaceAll(RegExp(r'podr[^A-Za-z0-9_ \n]{1,3}s'), 'podrás');
    content = content.replaceAll(RegExp(r'autom[^A-Za-z0-9_ \n]{1,3}ticamente'), 'automáticamente');
    content = content.replaceAll(RegExp(r'bas[^A-Za-z0-9_ \n]{1,3}ndose'), 'basándose');
    content = content.replaceAll(RegExp(r'encriptaci[^A-Za-z0-9_ \n]{1,3}n'), 'encriptación');
    content = content.replaceAll(RegExp(r'Auditor[^A-Za-z0-9_ \n]{1,3}a'), 'Auditoría');

    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed encodings in: ${file.path}');
    }
  }
}
