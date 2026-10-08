import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    content = content.replaceAll('Categoriaia', 'Categoria');
    content = content.replaceAll('Categoriaias', 'Categorias');
    content = content.replaceAll('Categoriay', 'category');

    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed Categoriaia in: ${file.path}');
    }
  }
}
