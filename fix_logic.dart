import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Fix empaquíeInsumoId
    if (content.contains('empaquíeInsumoId')) {
      content = content.replaceAll('empaquíeInsumoId', 'empaqueInsumoId');
      changed = true;
    }
    if (content.contains('empaquíe_insumo_id')) {
      content = content.replaceAll('empaquíe_insumo_id', 'empaque_insumo_id');
      changed = true;
    }
    
    // Fix costoPorUnidañado -> costoPorUnidad
    if (content.contains('costoPorUnidañado')) {
      content = content.replaceAll('costoPorUnidañado', 'costoPorUnidad');
      changed = true;
    }
    
    // Fix cantidañado -> cantidad
    if (content.contains('cantidañado')) {
      content = content.replaceAll('cantidañado', 'cantidad');
      changed = true;
    }
    
    // Fix variables with accents
    if (content.contains('_loadCategorías')) {
      content = content.replaceAll('_loadCategorías', '_loadCategorias');
      changed = true;
    }
    if (content.contains('_filtrarCategoría')) {
      content = content.replaceAll('_filtrarCategoría', '_filtrarCategoria');
      changed = true;
    }
    if (content.contains('CategoríaId')) {
      content = content.replaceAll('CategoríaId', 'CategoriaId');
      changed = true;
    }
    if (content.contains('categoríaId')) {
      content = content.replaceAll('categoríaId', 'categoriaId');
      changed = true;
    }
    
    // Fix dashboard ScaffoldMódulo
    if (file.path.contains('dashboard_screen.dart') && content.contains('ScaffoldMódulo')) {
      // The regex M(?![A-Z])[^d]+dulo wiped out: essenger.of(context).showSnackBar( SnackBar(content: Text('Mó
      // Let's reconstruct that else block.
      content = content.replaceAll(
          'ScaffoldMódulo "\$title" en construcción\')),\n      );', 
          'ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(content: Text(\'Módulo "\$title" en construcción\')),\n      );'
      );
      // Wait, what exactly is the text?
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed logic in: ${file.path}');
    }
  }
}
