import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/categoria_insumo.dart';
import 'package:pizzaapp/controllers/categoria_insumo_controller.dart';

/// Pantalla rediseñada de Categorías de Insumos bajo Material Design 3,
/// con paleta funcional (verde bosque #1E4630 / #2E6F40, crema #FBF9F5, rojo #EF4444),
/// tarjetas elevadas de 64px con iconografía descriptiva por categoría,
/// y modal emergente con BackdropFilter (blur de 4px) y animación elástica (scale + fade).
class CategoriasInsumoScreen extends StatefulWidget {
  const CategoriasInsumoScreen({super.key});

  @override
  State<CategoriasInsumoScreen> createState() => _CategoriasInsumoScreenState();
}

class _CategoriasInsumoScreenState extends State<CategoriasInsumoScreen> {
  // Paleta de colores
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _appBarGreen = Color(0xFF1E4630);
  static const Color _accentGreen = Color(0xFF2E6F40);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _pastelGreen = Color(0xFFE2ECE6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaInsumoController>().loadCategorias();
    });
  }

  /// Retorna un icono temático según el nombre de la categoría
  IconData _getIconForCategoria(String nombre) {
    final n = nombre.toLowerCase().trim();
    if (n.contains('ingrediente') ||
        n.contains('alimento') ||
        n.contains('comida') ||
        n.contains('queso') ||
        n.contains('carne') ||
        n.contains('salsa')) {
      return Icons.local_pizza_outlined;
    }
    if (n.contains('empaque') ||
        n.contains('caja') ||
        n.contains('bolsa') ||
        n.contains('descartable') ||
        n.contains('envase')) {
      return Icons.inventory_2_outlined;
    }
    if (n.contains('bebida') ||
        n.contains('gaseosa') ||
        n.contains('jugo') ||
        n.contains('refresco') ||
        n.contains('licor') ||
        n.contains('agua')) {
      return Icons.local_cafe_outlined;
    }
    if (n.contains('limpieza') ||
        n.contains('aseo') ||
        n.contains('detergente') ||
        n.contains('desinfect')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.category_outlined;
  }

  /// Modal con BackdropFilter blur de 4px y animación scale + fade elástica
  void _abrirFormulario() {
    final nameCtrl = TextEditingController();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModalCategoriaInsumo',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4.0 * anim.value,
            sigmaY: 4.0 * anim.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (ctx, anim, secondaryAnim) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(dialogCtx).size.width * 0.88,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado del Modal con icono decorativo en círculo pastel
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: _pastelGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.create_new_folder_outlined,
                              color: _accentGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Nueva Categoría de Insumo',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Campo de Formulario (Input de 52px con radio 14px)
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: TextField(
                          controller: nameCtrl,
                          autofocus: true,
                          enabled: !isSaving,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nombre (Ej: Ingredientes, Empaques)',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(
                              Icons.label_outline,
                              color: _textMuted,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botones de Acción (Fila Inferior con 12px de separación)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(dialogCtx),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _cardBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final text = nameCtrl.text.trim();
                                        if (text.isEmpty) return;
                                        setDialogState(() => isSaving = true);

                                        final controller = context
                                            .read<CategoriaInsumoController>();
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        final errorMsg = await controller
                                            .guardarCategoria(text);

                                        if (!mounted || !dialogCtx.mounted) return;

                                        if (errorMsg == null) {
                                          Navigator.of(dialogCtx).pop();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Categoría "$text" creada',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF10B981),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        } else {
                                          setDialogState(() => isSaving = false);
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                errorMsg,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  const Color(0xFFDC2626),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Guardar',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _eliminar(CategoriaInsumo cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminar Categoría',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la categoría "${cat.nombre}"?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: _textMuted,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await context
                  .read<CategoriaInsumoController>()
                  .eliminarCategoria(cat.id!);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Categoría "${cat.nombre}" eliminada',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriaInsumoController>(
      builder: (context, controller, child) {
        final categorias = controller.categorias;
        final isLoading = controller.isLoading;

        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: _appBarGreen,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Volver',
            ),
            title: Text(
              'Categorías de Insumos',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_accentGreen),
                  ),
                )
              : categorias.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: const BoxDecoration(
                                color: _pastelGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.category_outlined,
                                size: 44,
                                color: _accentGreen,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No hay categorías registradas',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Crea categorías para organizar tus ingredientes, empaques y suministros.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: _accentGreen,
                      onRefresh: () async {
                        await controller.loadCategorias();
                      },
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
                        itemCount: categorias.length,
                        itemBuilder: (ctx, i) {
                          final cat = categorias[i];
                          final icon = _getIconForCategoria(cat.nombre);

                          return Container(
                            height: 64,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // Icono Descriptivo Izquierdo (40px × 40px, radio 10px)
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _pastelGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        icon,
                                        color: _accentGreen,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Texto Central: Nombre de la categoría
                                  Expanded(
                                    child: Text(
                                      cat.nombre,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Botón Eliminar a la derecha (36px × 36px en rojo pastel)
                                  InkWell(
                                    onTap: () => _eliminar(cat),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEF2F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFEF4444),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

          // Botón Flotante (FAB) de 56px × 56px, radio 18px en verde bosque
          floatingActionButton: GestureDetector(
            onTap: _abrirFormulario,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _accentGreen,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _accentGreen.withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
