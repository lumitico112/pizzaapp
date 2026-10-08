import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found.');
    return;
  }

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int updatedCount = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Fix Mojibake
    content = content.replaceAll('Catǭlogo', 'Catálogo');
    content = content.replaceAll('CatÃ¡logo', 'Catálogo');
    content = content.replaceAll('Categora', 'Categoría');
    content = content.replaceAll('CategorÃ­a', 'Categoría');
    content = content.replaceAll('Descripcin', 'Descripción');
    content = content.replaceAll('Mdulo', 'Módulo');
    content = content.replaceAll('construccin', 'construcción');
    content = content.replaceAll('Tamao', 'Tamaño');
    content = content.replaceAll('Aadir', 'Añadir');
    content = content.replaceAll('daado', 'dañado');
    content = content.replaceAll('', 'í'); // Any leftover replacements? We must be careful

    // Fix currency symbols (replace literal $ or \$ that are used for display with S/)
    // We must avoid replacing Dart string interpolation $var or ${var}
    // So we replace \$ with S/
    content = content.replaceAll(r'\$ ', 'S/ ');
    content = content.replaceAll(r'\$', 'S/');
    // Replace standalone $ in Text widgets where it might just be '$ '
    content = content.replaceAll("Text('\$ ", "Text('S/ ");
    content = content.replaceAll("Text('\$'", "Text('S/')");
    content = content.replaceAll("Text(\"\$ ", "Text(\"S/ ");
    content = content.replaceAll("Text(\"\$\"", "Text(\"S/\")");
    
    // Some formats use '\${' which is dart string interpolation. Wait!
    // If a string is 'Total: \${val}', we want 'Total: S/ ${val}'.
    // So replacing \$ with S/ will correctly change 'Total: \${val}' into 'Total: S/ {val}'.
    // WAIT. If it was '\${val}', and we replace '\$' with 'S/', it becomes 'S/{val}'. That's wrong. It should be 'S/ ${val}'
    // Let's replace '\${' with 'S/ ${'
    content = content.replaceAll(r'\${', r'S/ ${');
    content = content.replaceAll(r'\$${', r'S/ ${'); // In case someone did $${
    // Any remaining '\$' that isn't interpolation
    content = content.replaceAll(r'\$', 'S/ ');
    content = content.replaceAll('S/  ', 'S/ '); // clean up double spaces

    // If there is any plain '$' not followed by a variable (e.g. '$ ' or ' $ ' or '$0.00'), we replace it manually.
    content = content.replaceAll(r"'$ ", r"'S/ ");
    content = content.replaceAll(r'"$ ', r'"S/ ');
    content = content.replaceAll(r" $ ", r" S/ ");
    content = content.replaceAll(r" $'", r" S/'");
    content = content.replaceAll(r' $"', r' S/"');

    if (content != original) {
      // Revert the naive  to í replacement if it messed up the file too much, 
      // but let's just do targeted fixes instead of a blanket ``.
      content = original;
      
      content = content.replaceAll('Catǭlogo', 'Catálogo');
      content = content.replaceAll('CatÃ¡logo', 'Catálogo');
      content = content.replaceAll('Categora', 'Categoría');
      content = content.replaceAll('Descripcin', 'Descripción');
      content = content.replaceAll('Mdulo', 'Módulo');
      content = content.replaceAll('construccin', 'construcción');
      content = content.replaceAll('Tamao', 'Tamaño');
      content = content.replaceAll('Tamaos', 'Tamaños');
      content = content.replaceAll('Aadir', 'Añadir');
      content = content.replaceAll('daado', 'dañado');
      content = content.replaceAll('aqu', 'aquí');
      content = content.replaceAll('recin', 'recién');
      content = content.replaceAll('podrs', 'podrás');
      content = content.replaceAll('automticamente', 'automáticamente');
      content = content.replaceAll('basndose', 'basándose');
      content = content.replaceAll('encriptacin', 'encriptación');
      content = content.replaceAll('Auditora', 'Auditoría');

      // Currency
      content = content.replaceAll(r'\${', r'S/ ${');
      content = content.replaceAll(r'\$', 'S/ ');
      content = content.replaceAll('S/  ', 'S/ ');
      content = content.replaceAll(r"'$ ", r"'S/ ");
      content = content.replaceAll(r'"$ ', r'"S/ ');
      content = content.replaceAll(r" $ ", r" S/ ");
      content = content.replaceAll(r" $'", r" S/'");
      content = content.replaceAll(r' $"', r' S/"');
      // Fix cases where replacing \$${ left us with S/ ${
      content = content.replaceAll(r'S/ {', r'S/ ${');

      file.writeAsStringSync(content);
      updatedCount++;
      print('Updated: ${file.path}');
    }
  }
  print('Total files updated: $updatedCount');
}
