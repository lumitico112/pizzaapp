import 'package:flutter/material.dart';

/// Sistema centralizado de colores. NUNCA escribir colores hardcoded en pantallas.
/// Usar siempre AppColors.xxx
class AppColors {
  AppColors._();

  // --- MARCA ---
  static const Color primary = Color(0xFFC94B35); // Tomate
  static const Color primaryDark = Color(0xFFA83828);
  static const Color primaryLight = Color(0xFFE58B42);
  static const Color tomato = Color(0xFFC94B35);
  static const Color secondary = Color(0xFF3D7758); // Verde oliva
  static const Color secondaryLight = Color(0xFF78A184);
  static const Color purple = Color(0xFF765779);

  // --- SUPERFICIE ---
  static const Color background = Color(0xFFF8F4EB);
  static const Color dashboardBackground = Color(0xFFF8F4EB);
  static const Color surface = Color(0xFFFFFDFA);
  static const Color surfaceVariant = Color(0xFFF1EADC);
  static const Color cardBorder = Color(0xFFE7DFD2);
  static const Color tomatoSoft = Color(0xFFFAE8E2);

  // --- ESTADOS ---
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD5F5E3);
  static const Color warning = Color(0xFFA96821);
  static const Color warningLight = Color(0xFFF8EDD5);
  static const Color error = Color(0xFFA43D32);
  static const Color errorLight = Color(0xFFF8E4DF);
  static const Color info = Color(0xFF426B86);
  static const Color infoLight = Color(0xFFE7F0F5);

  // --- STOCK INDICATORS ---
  static const Color stockOk = Color(0xFF27AE60); // Verde - stock disponible
  static const Color stockLow = Color(0xFFF39C12); // Amarillo - stock bajo
  static const Color stockEmpty = Color(0xFFE74C3C); // Rojo - sin stock

  // --- ESTADOS DE ACTIVO ---
  static const Color activoEnUso = Color(0xFF27AE60); // Verde
  static const Color activoEnReparacion = Color(0xFFF39C12); // Amarillo
  static const Color activoFueraServicio = Color(0xFFE74C3C); // Rojo

  // --- TEXTO ---
  static const Color textPrimary = Color(0xFF26231F);
  static const Color textSecondary = Color(0xFF756E64);
  static const Color textHint = Color(0xFFA69E93);
  static const Color textInverse = Colors.white;
  static const Color textDisabled = Color(0xFFBDC3C7);

  // --- OVERLAY ---
  static const Color overlay = Color(0x80000000); // 50% negro
  static const Color overlayLight = Color(0x33000000); // 20% negro

  // --- GLASSMORPHISM ---
  static const Color glassWhite = Color(0xA6FFFFFF); // 65% blanco
  static const Color glassBorder = Color(0x4DFFFFFF); // 30% blanco
}
