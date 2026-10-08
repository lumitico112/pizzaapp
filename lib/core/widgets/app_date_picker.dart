import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

/// Widget centralizado de selección de fecha.
/// Reutilizar en: activos, compras, ventas anteriores, cierre de caja, etc.
class AppDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String label;

  const AppDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.firstDate,
    this.lastDate,
    this.label = 'Fecha',
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Utilidad de fechas centralizada
class AppDateUtils {
  static String formatDisplay(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String formatDisplay2(DateTime d) => DateFormat('dd MMM yyyy', 'es').format(d);
  static String formatStorage(DateTime d) => d.toIso8601String().split('T')[0];
  static String formatFull(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);
  
  static DateTime get todayStart => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  
  static DateTime get weekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)); // Lunes
  }
  
  static DateTime get monthStart => DateTime(DateTime.now().year, DateTime.now().month, 1);
}
