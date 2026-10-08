import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Class and variable names shouldn't have accents
    content = content.replaceAll('Categoría', 'Categoria');
    content = content.replaceAll('Categorías', 'Categorias');
    content = content.replaceAll('_Categorias', '_Categorias');
    content = content.replaceAll('Módulo', 'Modulo');
    content = content.replaceAll('validañadoId', 'validate()');
    content = content.replaceAll('validañate()', 'validate()');
    content = content.replaceAll('disableInsumo', 'deleteInsumo');
    content = content.replaceAll('costoPorUnidañado', 'costoPorUnidad');

    // Only put accents in Strings/UI
    // I will just remove all accents from code and put them ONLY where I know they are strings.
    // Actually, it's easier to just remove accents from Categoría because we can live with "Categoria" in the UI for a second while the app compiles.
    
    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed logic in: ${file.path}');
    }
  }
}
