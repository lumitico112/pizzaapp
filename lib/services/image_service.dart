import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImageService {
  /// Lado máximo (px) al que se reduce cada imagen capturada o seleccionada
  /// (H-4: límite de dimensiones; el plugin aplica el downscale en origen).
  static const double maxLadoPx = 1600;

  /// Tope de bytes por archivo de imagen (H-4: límite de tamaño).
  static const int maxBytesPorArchivo = 5 * 1024 * 1024;

  final ImagePicker _picker;

  /// [picker] permite inyectar un doble de prueba; en producción se omite.
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<String?> pickImageFromCamera() => _pickImage(ImageSource.camera);

  Future<String?> pickImageFromGallery() => _pickImage(ImageSource.gallery);

  /// Indica si un archivo excede el tope de bytes permitido (H-4).
  /// La frontera exacta es válida: se rechaza solo si `bytes > limite`.
  static bool excedeLimiteBytes(int bytes, {int limite = maxBytesPorArchivo}) =>
      bytes > limite;

  Future<String?> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: maxLadoPx,
      maxHeight: maxLadoPx,
    );
    if (picked == null) return null;

    // Defensa en profundidad: si la plataforma no aplicó el downscale y el
    // archivo supera el tope, se descarta con borrado seguro sin romper el
    // contrato: `null` equivale a cancelación/rechazo.
    try {
      final bytes = await picked.length();
      if (excedeLimiteBytes(bytes)) {
        await deleteLocalFile(picked.path);
        return null;
      }
    } catch (_) {
      // Si no se puede medir el archivo, se conserva el flujo original.
    }
    return picked.path;
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
