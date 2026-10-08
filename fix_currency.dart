import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Replace literal \$ with S/
    content = content.replaceAll('\\\$', 'S/ ');
    content = content.replaceAll('S/ {', '\${'); // Fix string interpolation if we replaced something like \${
    content = content.replaceAll('S/ v', '\$v'); // Fix $var
    content = content.replaceAll('S/ i', '\$i'); // Fix $item
    
    // Some places might just use '$' string literal for dollar sign instead of \$
    content = content.replaceAll("'\$'", "'S/'");
    content = content.replaceAll('"\$"', '"S/"');

    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed currency in: ${file.path}');
    }
  }
}
