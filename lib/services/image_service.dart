import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    return picked?.path;
  }

  Future<String?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    return picked?.path;
  }

  /// Elimina de forma segura un archivo de imagen local en disco si existe.
  static Future<void> deleteLocalFile(String? filePath) async {
    final normalized = filePath?.trim();
    if (normalized == null || normalized.isEmpty) return;
    try {
      final file = File(normalized);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // No interrumpir el flujo de negocio si el archivo ya no existe o está bloqueado.
    }
  }

  /// Elimina múltiples archivos locales de imagen si existen en disco.
  static Future<void> deleteLocalFiles(Iterable<String?> filePaths) async {
    final uniquePaths = filePaths
        .map((p) => p?.trim())
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toSet();
    for (final path in uniquePaths) {
      await deleteLocalFile(path);
    }
  }
}
