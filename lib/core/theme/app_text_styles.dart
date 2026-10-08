import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto centralizados. Siempre usar AppTextStyles.xxx
class AppTextStyles {
  AppTextStyles._();

  // --- TÍTULOS ---
  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  // --- CUERPO ---
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary,
  );

  // --- LABELS ---
  static const TextStyle labelBold = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle labelSecondary = TextStyle(
    fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.textSecondary,
  );

  // --- MONEDA ---
  static const TextStyle currencyLarge = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.success,
  );
  static const TextStyle currencyMedium = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success,
  );
  static const TextStyle currencyNegative = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error,
  );

  // --- BOTÓN ---
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white,
  );
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
  );

  // --- APPBAR ---
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
  );

  // Helpers dinámicos
  static TextStyle colored(Color color, {double? size, FontWeight? weight}) => TextStyle(
    color: color, fontSize: size, fontWeight: weight,
  );
}
