import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/widgets/app_states.dart';

class RecetasScreen extends StatelessWidget {
  const RecetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Recetas'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: const AppEmptyState(
        message: 'Lista de Recetas en construcción',
        icon: Icons.receipt_long,
      ),
    );
  }
}
