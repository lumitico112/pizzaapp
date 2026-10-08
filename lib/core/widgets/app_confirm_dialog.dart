import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Diálogo de confirmación reutilizable para acciones críticas.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.confirmColor,
    this.icon,
  });

  /// Muestra el diálogo y retorna true si confirma, false/null si cancela
  static Future<bool> show(BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    Color? confirmColor,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppConfirmDialog(
        title: title, message: message,
        confirmLabel: confirmLabel, cancelLabel: cancelLabel,
        confirmColor: confirmColor, icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final color = confirmColor ?? AppColors.primary;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: AppTextStyles.heading3)),
        ],
      ),
      content: Text(message, style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel, style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel, style: AppTextStyles.buttonMedium),
        ),
      ],
    );
  }
}
