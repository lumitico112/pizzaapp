import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Use a very permissive regex to match Cat<anything>logo
    content = content.replaceAll(RegExp(r"Cat(?![A-Z])[^l]+logo"), 'Catálogo');
    content = content.replaceAll(RegExp(r"Categor(?![A-Z])[^a]+a"), 'Categoría');
    content = content.replaceAll(RegExp(r"Categor(?![A-Z])[^a]+as"), 'Categorías');
    content = content.replaceAll(RegExp(r"M(?![A-Z])[^d]+dulo"), 'Módulo');
    content = content.replaceAll(RegExp(r"construcci(?![A-Z])[^n]+n"), 'construcción');
    content = content.replaceAll(RegExp(r"Descripci(?![A-Z])[^n]+n"), 'Descripción');
    content = content.replaceAll(RegExp(r"Tama(?![A-Z])[^o]+o"), 'Tamaño');
    content = content.replaceAll(RegExp(r"Tama(?![A-Z])[^o]+os"), 'Tamaños');
    content = content.replaceAll(RegExp(r"da(?![A-Z])[^a]+ado"), 'dañado');
    content = content.replaceAll(RegExp(r"autom(?![A-Z])[^t]+ticamente"), 'automáticamente');
    content = content.replaceAll(RegExp(r"encriptaci(?![A-Z])[^n]+n"), 'encriptación');
    
    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed accents via wildcard in: ${file.path}');
    }
  }
}
