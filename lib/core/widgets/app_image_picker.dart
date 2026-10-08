import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Widget centralizado de selección de imagen.
/// Reutilizar en: activos, insumos, compras, productos, promociones, configuración QR, usuario.
class AppImagePicker extends StatelessWidget {
  final String? currentImagePath;
  final ValueChanged<String?> onImageSelected;
  final double size;
  final double borderRadius;
  final IconData defaultIcon;
  final String? label;
  final bool isCircular;

  const AppImagePicker({
    super.key,
    this.currentImagePath,
    required this.onImageSelected,
    this.size = 120,
    this.borderRadius = 16,
    this.defaultIcon = Icons.add_a_photo,
    this.label,
    this.isCircular = false,
  });

  Future<void> _showPickerOptions(BuildContext context) async {
    final imageService = ImageService();
    final result = await showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: AppRadius.roundAll)),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Tomar foto'),
              onTap: () async {
                final path = await imageService.pickImageFromCamera();
                if (context.mounted) Navigator.pop(context, path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Seleccionar de galería'),
              onTap: () async {
                final path = await imageService.pickImageFromGallery();
                if (context.mounted) Navigator.pop(context, path);
              },
            ),
            if (currentImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Eliminar imagen'),
                onTap: () => Navigator.pop(context, '__remove__'),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    
    if (result == '__remove__') {
      onImageSelected(null);
    } else if (result != null) {
      onImageSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = currentImagePath != null;
    final content = hasImage
        ? Image.file(File(currentImagePath!), fit: BoxFit.cover, width: size, height: size)
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(defaultIcon, size: size * 0.33, color: AppColors.textSecondary),
              if (label != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(label!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
                ),
              ],
            ],
          );

    return GestureDetector(
      onTap: () => _showPickerOptions(context),
      child: isCircular
          ? CircleAvatar(
              radius: size / 2,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: hasImage ? FileImage(File(currentImagePath!)) : null,
              child: hasImage ? null : Icon(defaultIcon, size: size * 0.4, color: AppColors.textSecondary),
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
    );
  }
}
