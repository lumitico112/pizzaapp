import 'package:flutter/material.dart';

/// Sistema centralizado de colores. NUNCA escribir colores hardcoded en pantallas.
/// Usar siempre AppColors.xxx
class AppColors {
  AppColors._();

  // --- MARCA ---
  static const Color primary = Color(0xFFE67E22);      // Naranja cálido
  static const Color primaryDark = Color(0xFFC0392B);  // Rojo pizzería
  static const Color primaryLight = Color(0xFFF39C12); // Naranja claro
  static const Color secondary = Color(0xFF2C7873);    // Teal oscuro
  static const Color secondaryLight = Color(0xFF52B788); // Verde suave

  // --- SUPERFICIE ---
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  static const Color cardBorder = Color(0xFFE0E0E0);

  // --- ESTADOS ---
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD5F5E3);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDECEC);
  static const Color info = Color(0xFF2980B9);
  static const Color infoLight = Color(0xFFD6EAF8);

  // --- STOCK INDICATORS ---
  static const Color stockOk = Color(0xFF27AE60);      // Verde - stock disponible
  static const Color stockLow = Color(0xFFF39C12);     // Amarillo - stock bajo
  static const Color stockEmpty = Color(0xFFE74C3C);   // Rojo - sin stock

  // --- ESTADOS DE ACTIVO ---
  static const Color activoEnUso = Color(0xFF27AE60);         // Verde
  static const Color activoEnReparacion = Color(0xFFF39C12);  // Amarillo
  static const Color activoFueraServicio = Color(0xFFE74C3C); // Rojo

  // --- TEXTO ---
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);
  static const Color textInverse = Colors.white;
  static const Color textDisabled = Color(0xFFBDC3C7);

  // --- OVERLAY ---
  static const Color overlay = Color(0x80000000);       // 50% negro
  static const Color overlayLight = Color(0x33000000);  // 20% negro

  // --- GLASSMORPHISM ---
  static const Color glassWhite = Color(0xA6FFFFFF);    // 65% blanco
  static const Color glassBorder = Color(0x4DFFFFFF);   // 30% blanco
}
