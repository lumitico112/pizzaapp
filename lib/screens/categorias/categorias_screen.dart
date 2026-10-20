import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/categoria_producto_controller.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/models/producto.dart';

/// Pantalla rediseñada de Categorías de Productos bajo Material Design 3.
/// Integra la paleta cálida de la marca (#FF6A00, #D62828, #1F2937, #FBF9F5),
/// iconografía descriptiva por categoría, microinteracciones táctiles,
/// animación escalonada de entrada y diálogos emergentes con BackdropFilter.
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  // Paleta de colores de la marca
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaProductoController>().loadCategorias();
      context.read<ProductoController>().loadProductos();
    });
  }

  /// Retorna la iconografía descriptiva y colores pasteles acordes al nombre de la categoría
  _CategoriaTheme _getThemeForCategoria(String nombre) {
    final n = nombre.toLowerCase().trim();
    if (n.contains('pizza')) {
      return const _CategoriaTheme(
        icon: Icons.local_pizza_outlined,
        iconColor: Color(0xFFD62828),
        bgColor: Color(0xFFFFF1ED),
      );
    }
    if (n.contains('bebida') ||
        n.contains('gaseosa') ||
        n.contains('refresco') ||
        n.contains('jugo') ||
        n.contains('trago') ||
        n.contains('cerveza') ||
        n.contains('agua') ||
        n.contains('drink')) {
      return const _CategoriaTheme(
        icon: Icons.local_drink_outlined,
        iconColor: Color(0xFFEA580C),
        bgColor: Color(0xFFFEF3C7),
      );
    }
    if (n.contains('entrada') ||
        n.contains('aperitivo') ||
        n.contains('tapa') ||
        n.contains('piqueo') ||
        n.contains('pan') ||
        n.contains('bocadit') ||
        n.contains('snack')) {
      return const _CategoriaTheme(
        icon: Icons.tapas_outlined,
        iconColor: Color(0xFF059669),
        bgColor: Color(0xFFECFDF5),
      );
    }
    if (n.contains('postre') ||
        n.contains('dulce') ||
        n.contains('helado') ||
        n.contains('torta') ||
        n.contains('pastel') ||
        n.contains('dessert') ||
        n.contains('cake')) {
      return const _CategoriaTheme(
        icon: Icons.icecream_outlined,
        iconColor: Color(0xFFE11D48),
        bgColor: Color(0xFFFFE4E6),
      );
    }
    return const _CategoriaTheme(
      icon: Icons.restaurant_menu_rounded,
      iconColor: Color(0xFF7C3AED),
      bgColor: Color(0xFFF3E8FF),
    );
  }

  /// Modal con BackdropFilter blur de 4px y animación elástica (Scale + Fade)
  void _abrirFormulario({Categoria? categoria}) {
    final nameCtrl = TextEditingController(text: categoria?.nombre ?? '');
    final formKey = GlobalKey<FormState>();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModalCategoriaProducto',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
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
      pageBuilder: (dialogCtx, anim, secondaryAnim) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(ctx).size.width * 0.88,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Encabezado del Modal
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1ED),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                categoria == null
                                    ? Icons.add_circle_outline_rounded
                                    : Icons.edit_note_rounded,
                                color: _primaryOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoria == null
                                        ? 'Nueva Categoría'
                                        : 'Editar Categoría',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                  ),
                                  Text(
                                    categoria == null
                                        ? 'Crea una categoría para tus productos'
                                        : 'Modifica el nombre de la categoría',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Campo de texto
                        Text(
                          'NOMBRE DE LA CATEGORÍA',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameCtrl,
                          autofocus: true,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ej. Pizzas, Bebidas, Postres...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(
                              Icons.label_outline_rounded,
                              color: _primaryOrange,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _cardBorder,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _cardBorder,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _primaryOrange,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Por favor ingresa un nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Acciones
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(ctx),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_primaryOrange, _secondaryRed],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _secondaryRed.withValues(alpha: 0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!.validate()) {
                                            return;
                                          }
                                          setDialogState(() => isSaving = true);
                                          final controller = context
                                              .read<CategoriaProductoController>();
                                          final success =
                                              await controller.guardarCategoria(
                                            id: categoria?.id,
                                            nombre: nameCtrl.text.trim(),
                                          );

                                          if (!mounted || !ctx.mounted) return;
                                          if (success) {
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  categoria == null
                                                      ? 'Categoría creada con éxito'
                                                      : 'Categoría actualizada con éxito',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    const Color(0xFF059669),
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
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    controller.error ??
                                                        'Ocurrió un error al guardar',
                                                    style: GoogleFonts.poppins(),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFDC2626),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Guardar',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
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
              ),
            );
          },
        );
      },
    );
  }

  /// Diálogo estilizado de confirmación de eliminación con advertencia de productos asociados
  Future<void> _eliminar(Categoria cat, int productosAsociados) async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModalEliminarCategoria',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
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
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (ctx, anim, secondaryAnim) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.86,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de advertencia en círculo rojo suave
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Eliminar Categoría?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Estás seguro de que deseas eliminar la categoría "${cat.nombre}"?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                ),
                if (productosAsociados > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Atención: Hay $productosAsociados ${productosAsociados == 1 ? 'producto asociado' : 'productos asociados'} a esta categoría.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Eliminar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
      ),
    );

    if (confirm == true && mounted) {
      final controller = context.read<CategoriaProductoController>();
      await controller.eliminarCategoria(cat.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Categoría eliminada',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF1F2937),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoriaProductoController, ProductoController>(
      builder: (context, catController, prodController, child) {
        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            leading: Center(
              child: Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Categorías de Productos',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_secondaryRed, _primaryOrange],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          body: catController.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
                  ),
                )
              : catController.categorias.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 88),
                      itemCount: catController.categorias.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        final cat = catController.categorias[index];
                        final theme = _getThemeForCategoria(cat.nombre);
                        final productCount = prodController.productos
                            .where((p) => p.categoriaId == cat.id)
                            .length;
                        final countText = productCount == 0
                            ? 'Sin productos registrados'
                            : productCount == 1
                                ? '1 producto registrado'
                                : '$productCount productos registrados';

                        return _StaggeredCard(
                          index: index,
                          child: _ScaleCard(
                            onTap: () => _abrirFormulario(categoria: cat),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 68),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _cardBorder,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _textDark.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Icono descriptivo a la izquierda
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: theme.bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      theme.icon,
                                      color: theme.iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Texto Central
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          cat.nombre,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          countText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.normal,
                                            color: _textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Botón Editar
                                  _buildActionButton(
                                    tooltip: 'Editar categoría',
                                    bgColor: const Color(0xFFFFF7ED),
                                    iconColor: const Color(0xFFEA580C),
                                    icon: Icons.edit_outlined,
                                    onTap: () =>
                                        _abrirFormulario(categoria: cat),
                                  ),
                                  const SizedBox(width: 8),

                                  // Botón Eliminar
                                  _buildActionButton(
                                    tooltip: 'Eliminar categoría',
                                    bgColor: const Color(0xFFFEF2F2),
                                    iconColor: const Color(0xFFEF4444),
                                    icon: Icons.delete_outline_rounded,
                                    onTap: () =>
                                        _eliminar(cat, productCount),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          floatingActionButton: Container(
            margin: const EdgeInsets.only(bottom: 6, right: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryOrange, _secondaryRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _secondaryRed.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _abrirFormulario(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nueva Categoría',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Botón de acción compacto para Editar y Eliminar
  Widget _buildActionButton({
    required String tooltip,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Vista cuando no hay categorías registradas
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1ED),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryOrange.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 42,
                color: _primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin categorías de productos',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organiza tu carta creando categorías como Pizzas, Bebidas, Entradas o Postres.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Crear Primera Categoría',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para tema de categoría
class _CategoriaTheme {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _CategoriaTheme({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

/// Envoltorio de microinteracción con escala sutil de 0.98x
class _ScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleCard({required this.child, this.onTap});

  @override
  State<_ScaleCard> createState() => _ScaleCardState();
}

class _ScaleCardState extends State<_ScaleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Widget para animación escalonada vertical (Fade + Slide) con desfase
class _StaggeredCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredCard({
    required this.index,
    required this.child,
  });

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(curved);

    final delayMs = (widget.index * 40).clamp(0, 480);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

